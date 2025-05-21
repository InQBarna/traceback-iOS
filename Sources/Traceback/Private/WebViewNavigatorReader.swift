//
//  WebViewLanguageReader.swift
//  traceback-ios
//
//  Created by Sergi Hernanz on 7/4/25.
//


import WebKit

final class WebViewNavigatorReader: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<Navigator?, Never>?
    
    struct Navigator {
        let language: String?
        let appVersion: String?
    }

    func getWebViewInfo() async -> Navigator? {
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
                  window.generateDeviceLanguage = () => navigator.language || '';
                  window.generateDeviceAppVersion = () => navigator.appVersion || '';
                </script>
              </head>
              <body></body>
            </html>
            """

            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("window.generateDeviceAppVersion()") { [weak self] appVersion, _ in
            let appVersionString = appVersion as? String
            webView.evaluateJavaScript("window.generateDeviceLanguage()") { [weak self] language, _ in
                let languageString = language as? String
                self?.continuation?.resume(
                    returning: Navigator(
                        language: languageString,
                        appVersion: appVersionString
                    )
                )
                self?.cleanup()
            }
        }
    }

    private func cleanup() {
        webView?.navigationDelegate = nil
        webView = nil
        continuation = nil
    }
}
