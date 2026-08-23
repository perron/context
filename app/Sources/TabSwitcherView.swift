// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SwiftUI

struct TabSwitcherView: View {
    @ObservedObject var browser: BrowserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(browser.tabs) { tab in
                            tabCard(tab)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Tabs")
            .foregroundStyle(Color.contextNightText)
            .toolbarBackground(Color.contextNight.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        browser.addTab()
                        dismiss()
                    } label: {
                        Label("New tab", systemImage: "plus")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func tabCard(_ tab: BrowserTab) -> some View {
        ZStack(alignment: .topTrailing) {
            Button {
                browser.select(tab.id)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.07))
                        .frame(height: 120)
                        .overlay {
                            Image(systemName: tab.isNewTab ? "plus" : "globe")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }

                    Text(tab.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(tab.page.url?.host() ?? "Start a search")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.60))
                        .lineLimit(1)
                }
                .padding(10)
                .foregroundStyle(Color.contextNightText)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(tab.title), tab")

            Button {
                browser.close(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .padding(8)
                    .background(.regularMaterial, in: Circle())
            }
            .padding(16)
            .accessibilityLabel("Close \(tab.title)")
        }
    }
}
