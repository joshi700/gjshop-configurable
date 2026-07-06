//
//  SettingsView.swift
//  GJShop_Configurable
//
//  API Configuration module (FR-07 / FR-08 / FR-08A).
//  Edits are local until Save; the password goes to the Keychain.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var store = ConfigStore.shared

    // Draft values — committed to the store only on Save (FR-07.4)
    @State private var merchantId = ""
    @State private var apiPassword = ""
    @State private var apiBaseUrl = ""
    @State private var apiVersion = ""
    @State private var backendUrl = ""
    @State private var advancedMode = false
    @State private var payloadJSON = ""

    @State private var loaded = false
    @State private var showPassword = false
    @State private var validationError: String? = nil
    @State private var showingResetConfirmation = false
    @State private var savedBanner = false
    @State private var copiedBanner: String? = nil

    // Test Connection state (FR-08.6)
    private enum ConnectionState: Equatable {
        case idle, testing, success(String), failure(String)
    }
    @State private var connectionState: ConnectionState = .idle

    private var apiUsername: String { "merchant.\(merchantId)" }

    private var isTestEnvironment: Bool {
        let url = apiBaseUrl.lowercased()
        return url.contains("mtf.") || url.contains("test")
    }

    private var hasUnsavedChanges: Bool {
        merchantId != store.merchantId ||
        apiPassword != store.apiPassword ||
        apiBaseUrl != store.apiBaseUrl ||
        apiVersion != store.apiVersion ||
        backendUrl != store.backendUrl ||
        advancedMode != store.advancedMode ||
        payloadJSON != store.payloadJSON
    }

    var body: some View {
        Form {
            environmentSection
            apiConfigurationSection
            connectionSection
            advancedJSONSection
            actionsSection
            securityNoteSection
        }
        .navigationTitle("API Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveConfiguration()
                }
                .fontWeight(.semibold)
                .disabled(!hasUnsavedChanges)
            }
        }
        .onAppear {
            if !loaded {
                loadDraft()
                loaded = true
            }
        }
        .alert("Reset to Defaults?", isPresented: $showingResetConfirmation) {
            Button("Reset", role: .destructive) {
                store.resetToDefaults()
                loadDraft()
                connectionState = .idle
                validationError = nil
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This restores the shipped configuration and clears the stored API password.")
        }
    }

    // MARK: - Sections

    private var environmentSection: some View {
        Section {
            HStack {
                Text("Environment")
                Spacer()
                Text(isTestEnvironment ? "TEST" : "LIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isTestEnvironment ? Color.orange.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(isTestEnvironment ? .orange : .red)
                    .cornerRadius(6)
            }
            if hasUnsavedChanges {
                Label("Unsaved changes", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundColor(.orange)
            }
            if savedBanner {
                Label("Configuration saved", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
            if let error = validationError {
                Label(error, systemImage: "xmark.circle.fill")
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        } footer: {
            if let savedAt = store.lastSavedAt {
                Text("Last saved: \(savedAt.formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    private var apiConfigurationSection: some View {
        Section("Gateway") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Merchant ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("TESTMIDtesting00", text: $merchantId)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Username (auto-generated)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(apiUsername)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Password")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    if showPassword {
                        TextField("Empty = backend fallback", text: $apiPassword)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        SecureField("Empty = backend fallback", text: $apiPassword)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Base URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("https://mtf.gateway.mastercard.com", text: $apiBaseUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Version")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("100", text: $apiVersion)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var connectionSection: some View {
        Section("Backend") {
            VStack(alignment: .leading, spacing: 4) {
                Text("Backend URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField(ConfigStore.Defaults.backendUrl, text: $backendUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Button(action: testConnection) {
                HStack {
                    if connectionState == .testing {
                        ProgressView()
                            .padding(.trailing, 4)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text(connectionState == .testing ? "Testing…" : "Test Connection")
                }
            }
            .disabled(connectionState == .testing)

            switch connectionState {
            case .success(let message):
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundColor(.green)
            case .failure(let message):
                Label(message, systemImage: "xmark.circle.fill")
                    .font(.footnote)
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
        }
    }

    private var advancedJSONSection: some View {
        Section {
            Toggle("Advanced payload mode", isOn: $advancedMode)

            if advancedMode {
                Text("order.id and order.amount are injected from the live cart at request time.")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                TextEditor(text: $payloadJSON)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(minHeight: 260)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: { payloadJSON = ConfigStore.defaultPayloadJSON }) {
                    Label("Restore Default Payload", systemImage: "arrow.counterclockwise")
                }
            }

            Button(action: copyJSON) {
                Label("Copy JSON", systemImage: "doc.on.doc")
            }
            Button(action: copyCurl) {
                Label("Copy as cURL", systemImage: "terminal")
            }
            if let copied = copiedBanner {
                Label(copied, systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
        } header: {
            Text("Advanced JSON")
        } footer: {
            Text(advancedMode
                 ? "The raw INITIATE_CHECKOUT payload above is sent as-is (with fresh order id/amount)."
                 : "In Simple mode the backend assembles the INITIATE_CHECKOUT payload from the fields above plus cart data.")
        }
    }

    private var actionsSection: some View {
        Section {
            Button("Cancel Changes", role: .cancel) {
                loadDraft()
                validationError = nil
            }
            .disabled(!hasUnsavedChanges)

            Button("Reset to Defaults", role: .destructive) {
                showingResetConfirmation = true
            }
        }
    }

    private var securityNoteSection: some View {
        Section {
            EmptyView()
        } footer: {
            Text("Credentials are intended for gateway TEST/demo profiles, are stored in the iOS Keychain on this device only, and are sent to the backend exclusively over HTTPS request bodies.")
        }
    }

    // MARK: - Actions

    private func loadDraft() {
        merchantId = store.merchantId
        apiPassword = store.apiPassword
        apiBaseUrl = store.apiBaseUrl
        apiVersion = store.apiVersion
        backendUrl = store.backendUrl
        advancedMode = store.advancedMode
        payloadJSON = store.payloadJSON
    }

    // FR-08.7 / FR-08A.4 validation
    private func validate() -> String? {
        if merchantId.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Merchant ID must not be empty."
        }
        guard let url = URL(string: apiBaseUrl), url.scheme == "https", url.host != nil else {
            return "API Base URL must be a valid https:// URL."
        }
        if Int(apiVersion) == nil {
            return "API Version must be numeric."
        }
        guard let backend = URL(string: backendUrl), backend.scheme != nil, backend.host != nil else {
            return "Backend URL must be a valid URL."
        }
        if advancedMode {
            guard let data = payloadJSON.data(using: .utf8),
                  (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] != nil else {
                return "Please fix JSON errors before saving."
            }
        }
        return nil
    }

    private func saveConfiguration() {
        if let error = validate() {
            validationError = error
            return
        }
        validationError = nil

        store.merchantId = merchantId.trimmingCharacters(in: .whitespaces)
        store.apiPassword = apiPassword
        store.apiBaseUrl = apiBaseUrl.trimmingCharacters(in: .whitespaces)
        store.apiVersion = apiVersion.trimmingCharacters(in: .whitespaces)
        store.backendUrl = backendUrl.trimmingCharacters(in: .whitespaces)
        store.advancedMode = advancedMode
        store.payloadJSON = payloadJSON
        store.save()
        loadDraft()

        savedBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            savedBanner = false
        }
    }

    private func testConnection() {
        connectionState = .testing

        var config = [
            "merchantId": merchantId,
            "apiBaseUrl": apiBaseUrl,
            "apiVersion": apiVersion
        ]
        if !apiPassword.isEmpty {
            config["apiPassword"] = apiPassword
        }

        BackendAPI.testConnection(config: config, backendUrl: backendUrl) { result in
            switch result {
            case .success(let response):
                let message = response.message ?? "Backend Connected"
                if response.gateway == "ok" {
                    connectionState = .success("Backend Connected — " + message)
                } else if response.backend == "ok" {
                    connectionState = .success(message)
                } else {
                    connectionState = .failure(message)
                }
            case .failure(let error):
                connectionState = .failure("Connection Error — " + error.message)
            }
        }
    }

    // MARK: - Copy helpers (FR-08A.6)

    // The effective /api/checkout request body for the current draft
    private func effectiveRequestBody(redactPassword: Bool) -> [String: Any] {
        var config: [String: Any] = [
            "merchantId": merchantId,
            "apiBaseUrl": apiBaseUrl,
            "apiVersion": apiVersion
        ]
        if !apiPassword.isEmpty {
            config["apiPassword"] = redactPassword ? "•••" : apiPassword
        }

        var body: [String: Any] = [
            "amount": "1.00",
            "currency": "USD",
            "orderId": "ORDER123",
            "config": config
        ]
        if advancedMode,
           let data = payloadJSON.data(using: .utf8),
           let override = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            body["payloadOverride"] = override
        }
        return body
    }

    private func prettyJSON(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    private func copyJSON() {
        UIPasteboard.general.string = prettyJSON(effectiveRequestBody(redactPassword: false))
        flashCopied("JSON copied to clipboard")
    }

    private func copyCurl() {
        let json = prettyJSON(effectiveRequestBody(redactPassword: true))
        let curl = """
        curl -X POST '\(backendUrl)/api/checkout' \\
          -H 'Content-Type: application/json' \\
          -d '\(json)'
        """
        UIPasteboard.general.string = curl
        flashCopied("cURL copied (password redacted)")
    }

    private func flashCopied(_ message: String) {
        copiedBanner = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            copiedBanner = nil
        }
    }
}
