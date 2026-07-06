//
//  ConfigStore.swift
//  GJShop_Configurable
//
//  Source of truth for the HCO configuration (BRD §10.2).
//  Password lives in the Keychain; everything else in UserDefaults.
//

import Foundation
import SwiftUI

final class ConfigStore: ObservableObject {
    static let shared = ConfigStore()

    enum Defaults {
        static let merchantId = "TESTMIDtesting00"
        static let apiBaseUrl = "https://mtf.gateway.mastercard.com"
        static let apiVersion = "100"
        static let backendUrl = "https://gjshop-configurable-backend.vercel.app"
    }

    @Published var merchantId: String
    @Published var apiPassword: String
    @Published var apiBaseUrl: String
    @Published var apiVersion: String
    @Published var backendUrl: String
    @Published var advancedMode: Bool
    @Published var payloadJSON: String
    @Published var lastSavedAt: Date?

    var apiUsername: String { "merchant.\(merchantId)" }

    var isTestEnvironment: Bool {
        let url = apiBaseUrl.lowercased()
        return url.contains("mtf.") || url.contains("test")
    }

    private init() {
        let defaults = UserDefaults.standard
        merchantId = defaults.string(forKey: "merchantId") ?? Defaults.merchantId
        apiBaseUrl = defaults.string(forKey: "apiBaseUrl") ?? Defaults.apiBaseUrl
        apiVersion = defaults.string(forKey: "apiVersion") ?? Defaults.apiVersion
        backendUrl = defaults.string(forKey: "backendUrl") ?? Defaults.backendUrl
        advancedMode = defaults.bool(forKey: "advancedMode")
        payloadJSON = defaults.string(forKey: "payloadJSON") ?? ConfigStore.defaultPayloadJSON
        lastSavedAt = defaults.object(forKey: "lastSavedAt") as? Date
        apiPassword = KeychainHelper.loadPassword()
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(merchantId, forKey: "merchantId")
        defaults.set(apiBaseUrl, forKey: "apiBaseUrl")
        defaults.set(apiVersion, forKey: "apiVersion")
        defaults.set(backendUrl, forKey: "backendUrl")
        defaults.set(advancedMode, forKey: "advancedMode")
        defaults.set(payloadJSON, forKey: "payloadJSON")
        lastSavedAt = Date()
        defaults.set(lastSavedAt, forKey: "lastSavedAt")
        KeychainHelper.savePassword(apiPassword)
    }

    func resetToDefaults() {
        merchantId = Defaults.merchantId
        apiBaseUrl = Defaults.apiBaseUrl
        apiVersion = Defaults.apiVersion
        backendUrl = Defaults.backendUrl
        advancedMode = false
        payloadJSON = ConfigStore.defaultPayloadJSON
        apiPassword = ""
        KeychainHelper.deletePassword()
        save()
    }

    // The `config` object sent with every backend request (FR-10.2).
    // An empty password is omitted so the backend falls back to its env vars.
    func configPayload() -> [String: String] {
        var config = [
            "merchantId": merchantId,
            "apiBaseUrl": apiBaseUrl,
            "apiVersion": apiVersion
        ]
        if !apiPassword.isEmpty {
            config["apiPassword"] = apiPassword
        }
        return config
    }

    // Advanced-mode payload as a JSON object, nil when invalid or in Simple mode.
    func payloadOverrideObject() -> [String: Any]? {
        guard advancedMode,
              let data = payloadJSON.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }

    // Mirrors the backend's default INITIATE_CHECKOUT payload.
    // order.id and order.amount are injected by the backend at request time (FR-08A.5).
    static let defaultPayloadJSON = """
    {
      "apiOperation" : "INITIATE_CHECKOUT",
      "checkoutMode" : "WEBSITE",
      "interaction" : {
        "operation" : "PURCHASE",
        "merchant" : {
          "name" : "GJ Enterprises LLC",
          "url" : "https://apitest.free.beeceptor.com"
        },
        "returnUrl" : "myapp://receipt",
        "displayControl" : {
          "billingAddress" : "READ_ONLY",
          "customerEmail" : "READ_ONLY",
          "shipping" : "READ_ONLY"
        }
      },
      "order" : {
        "currency" : "USD",
        "amount" : "1.00",
        "id" : "INJECTED_AT_CHECKOUT",
        "description" : "Goods and Services"
      }
    }
    """
}

// Shared context for the order being paid, so the receipt can verify it (FR-08B).
final class CheckoutContext: ObservableObject {
    static let shared = CheckoutContext()

    @Published var orderId: String?
    @Published var successIndicator: String?
    @Published var amount: Double?

    func reset() {
        orderId = nil
        successIndicator = nil
        amount = nil
    }
}
