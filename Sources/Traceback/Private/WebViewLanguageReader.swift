//
//  WebViewLanguageReader.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//


import WebKit

final class WebViewLanguageReader: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<String?, Never>?

    func getWebViewLocaleIdentifier() async -> String? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let config = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            webView.isHidden = true
            self.webView = webView

            let html = """
            <html>
              <head>
                <script>
                  window.generateDeviceHeuristics = () => navigator.language || '';
                </script>
              </head>
              <body></body>
            </html>
            """

            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("window.generateDeviceHeuristics()") { [weak self] result, _ in
            let value = result as? String
            self?.continuation?.resume(returning: value)
            self?.cleanup()
        }
    }

    private func cleanup() {
        webView?.navigationDelegate = nil
        webView = nil
        continuation = nil
    }
}
