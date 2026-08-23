// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("grokBotTeammateName") private var teammateName = "Context"

    var body: some View {
        NavigationStack {
            Form {
                Section("Browser") {
                    LabeledContent("Search engine", value: "Google")
                    LabeledContent("New tabs", value: "Context home")
                }

                Section("Grok") {
                    Link(destination: ContextLinks.grok) {
                        Label("Open grok.com", systemImage: "sparkles")
                    }
                    Button(action: openGrokBot) {
                        Label("Open Grok Bot", systemImage: "arrow.up.forward.app")
                    }
                    TextField("Grok Bot teammate", text: $teammateName)
                    Text(
                        "The teammate name is included in handoffs. Current Grok Bot links can open "
                            + "the app but cannot route Context directly to a named teammate."
                    )
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Label("History stays on this device", systemImage: "iphone")
                    Label("No analytics or tracking SDK", systemImage: "hand.raised")
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
                    Link(destination: ContextLinks.source) {
                        Label("Source code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: ContextLinks.support) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Settings")
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
}
