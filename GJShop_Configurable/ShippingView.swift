//
//  ShippingView.swift
//  GJShop_Configurable
//

import SwiftUI

struct ShippingView: View {
    @Binding var cartItems: [Item]
    @ObservedObject private var config = ConfigStore.shared

    // State management
    @State private var isLoading = false
    @State private var paymentDone = false
    @State private var paymentResult = false
    @State private var orderId = ""
    @State private var sessionId = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var totalAmount: Double {
        cartItems.reduce(0, { $0 + $1.price })
    }

    var body: some View {
        VStack(spacing: 0) {
            if sessionId.isEmpty {
                shippingFormView
            } else if !paymentDone {
                paymentView
            } else {
                resultView
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Shipping Form View
    private var shippingFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                orderSummaryCard
                activeConfigCard

                VStack(spacing: 20) {
                    confirmButton
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var orderSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Order Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("$\(String(format: "%.2f", totalAmount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            ForEach(cartItems, id: \.id) { item in
                HStack {
                    Text(item.name)
                        .font(.body)
                    Spacer()
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    // Which gateway profile this checkout will use (FR-05.2a)
    private var activeConfigCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Gateway Configuration")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(config.isTestEnvironment ? "TEST" : "LIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(config.isTestEnvironment ? Color.orange.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(config.isTestEnvironment ? .orange : .red)
                    .cornerRadius(6)
            }
            HStack {
                Text("Merchant")
                    .foregroundColor(.secondary)
                Spacer()
                Text(config.merchantId)
            }
            .font(.subheadline)
            HStack {
                Text("Payload")
                    .foregroundColor(.secondary)
                Spacer()
                Text(config.advancedMode ? "Advanced (custom JSON)" : "Simple")
            }
            .font(.subheadline)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    private var confirmButton: some View {
        Button(action: {
            processShipping()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                Text(isLoading ? "Creating session..." : "Continue to Payment")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(cartItems.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(cartItems.isEmpty || isLoading)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Payment View
    private var paymentView: some View {
        HostedCheckout(
            hostUrl: config.apiBaseUrl,
            sessionId: sessionId,
            paymentFinished: $paymentDone,
            onDeepLink: { url in
                print("Deep link intercepted: \(url)")
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Result View (fallback when the hosted page finishes without a deep link)
    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Verifying payment…")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: paymentResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(paymentResult ? .green : .red)

                        VStack(spacing: 8) {
                            Text(paymentResult ? "Order Confirmed!" : "Payment Failed")
                                .font(.title)
                                .fontWeight(.bold)

                            Text(paymentResult ?
                                "Your order has been confirmed and will be delivered to your address." :
                                "There was an issue processing your payment. Please try again.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }

                    if paymentResult && !orderId.isEmpty {
                        VStack(spacing: 8) {
                            Text("Order ID: \(orderId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Total: $\(String(format: "%.2f", totalAmount))")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if !isLoading {
                fetchPaymentResult()
            }
        }
    }

    // MARK: - Helper Functions
    private func processShipping() {
        isLoading = true
        requestSession {
            isLoading = false
        }
    }

    private func fetchPaymentResult() {
        isLoading = true
        getResult {
            isLoading = false
        }
    }

    func randomString(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    func requestSession(completion: @escaping () -> ()) {
        self.orderId = self.randomString(length: 8)
        print("orderId " + orderId)

        BackendAPI.createSession(amount: totalAmount, orderId: orderId) { result in
            switch result {
            case .success(let session):
                // Keep the order context for receipt verification (FR-08B)
                CheckoutContext.shared.orderId = session.orderId
                CheckoutContext.shared.successIndicator = session.successIndicator
                CheckoutContext.shared.amount = totalAmount
                self.sessionId = session.sessionId
            case .failure(let error):
                self.alertMessage = error.message
                self.showingAlert = true
            }
            completion()
        }
    }

    func getResult(completion: @escaping () -> ()) {
        guard !orderId.isEmpty else {
            self.alertMessage = "Invalid order ID"
            self.showingAlert = true
            completion()
            return
        }

        BackendAPI.retrieveOrder(orderId: orderId) { result in
            switch result {
            case .success(let order):
                self.paymentResult = (order.result == "SUCCESS" && order.status == "CAPTURED")
            case .failure(let error):
                self.paymentResult = false
                self.alertMessage = error.message
                self.showingAlert = true
            }
            completion()
        }
    }
}
