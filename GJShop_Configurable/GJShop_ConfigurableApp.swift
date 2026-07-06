//
//  GJShop_ConfigurableApp.swift
//  GJShop_Configurable
//

import SwiftUI

@main
struct GJShop_ConfigurableApp: App {
    @State private var currentPage: String? = nil
    @State private var cartItems = [Item]()
    @State private var resultIndicator: String? = nil
    @State private var sessionVersion: String? = nil
    @State private var checkoutVersion: String? = nil

    var body: some Scene {
        WindowGroup {
            NavigationView {
                Group {
                    if currentPage == "receipt" {
                        ReceiptView(
                            resultIndicator: resultIndicator,
                            sessionVersion: sessionVersion,
                            checkoutVersion: checkoutVersion,
                            onBack: {
                                currentPage = nil
                                resultIndicator = nil
                                sessionVersion = nil
                                checkoutVersion = nil
                                CheckoutContext.shared.reset()
                                cartItems = []
                            }
                        )
                    } else {
                        ContentView(cartItems: $cartItems, currentPage: $currentPage)
                    }
                }
            }
            .navigationViewStyle(.stack)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowReceipt"))) { notification in
                print("=== NOTIFICATION RECEIVED ===")
                if let userInfo = notification.userInfo {
                    resultIndicator = userInfo["resultIndicator"] as? String
                    sessionVersion = userInfo["sessionVersion"] as? String
                    checkoutVersion = userInfo["checkoutVersion"] as? String
                }
                if let url = notification.object as? URL {
                    parseDeepLinkURL(url)
                }
                DispatchQueue.main.async {
                    currentPage = "receipt"
                }
            }
            .onOpenURL { url in
                print("=== APP RECEIVED DIRECT URL: \(url.absoluteString) ===")
                if url.scheme == "myapp", url.host == "receipt" {
                    parseDeepLinkURL(url)
                    DispatchQueue.main.async {
                        currentPage = "receipt"
                    }
                }
            }
        }
    }

    private func parseDeepLinkURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        for item in queryItems {
            switch item.name {
            case "resultIndicator":
                resultIndicator = item.value
            case "sessionVersion":
                sessionVersion = item.value
            case "checkoutVersion":
                checkoutVersion = item.value
            default:
                break
            }
        }
    }
}
