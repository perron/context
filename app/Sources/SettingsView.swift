// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import WebKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingClearDataConfirmation = false
    @State private var isClearingWebsiteData = false
    @State private var didClearWebsiteData = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Browser") {
                    LabeledContent("Search engine", value: "Google")
                    LabeledContent("New tabs", value: "Context home")
                }

                Section {
                    Link(destination: ContextLinks.grok) {
                        Label("Open grok.com", systemImage: "sparkles")
                    }
                    Button(action: openGrokBot) {
                        Label("Open Grok Bot", systemImage: "arrow.up.forward.app")
                    }
                } header: {
                    Text("Grok")
                } footer: {
                    Text(
                        "Context does not connect to your Grok or X account. Use Ask Grok to review "
                            + "and share page context through iOS."
                    )
                }

                Section("Privacy") {
                    Label("History stays on this device", systemImage: "iphone")
                    Label("No analytics or tracking SDK", systemImage: "hand.raised")
                    Button(role: .destructive) {
                        isShowingClearDataConfirmation = true
                    } label: {
                        Label("Clear website data", systemImage: "trash")
                    }
                    .accessibilityIdentifier("clear-website-data-button")
                    .disabled(isClearingWebsiteData)
                    if isClearingWebsiteData {
                        Label("Clearing website data…", systemImage: "hourglass")
                            .foregroundStyle(.secondary)
                    } else if didClearWebsiteData {
                        Label("Website data cleared", systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: ContextLinks.privacy) {
                        Label("Privacy policy", systemImage: "doc.text")
                    }
                    Text("Websites you visit may collect data under their own policies.")
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack(spacing: 12) {
                        Image("ContextMark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading) {
                            Text("Context")
                                .font(.headline)
                            Text("By Topcloud LLC")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent("Version", value: versionDescription)
                    LabeledContent("License", value: "MPL-2.0")
                    Link(destination: ContextLinks.easyListLicense) {
                        Label(
                            "EasyList and EasyPrivacy (CC BY-SA)",
                            systemImage: "shield.checkered"
                        )
                    }
                    .accessibilityIdentifier("easylist-attribution-link")
                    Link(destination: ContextLinks.source) {
                        Label("Source code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: ContextLinks.support) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Clear website data?",
                isPresented: $isShowingClearDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear website data", role: .destructive) {
                    clearWebsiteData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This signs you out of websites and removes their cookies, cache, and local storage. "
                        + "Bookmarks and browsing history are not removed."
                )
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var versionDescription: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openGrokBot() {
        UIApplication.shared.open(ContextLinks.grokBotOpen) { success in
            guard !success else {
                return
            }
            UIApplication.shared.open(ContextLinks.grokBotHelp)
        }
    }

    private func clearWebsiteData() {
        isClearingWebsiteData = true
        didClearWebsiteData = false
        Task {
            await WebsiteDataCleaner.clearAll()
            isClearingWebsiteData = false
            didClearWebsiteData = true
        }
    }
}

@MainActor
private enum WebsiteDataCleaner {
    static func clearAll() async {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: .distantPast
            ) {
                continuation.resume()
            }
        }
    }
}
