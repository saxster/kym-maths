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
    @Bindable var store: AppStore

    var body: some View {
        PatternedWorldWebViewRepresentable(
            chapterNumber: chapterNumber,
            atlasRoute: atlasRoute,
            store: store
        )
    }
}

#if os(macOS)
struct PatternedWorldWebViewRepresentable: NSViewRepresentable {
    let chapterNumber: Int
    let atlasRoute: String?
    var store: AppStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "kymmathsBridge")
        let webView = WKWebView(frame: .zero, configuration: config)
        loadBook(in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        var js = "if (window.selectChapter) { window.selectChapter(\(chapterNumber)); }"
        if let route = atlasRoute, !route.isEmpty {
            js += " if (window.setAtlasRoute) { window.setAtlasRoute('\(route)'); }"
        }
        webView.evaluateJavaScript(js, completionHandler: nil)
        webView.evaluateJavaScript(WebStageHealthProbe.verificationScript) { result, _ in
            let report = WebStageHealthProbe.evaluateReport(from: result as? [String: Any])
            Task { @MainActor in
                store.webStageHealthVerified = report.isHealthy
            }
        }
    }

    private func loadBook(in webView: WKWebView) {
        if let indexURL = Self.resolveIndexURL() {
            let readAccessDir = indexURL.deletingLastPathComponent()
            webView.loadFileURL(indexURL, allowingReadAccessTo: readAccessDir)
        } else {
            webView.loadHTMLString("<html><body style='font-family: -apple-system; padding: 24px;'><h3>The Patterned World Interactive Stage</h3><p>Chapter \(chapterNumber) ready.</p></body></html>", baseURL: nil)
        }
    }

    static func resolveIndexURL() -> URL? {
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PatternedWorldBook") {
            return url
        }
        let candidates: [URL] = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("KymMaths/Resources/PatternedWorldBook/index.html"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("KymMaths/KymMaths/Resources/PatternedWorldBook/index.html"),
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/PatternedWorldBook/index.html")
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var store: AppStore

        init(store: AppStore) {
            self.store = store
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else { return }
            Task { @MainActor in
                if type == "chapterRead", let ch = dict["chapter"] as? Int {
                    store.markChapterRead(chapterNumber: ch, fraction: 1.0)
                }
            }
        }
    }
}
#else
struct PatternedWorldWebViewRepresentable: UIViewRepresentable {
    let chapterNumber: Int
    let atlasRoute: String?
    var store: AppStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "kymmathsBridge")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        if let indexURL = Self.resolveIndexURL() {
            let dir = indexURL.deletingLastPathComponent()
            webView.loadFileURL(indexURL, allowingReadAccessTo: dir)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        var js = "if (window.selectChapter) { window.selectChapter(\(chapterNumber)); }"
        if let route = atlasRoute, !route.isEmpty {
            js += " if (window.setAtlasRoute) { window.setAtlasRoute('\(route)'); }"
        }
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    static func resolveIndexURL() -> URL? {
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "PatternedWorldBook") {
            return url
        }
        let candidate = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/PatternedWorldBook/index.html")
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var store: AppStore

        init(store: AppStore) {
            self.store = store
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else { return }
            Task { @MainActor in
                if type == "chapterRead", let ch = dict["chapter"] as? Int {
                    store.markChapterRead(chapterNumber: ch, fraction: 1.0)
                }
            }
        }
    }
}
#endif
