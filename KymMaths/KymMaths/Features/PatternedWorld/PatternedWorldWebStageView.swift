import SwiftUI
import WebKit

// MARK: - The web view that hosts a chapter's interactive figure (PatternedWorldBook and its atlas figures)

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
    /// Called with the page's height, so the host can size the stage to its figure.
    var onContentHeight: ((CGFloat) -> Void)? = nil
    @Bindable var store: AppStore
    @Environment(\.standardTheme) private var theme

    var body: some View {
        PatternedWorldWebViewRepresentable(
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            onTermHighlighted: onTermHighlighted,
            onContentHeight: onContentHeight,
            store: store,
            isDark: theme.isDark
        )
    }
}

enum PatternedWorldWebStageBridge {
    static func buildSyncScript(
        chapterNumber: Int,
        atlasRoute: String?,
        highlightedColorRole: String?,
        isDark: Bool? = nil
    ) -> String {
        var js = ""
        if let isDark {
            js += themeScript(isDark: isDark) + " "
        }
        js += "if (window.selectChapter) { window.selectChapter(\(chapterNumber)); }"
        if let route = atlasRoute, !route.isEmpty {
            js += " if (window.setAtlasRoute) { window.setAtlasRoute('\(route)'); }"
        }
        let role = highlightedColorRole ?? ""
        js += " if (window.highlightFormulaTerm) { window.highlightFormulaTerm('\(role)'); }"
        return js
    }

    /// Sets the page's paper or night palette. The stage's CSS and canvas both read `data-theme`;
    /// the app's theme can differ from the system's appearance, so the app sets it.
    static func themeScript(isDark: Bool) -> String {
        "document.documentElement.setAttribute('data-theme', '\(isDark ? "dark" : "light")');"
    }

    /// Posts the page's height whenever it changes. The book lays out by content, not by the
    /// viewport, so sizing the web view to this height never feeds back into it.
    static let contentHeightScript = """
    new ResizeObserver(function() {
        window.webkit.messageHandlers.kymmathsBridge.postMessage({ type: 'contentHeight', height: document.documentElement.scrollHeight });
    }).observe(document.body);
    """

    static func resolveIndexURL() -> URL? {
        KymResources.url(forResource: "index", withExtension: "html", subdirectory: "PatternedWorldBook")
    }

    @MainActor
    static func makeConfiguredWebView(
        coordinator: PatternedWorldWebStageCoordinator,
        chapterNumber: Int,
        atlasRoute: String? = nil,
        isDark: Bool = false
    ) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(coordinator, name: "kymmathsBridge")
        // The palette is set before first paint, and the chapter as soon as the page's script has
        // run, so the stage never flashes the wrong theme or chapter 0.
        config.userContentController.addUserScript(
            WKUserScript(source: themeScript(isDark: isDark), injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        config.userContentController.addUserScript(
            WKUserScript(
                source: buildSyncScript(chapterNumber: chapterNumber, atlasRoute: atlasRoute, highlightedColorRole: nil, isDark: isDark),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        config.userContentController.addUserScript(
            WKUserScript(source: contentHeightScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
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
            webView.loadHTMLString("<html><body style='font-family: -apple-system; padding: 24px;'><h3>The Patterned World</h3><p>The figure for chapter \(chapterNumber) could not be found.</p></body></html>", baseURL: nil)
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
        coordinator: PatternedWorldWebStageCoordinator,
        isDark: Bool = false
    ) {
        coordinator.onTermHighlighted = onTermHighlighted
        let js = buildSyncScript(
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            isDark: isDark
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
    var onContentHeight: ((CGFloat) -> Void)?

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
            } else if type == "contentHeight", let height = dict["height"] as? Double {
                onContentHeight?(CGFloat(height))
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
    var onContentHeight: ((CGFloat) -> Void)?
    var store: AppStore
    var isDark: Bool = false

    func makeCoordinator() -> PatternedWorldWebStageCoordinator {
        PatternedWorldWebStageCoordinator(store: store, onTermHighlighted: onTermHighlighted)
    }

    func makeNSView(context: Context) -> WKWebView {
        PatternedWorldWebStageBridge.makeConfiguredWebView(
            coordinator: context.coordinator,
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            isDark: isDark
        )
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onContentHeight = onContentHeight
        PatternedWorldWebStageBridge.syncWebView(
            webView,
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            onTermHighlighted: onTermHighlighted,
            store: store,
            coordinator: context.coordinator,
            isDark: isDark
        )
    }
}
#else
struct PatternedWorldWebViewRepresentable: UIViewRepresentable {
    let chapterNumber: Int
    let atlasRoute: String?
    var highlightedColorRole: String?
    var onTermHighlighted: ((String, String) -> Void)?
    var onContentHeight: ((CGFloat) -> Void)?
    var store: AppStore
    var isDark: Bool = false

    func makeCoordinator() -> PatternedWorldWebStageCoordinator {
        PatternedWorldWebStageCoordinator(store: store, onTermHighlighted: onTermHighlighted)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = PatternedWorldWebStageBridge.makeConfiguredWebView(
            coordinator: context.coordinator,
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            isDark: isDark
        )
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onContentHeight = onContentHeight
        PatternedWorldWebStageBridge.syncWebView(
            webView,
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            highlightedColorRole: highlightedColorRole,
            onTermHighlighted: onTermHighlighted,
            store: store,
            coordinator: context.coordinator,
            isDark: isDark
        )
    }
}
#endif
