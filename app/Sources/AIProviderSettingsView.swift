// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct AIProviderSettingsView: View {
    @AppStorage(AIProviderPreferences.selectedProviderKey)
    private var selectedProviderID = AIProvider.xAI.rawValue
    @State private var configuredProviders: Set<AIProvider> = []

    var body: some View {
        List {
            Section {
                ForEach(AIProvider.allCases) { provider in
                    NavigationLink {
                        AIProviderDetailView(provider: provider)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: provider.symbolName)
                                .foregroundStyle(
                                    selectedProviderID == provider.rawValue
                                        ? Color.contextTint
                                        : .secondary
                                )
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(provider.settingsName)
                                Text(AIProviderPreferences.model(for: provider))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if configuredProviders.contains(provider) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.contextTint)
                                    .accessibilityLabel("API key saved")
                            }
                        }
                    }
                    .accessibilityIdentifier("ai-provider-\(provider.rawValue)")
                }
            } header: {
                Text("Providers")
            } footer: {
                Text(
                    "Choose a provider, paste your own API key, then save. API use is billed "
                        + "separately by that provider. Consumer subscriptions such as Grok, "
                        + "ChatGPT, or Claude do not include API credits."
                )
            }

            Section("On this device") {
                Label("Keys are stored in iOS Keychain", systemImage: "key.fill")
                Label("Keys are not added to browser history", systemImage: "clock.badge.xmark")
                Label("Keys are not included in iCloud backup", systemImage: "icloud.slash")
            }

            Section {
                Text(
                    "When you press Send, Context sends your conversation and the page context "
                        + "shown in Ask Grok directly to the selected provider. Review each "
                        + "provider's data and billing terms."
                )
                .foregroundStyle(.secondary)
            } header: {
                Text("Before sending")
            }
        }
        .navigationTitle("AI Providers")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshConfiguredProviders)
    }

    private func refreshConfiguredProviders() {
        configuredProviders = Set(
            AIProvider.allCases.filter { provider in
                guard let key = try? APIKeyStore.shared.key(for: provider) else {
                    return false
                }
                return !key.isEmpty
            }
        )
    }
}

private struct AIProviderDetailView: View {
    let provider: AIProvider
    let keyStore: any APIKeyStoring

    @AppStorage(AIProviderPreferences.selectedProviderKey)
    private var selectedProviderID = AIProvider.xAI.rawValue
    @State private var apiKey = ""
    @State private var model: String
    @State private var hasSavedKey = false
    @State private var savedConfirmation = false
    @State private var isShowingDeleteConfirmation = false
    @State private var errorMessage: String?

    init(
        provider: AIProvider,
        keyStore: any APIKeyStoring = APIKeyStore.shared
    ) {
        self.provider = provider
        self.keyStore = keyStore
        _model = State(initialValue: AIProviderPreferences.model(for: provider))
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Provider", value: provider.companyName)
                Link(destination: provider.keyCreationURL) {
                    Label("Create or manage API key", systemImage: "arrow.up.forward.square")
                }
            } footer: {
                Text("The provider opens in your browser. Context never sees your account password.")
            }

            Section {
                SecureField(
                    hasSavedKey ? "Paste only to replace saved key" : "Paste API key",
                    text: $apiKey
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .accessibilityIdentifier("ai-api-key-field")

                if hasSavedKey {
                    Label("API key saved in Keychain", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(Color.contextTint)
                }
            } header: {
                Text("API key")
            } footer: {
                Text(
                    "The saved key is available only while this device is unlocked and does not "
                        + "migrate to another device. Context cannot show it again after saving."
                )
            }

            Section {
                TextField("Model", text: $model)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("ai-model-field")
                Button(action: resetModel) {
                    Label("Use recommended model", systemImage: "arrow.counterclockwise")
                }
            } header: {
                Text("Model")
            } footer: {
                Text("Recommended now: \(provider.defaultModel). You can enter another model ID.")
            }

            Section {
                Button(action: save) {
                    Label(
                        savedConfirmation ? "Saved and selected" : "Save and use this provider",
                        systemImage: savedConfirmation ? "checkmark" : "key"
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .tint(.contextTint)
                .disabled(!canSave)
                .accessibilityIdentifier("save-ai-provider-button")

                if hasSavedKey {
                    Button("Delete saved API key", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(provider.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refreshSavedState)
        .confirmationDialog(
            "Delete the \(provider.name) API key?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete API key", role: .destructive, action: deleteKey)
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Could not save provider",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var canSave: Bool {
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanModel.isEmpty && (hasSavedKey || !cleanKey.isEmpty)
    }

    private func refreshSavedState() {
        do {
            hasSavedKey = try keyStore.key(for: provider)?.isEmpty == false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanKey.isEmpty {
                try keyStore.save(cleanKey, for: provider)
                apiKey = ""
            }
            AIProviderPreferences.setModel(model, for: provider)
            selectedProviderID = provider.rawValue
            hasSavedKey = true
            savedConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteKey() {
        do {
            try keyStore.deleteKey(for: provider)
            apiKey = ""
            hasSavedKey = false
            savedConfirmation = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetModel() {
        model = provider.defaultModel
    }
}
