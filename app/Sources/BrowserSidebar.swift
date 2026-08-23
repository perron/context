// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SwiftUI

struct BrowserSidebar: View {
    @ObservedObject var browser: BrowserStore
    let hideSidebar: () -> Void
    let showAssistant: () -> Void
    let showLibrary: () -> Void
    let showSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tabs")
                    .font(.title2.weight(.bold))
                Spacer()
                Button(action: hideSidebar) {
                    Label("Hide tabs", systemImage: "sidebar.left")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Hide tabs")
                .accessibilityIdentifier("hideTabsSidebarButton")
                Button {
                    browser.addTab()
                } label: {
                    Label("New tab", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
            }
            .padding()

            List {
                ForEach(browser.tabs) { tab in
                    Button {
                        browser.select(tab.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tab.title)
                                .lineLimit(1)
                            Text(tab.page.url?.host() ?? "New tab")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .background(
                            tab.id == browser.selectedTabID
                                ? Color.primary.opacity(0.06)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(
                        tab.id == browser.selectedTabID ? .isSelected : []
                    )
                    .contextMenu {
                        Button("Close", role: .destructive) {
                            browser.close(tab.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            VStack(spacing: 0) {
                Button(action: showAssistant) {
                    Label("Ask Grok Bot", systemImage: "sparkles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                Button(action: showLibrary) {
                    Label("Library", systemImage: "books.vertical")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                Button(action: showSettings) {
                    Label("Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .buttonStyle(.plain)
        }
        .background(Color.contextPaper)
    }
}
