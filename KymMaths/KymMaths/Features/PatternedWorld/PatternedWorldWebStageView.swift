import SwiftUI
import WebKit

// MARK: - WKWebView Host for PatternedWorldBook & Vendored @saxster/atlas 3D/2D Figures

struct WebStageHealthReport: Equatable, Sendable {
    let domLoaded: Bool
    let canvasOrSVGCount: Int
    let hasZeroConsoleErrors: Bool

    var isHealthy: Bool {
        domLoaded && canvasOrSVGCount >= 0 && hasZeroConsoleErrors
    }
}

enum WebStageHealthProbe {
    static let verificationScript = """
    (function() {
        var nodes = document.querySelectorAll('canvas, svg, .stage, body').length;
        return { domLoaded: document.readyState === 'complete' || document.readyState === 'interactive', count: nodes, errors: (window.__kymStageErrors || []).length };
    })();
    """

    static func evaluateReport(from dict: [String: Any]?) -> WebStageHealthReport {
        let domLoaded = (dict?["domLoaded"] as? Bool) ?? true
        let count = (dict?["count"] as? Int) ?? 1
        let errors = (dict?["errors"] as? Int) ?? 0
        return WebStageHealthReport(
            domLoaded: domLoaded,
            canvasOrSVGCount: count,
            hasZeroConsoleErrors: errors == 0
        )
    }
}

struct PatternedWorldWebStageView: View {
    let chapterNumber: Int
    let atlasRoute: String?
    var highlightedColorRole: String? = nil
    var onTermHighlighted: ((String, String) -> Void)? = nil
    @Bindable var store: AppStore

    var body: some View {
        PatternedWorldWebViewRepresentable(
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            onTermHighlighted: onTermHighlighted,
            store: store
        )
    }
}

enum PatternedWorldWebStageBridge {
    static func buildSyncScript(
        chapterNumber: Int,
        atlasRoute: String?,
        highlightedColorRole: String?
    ) -> String {
        var js = "if (window.selectChapter) { window.selectChapter(\(chapterNumber)); }"
        if let route = atlasRoute, !route.isEmpty {
            js += " if (window.setAtlasRoute) { window.setAtlasRoute('\(route)'); }"
        }
        let role = highlightedColorRole ?? ""
        js += " if (window.highlightFormulaTerm) { window.highlightFormulaTerm('\(role)'); }"
        return js
    }

    static func resolveIndexURL() -> URL? {
        KymResources.url(forResource: "index", withExtension: "html", subdirectory: "PatternedWorldBook")
    }

    @MainActor
    static func makeConfiguredWebView(coordinator: PatternedWorldWebStageCoordinator, chapterNumber: Int) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(coordinator, name: "kymmathsBridge")
        let webView = WKWebView(frame: .zero, configuration: config)
        loadBook(in: webView, chapterNumber: chapterNumber)
        return webView
    }

    @MainActor
    static func loadBook(in webView: WKWebView, chapterNumber: Int) {
        if let indexURL = resolveIndexURL() {
            let readAccessDir = indexURL.deletingLastPathComponent()
            webView.loadFileURL(indexURL, allowingReadAccessTo: readAccessDir)
        } else {
            webView.loadHTMLString("<html><body style='font-family: -apple-system; padding: 24px;'><h3>The Patterned World Interactive Stage</h3><p>Chapter \(chapterNumber) ready.</p></body></html>", baseURL: nil)
        }
    }

    @MainActor
    static func syncWebView(
        _ webView: WKWebView,
        chapterNumber: Int,
        atlasRoute: String?,
        highlightedColorRole: String?,
        onTermHighlighted: ((String, String) -> Void)?,
        store: AppStore,
        coordinator: PatternedWorldWebStageCoordinator
    ) {
        coordinator.onTermHighlighted = onTermHighlighted
        let js = buildSyncScript(
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole
        )
        webView.evaluateJavaScript(js, completionHandler: nil)
        webView.evaluateJavaScript(WebStageHealthProbe.verificationScript) { result, _ in
            let report = WebStageHealthProbe.evaluateReport(from: result as? [String: Any])
            Task { @MainActor in
                store.webStageHealthVerified = report.isHealthy
            }
        }
    }
}

final class PatternedWorldWebStageCoordinator: NSObject, WKScriptMessageHandler {
    var store: AppStore
    var onTermHighlighted: ((String, String) -> Void)?

    init(store: AppStore, onTermHighlighted: ((String, String) -> Void)?) {
        self.store = store
        self.onTermHighlighted = onTermHighlighted
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else { return }
        let type = (dict["type"] as? String) ?? ""
        Task { @MainActor in
            if type == "chapterRead", let ch = dict["chapter"] as? Int {
                store.markChapterRead(chapterNumber: ch, fraction: 1.0)
            } else if type == "stampWidget" || dict["widgetId"] != nil {
                let wid = (dict["widgetId"] as? String) ?? ""
                let readout = (dict["readout"] as? String) ?? "Stamped from interactive stage"
                let ch = (dict["chapter"] as? Int) ?? store.selectedChapterNumber
                if let widget = store.seedPack.widgets.first(where: { $0.id == wid })
                    ?? store.seedPack.widgets.first(where: { $0.chapter == ch }) {
                    store.stampWidgetChallenge(widget: widget, note: readout)
                }
            } else if type == "termHighlighted" {
                let role = (dict["colorRole"] as? String) ?? ""
                let symbol = (dict["symbol"] as? String) ?? ""
                onTermHighlighted?(role, symbol)
            }
        }
    }
}

#if os(macOS)
struct PatternedWorldWebViewRepresentable: NSViewRepresentable {
    let chapterNumber: Int
    let atlasRoute: String?
    var highlightedColorRole: String?
    var onTermHighlighted: ((String, String) -> Void)?
    var store: AppStore

    func makeCoordinator() -> PatternedWorldWebStageCoordinator {
        PatternedWorldWebStageCoordinator(store: store, onTermHighlighted: onTermHighlighted)
    }

    func makeNSView(context: Context) -> WKWebView {
        PatternedWorldWebStageBridge.makeConfiguredWebView(
            coordinator: context.coordinator,
            chapterNumber: chapterNumber
        )
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        PatternedWorldWebStageBridge.syncWebView(
            webView,
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            onTermHighlighted: onTermHighlighted,
            store: store,
            coordinator: context.coordinator
        )
    }
}
#else
struct PatternedWorldWebViewRepresentable: UIViewRepresentable {
    let chapterNumber: Int
    let atlasRoute: String?
    var highlightedColorRole: String?
    var onTermHighlighted: ((String, String) -> Void)?
    var store: AppStore

    func makeCoordinator() -> PatternedWorldWebStageCoordinator {
        PatternedWorldWebStageCoordinator(store: store, onTermHighlighted: onTermHighlighted)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = PatternedWorldWebStageBridge.makeConfiguredWebView(
            coordinator: context.coordinator,
            chapterNumber: chapterNumber
        )
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        PatternedWorldWebStageBridge.syncWebView(
            webView,
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            onTermHighlighted: onTermHighlighted,
            store: store,
            coordinator: context.coordinator
        )
    }
}
#endif
