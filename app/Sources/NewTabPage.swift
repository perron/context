// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BrowserKit
import SwiftUI

struct NewTabPage: View {
    let contentRuleStatus: ContentRuleStatus
    let open: (URL) -> Void
    let openGrok: () -> Void
    let showAssistant: () -> Void

    private let sites = [
        TopSite(name: "Grok", monogram: "G", url: ContextLinks.grok),
        TopSite(name: "X", monogram: "X", url: ContextLinks.xHome),
        TopSite(name: "GitHub", monogram: "Gh", url: URL(string: "https://github.com")!),
        TopSite(name: "Wikipedia", monogram: "W", url: URL(string: "https://wikipedia.org")!)
    ]

    var body: some View {
        ZStack {
            NightSkyBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 7) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                brand
                                Spacer(minLength: 12)
                                protectionPill
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                brand
                                protectionPill
                            }
                        }

                        Text("Your page. Ready for Grok.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    Button(action: showAssistant) {
                        HStack(spacing: 16) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ask Grok")
                                    .font(.headline)
                                Text("Review and share useful page context")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.70))
                            }

                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(18)
                        .background(
                            Color.contextTint.opacity(0.92),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ask Grok")

                    sectionLabel("Quick Links")
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                        spacing: 12
                    ) {
                        ForEach(sites) { site in
                            Button {
                                open(site.url)
                            } label: {
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.08))
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay {
                                            Text(site.monogram)
                                                .font(.headline.weight(.bold))
                                        }
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.white.opacity(0.10), lineWidth: 1)
                                        }

                                    Text(site.name)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.68))
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(Color.contextTint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Private by default")
                                .font(.subheadline.weight(.semibold))
                            Text("Browsing data stays on this device. Context includes no analytics or tracking SDK.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                        }
                    }
                    .padding(16)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button("Open grok.com", action: openGrok)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.contextTint)
                }
                .foregroundStyle(Color.contextNightText)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 130)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var protectionPill: some View {
        Label(protectionLabel, systemImage: protectionSymbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(contentRuleStatus.isFailure ? Color.red : .white)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(.white.opacity(0.09), in: Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.10), lineWidth: 1)
            }
            .accessibilityIdentifier("content-protection-status")
    }

    private var brand: some View {
        HStack(spacing: 12) {
            Image("ContextMark")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Context")
                .font(.title2.bold())
        }
    }

    private var protectionLabel: String {
        switch contentRuleStatus {
        case .preparing:
            "Protection preparing"
        case .ready:
            "Protection on"
        case .failed:
            "Protection unavailable"
        }
    }

    private var protectionSymbol: String {
        switch contentRuleStatus {
        case .preparing:
            "shield.lefthalf.filled"
        case .ready:
            "shield.checkered"
        case .failed:
            "exclamationmark.shield"
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white.opacity(0.82))
    }
}

private extension ContentRuleStatus {
    var isFailure: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

private struct TopSite: Identifiable {
    let name: String
    let monogram: String
    let url: URL

    var id: URL {
        url
    }
}
