import SwiftUI
import WebKit
import Combine

/// Owns the single WKWebView that shows instagram.com with the filter injected.
@MainActor
final class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView
    @Published var canGoBack = false
    @Published var isLoading = false

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()              // keeps you logged in between launches
        config.allowsInlineMediaPlayback = true
        // Look like mobile Safari so Instagram serves its normal mobile site
        config.applicationNameForUserAgent = "Version/18.0 Mobile/15E148 Safari/604.1"
        config.userContentController.addUserScript(
            WKUserScript(source: InstagramFilter.script,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: true)
        )

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.publisher(for: \.canGoBack).receive(on: DispatchQueue.main).assign(to: &$canGoBack)
        webView.publisher(for: \.isLoading).receive(on: DispatchQueue.main).assign(to: &$isLoading)

        webView.load(URLRequest(url: InstagramFilter.homeURL))
    }

    func goHome() { webView.load(URLRequest(url: InstagramFilter.homeURL)) }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .allow }

        // Stop "Open in app" links (instagram://, itms-apps://) from jumping to the native app
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data"]
        guard allowedSchemes.contains(url.scheme?.lowercased() ?? "") else { return .cancel }

        // target="_blank" links: open them in this same web view
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            return .cancel
        }

        // Only police the main page, not iframes/resources
        guard navigationAction.targetFrame?.isMainFrame == true else { return .allow }

        if let redirect = InstagramFilter.redirect(for: url) {
            webView.load(URLRequest(url: redirect))
            return .cancel
        }
        return .allow
    }
}

/// Wraps the model's WKWebView for SwiftUI.
struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
