//
//  BackendAPI.swift
//  GJShop_Configurable
//
//  Thin client for the GJShop Configurable backend (BRD §11).
//  Every request carries the active configuration in the body — never in the URL.
//

import Foundation

struct CheckoutResponse: Decodable {
    let sessionId: String
    let orderId: String
    let successIndicator: String?
}

struct OrderResult: Decodable {
    let orderId: String?
    let result: String?
    let status: String?
    let amount: Double?
    let currency: String?
    let description: String?
}

struct TestConnectionResponse: Decodable {
    let backend: String?
    let gateway: String?
    let message: String?
}

struct BackendErrorResponse: Decodable {
    let error: String?
    let gatewayCode: String?
    let explanation: String?
}

struct BackendError: Error {
    let message: String
}

enum BackendAPI {

    static func createSession(amount: Double, orderId: String,
                              completion: @escaping (Result<CheckoutResponse, BackendError>) -> Void) {
        let config = ConfigStore.shared
        var body: [String: Any] = [
            "amount": String(format: "%.2f", amount),
            "currency": "USD",
            "orderId": orderId,
            "config": config.configPayload()
        ]
        if let override = config.payloadOverrideObject() {
            body["payloadOverride"] = override
        }
        post(path: "/api/checkout", body: body, completion: completion)
    }

    static func retrieveOrder(orderId: String,
                              completion: @escaping (Result<OrderResult, BackendError>) -> Void) {
        let body: [String: Any] = [
            "orderId": orderId,
            "config": ConfigStore.shared.configPayload()
        ]
        post(path: "/api/checkorder", body: body, completion: completion)
    }

    static func testConnection(config: [String: String], backendUrl: String,
                               completion: @escaping (Result<TestConnectionResponse, BackendError>) -> Void) {
        post(path: "/api/testconnection", body: ["config": config],
             backendUrl: backendUrl, completion: completion)
    }

    private static func post<T: Decodable>(path: String, body: [String: Any],
                                           backendUrl: String? = nil,
                                           completion: @escaping (Result<T, BackendError>) -> Void) {
        let base = backendUrl ?? ConfigStore.shared.backendUrl
        guard let url = URL(string: base + path) else {
            completion(.failure(BackendError(message: "Invalid backend URL: \(base)")))
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 30.0)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(BackendError(message: "Network error: \(error.localizedDescription)")))
                    return
                }
                guard let data = data else {
                    completion(.failure(BackendError(message: "Empty response from backend")))
                    return
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if statusCode >= 400 {
                    // Structured MPGS error passed through by the backend (FR-10.5)
                    if let backendError = try? JSONDecoder().decode(BackendErrorResponse.self, from: data) {
                        var message = backendError.error ?? "Request failed"
                        if let explanation = backendError.explanation {
                            message += "\n\(explanation)"
                        }
                        if let code = backendError.gatewayCode {
                            message += "\nGateway code: \(code)"
                        }
                        completion(.failure(BackendError(message: message)))
                    } else {
                        completion(.failure(BackendError(message: "Backend error (HTTP \(statusCode))")))
                    }
                    return
                }

                do {
                    completion(.success(try JSONDecoder().decode(T.self, from: data)))
                } catch {
                    completion(.failure(BackendError(message: "Could not read backend response: \(error.localizedDescription)")))
                }
            }
        }.resume()
    }
}
