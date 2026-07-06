//
//  ReceiptView.swift
//  GJShop_Configurable
//
//  Server-side payment verification (FR-08B): the success state only shows
//  after the backend confirms the order via RETRIEVE_ORDER.
//

import SwiftUI

struct ReceiptView: View {
    var resultIndicator: String?
    var sessionVersion: String?
    var checkoutVersion: String?
    var onBack: (() -> Void)? = nil

    private enum VerificationState {
        case verifying
        case verified(OrderResult)
        case failed(String)
        case unavailable
    }

    @State private var verification: VerificationState = .verifying
    @ObservedObject private var context = CheckoutContext.shared

    // FR-08B.4: compare the deep link's resultIndicator with the session's successIndicator
    private var indicatorsMatch: Bool? {
        guard let result = resultIndicator, let success = context.successIndicator else { return nil }
        return result == success
    }

    private var isSuccess: Bool {
        if case .verified(let order) = verification {
            return order.result == "SUCCESS" && (order.status == "CAPTURED" || order.status == "AUTHORIZED")
        }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                switch verification {
                case .verifying:
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.4)
                        Text("Verifying payment…")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Confirming the order with the gateway")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 80)

                case .verified(let order):
                    Image(systemName: isSuccess ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(isSuccess ? .green : .orange)

                    Text(isSuccess ? "Thank you for your order!" : "Payment \(order.status ?? "not confirmed")")
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    orderDetails(order)
                    indicatorSection

                case .failed(let message):
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.red)

                    Text("Verification failed")
                        .font(.title)
                        .bold()

                    Text(message)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)

                    indicatorSection

                case .unavailable:
                    Image(systemName: "checkmark.seal")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.green)

                    Text("Payment flow finished")
                        .font(.title)
                        .bold()

                    Text("No order context available to verify against the gateway.")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    indicatorSection
                }

                if case .verifying = verification {} else {
                    Button(action: {
                        onBack?()
                    }) {
                        Text("Back to Home")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                }
            }
            .padding()
        }
        .onAppear {
            verifyPayment()
        }
    }

    private func orderDetails(_ order: OrderResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            detailRow("Order ID", order.orderId ?? "N/A")
            detailRow("Gateway Result", order.result ?? "N/A")
            detailRow("Status", order.status ?? "N/A")
            if let amount = order.amount, let currency = order.currency {
                detailRow("Amount", String(format: "%.2f %@", amount, currency))
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }

    private var indicatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Indicator Match:")
                    .fontWeight(.medium)
                Spacer()
                if let match = indicatorsMatch {
                    Label(match ? "Match" : "Mismatch",
                          systemImage: match ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(match ? .green : .red)
                } else {
                    Text("N/A")
                        .foregroundColor(.secondary)
                }
            }
            detailRow("Result Indicator", resultIndicator ?? "N/A")
            detailRow("Success Indicator", context.successIndicator ?? "N/A")
            detailRow("Session Version", sessionVersion ?? "N/A")
            detailRow("Checkout Version", checkoutVersion ?? "N/A")
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text("\(title):")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func verifyPayment() {
        guard let orderId = context.orderId else {
            verification = .unavailable
            return
        }

        verification = .verifying
        BackendAPI.retrieveOrder(orderId: orderId) { result in
            switch result {
            case .success(let order):
                verification = .verified(order)
            case .failure(let error):
                verification = .failed(error.message)
            }
        }
    }
}
