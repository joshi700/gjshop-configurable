//
//  HostedCheckout.swift
//  GJShop_Configurable
//

import SwiftUI
import WebKit

struct HostedCheckout: UIViewRepresentable {
    var hostUrl: String
    var sessionId: String
    @Binding var paymentFinished: Bool

    // Callback for deep link URLs (e.g., myapp://receipt)
    var onDeepLink: ((URL) -> Void)? = nil

    func makeUIView(context: Context) -> WKWebView {
        let wKWebView = WKWebView()
        wKWebView.navigationDelegate = context.coordinator
        return wKWebView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <html>
            <head>
                <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'>
                <script src='\(self.hostUrl)/static/checkout/checkout.min.js'></script>
                <script type='text/javascript'>
                    Checkout.configure({
                        session: {
                            id: '\(self.sessionId)'
                        }
                    }).then(() => {
                        Checkout.showPaymentPage();
                    }).catch((error) => {
                        console.log('Checkout configuration error:', error);
                    });
                </script>
            </head>
            <body>
                <div id='embed-target'></div>
            </body>
        </html>
        """
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self, onDeepLink: onDeepLink)
    }

    class WebViewCoordinator: NSObject, WKNavigationDelegate {
        var parent: HostedCheckout
        var onDeepLink: ((URL) -> Void)?

        init(_ parent: HostedCheckout, onDeepLink: ((URL) -> Void)? = nil) {
            self.parent = parent
            self.onDeepLink = onDeepLink
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            print("Navigating to URL: \(url.absoluteString)")

            // Detect your custom URL scheme deep link (e.g., myapp://receipt)
            if url.scheme == "myapp" {
                print("Deep link detected: \(url)")

                // Parse the URL parameters and send via notification
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems {

                    var userInfo: [String: Any] = [:]

                    for item in queryItems {
                        if let value = item.value {
                            userInfo[item.name] = value
                        }
                    }

                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowReceipt"),
                            object: url,
                            userInfo: userInfo
                        )
                        self.parent.paymentFinished = true
                    }
                }

                onDeepLink?(url)
                decisionHandler(.cancel)  // Prevent WebView loading this URL
                return
            }

            // Existing logic for recognized navigation URLs
            let urlString = url.absoluteString.lowercased()
            if urlString.contains("return") || urlString.contains("timeout") || urlString.contains("cancel") {
                print("Payment flow finished: \(urlString)")
                DispatchQueue.main.async {
                    self.parent.paymentFinished = true
                }
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView failed to load: \(error)")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading")
        }
    }
}
