// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct BrowserBottomBar: View {
    @Binding var addressInput: String
    let tabCount: Int
    let submit: () -> Void
    let showTabs: () -> Void
    let showLibrary: () -> Void
    let showSettings: () -> Void
    let openGrok: () -> Void
    let showAssistant: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search or enter website", text: $addressInput)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.webSearch)
                    .submitLabel(.go)
                    .autocorrectionDisabled()
                    .onSubmit(submit)

                Button(action: showTabs) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        Text("\(tabCount)")
                            .font(.caption2.weight(.bold))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.contextInk)
                .accessibilityLabel("\(tabCount) tabs")
            }
            .padding(.leading, 14)
            .padding(.trailing, 10)
            .frame(minHeight: 48)
            .background(Color.contextCard, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.primary.opacity(0.10), lineWidth: 1)
            }

            Button(action: showAssistant) {
                GrokButton()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ask Grok")

            Menu {
                Button(action: showLibrary) {
                    Label("Library", systemImage: "books.vertical")
                }
                Button(action: openGrok) {
                    Label("Open grok.com", systemImage: "sparkles")
                }
                Button(action: showSettings) {
                    Label("Settings", systemImage: "gearshape")
                }
            } label: {
                Circle()
                    .fill(Color.contextCard)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "ellipsis")
                            .font(.body.weight(.semibold))
                    }
            }
            .tint(Color.contextInk)
            .accessibilityLabel("More")
        }
    }
}

private struct GrokButton: View {
    var body: some View {
        Circle()
            .fill(Color.contextTint)
            .frame(width: 48, height: 48)
            .overlay {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
            }
    }
}
