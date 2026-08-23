// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct LibraryView: View {
    @ObservedObject var library: BrowserLibraryStore
    let open: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selection: LibrarySection = .bookmarks
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                VStack(spacing: 14) {
                    Picker("Library section", selection: $selection) {
                        ForEach(LibrarySection.allCases) { section in
                            Label(section.title, systemImage: section.symbol)
                                .tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredPages.isEmpty {
                        emptyState
                    } else {
                        pageList
                    }
                }
            }
            .navigationTitle("Library")
            .foregroundStyle(Color.contextNightText)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: selection.searchPrompt
            )
            .toolbarBackground(Color.contextNight.opacity(0.94), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if selection == .history, !library.history.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            library.clearHistory()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var filteredPages: [SavedPage] {
        let pages = selection == .bookmarks ? library.bookmarks : library.history
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return pages
        }
        return pages.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.urlString.localizedCaseInsensitiveContains(query)
        }
    }

    private var pageList: some View {
        List {
            ForEach(filteredPages) { page in
                Button {
                    guard let url = page.url else {
                        return
                    }
                    open(url)
                    dismiss()
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: pageSymbol(for: page))
                            .font(.title3)
                            .foregroundStyle(Color.contextTint)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(page.title)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.contextNightText)
                                .lineLimit(1)
                            Text(page.url?.host() ?? page.urlString)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)
                        Text(page.savedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.contextNightRaised.opacity(0.84))
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        delete(page)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(selection.emptyTitle, systemImage: selection.symbol)
        } description: {
            Text(selection.emptyDescription)
        }
        .foregroundStyle(Color.contextNightText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ page: SavedPage) {
        switch selection {
        case .bookmarks:
            library.removeBookmark(page)
        case .history:
            library.removeHistory(page)
        }
    }

    private func pageSymbol(for page: SavedPage) -> String {
        switch selection {
        case .bookmarks:
            "bookmark.fill"
        case .history:
            "clock.arrow.circlepath"
        }
    }
}

private enum LibrarySection: String, CaseIterable, Identifiable {
    case bookmarks
    case history

    var id: Self { self }

    var title: String {
        switch self {
        case .bookmarks: "Bookmarks"
        case .history: "History"
        }
    }

    var symbol: String {
        switch self {
        case .bookmarks: "bookmark"
        case .history: "clock.arrow.circlepath"
        }
    }

    var searchPrompt: String {
        switch self {
        case .bookmarks: "Search bookmarks"
        case .history: "Search history"
        }
    }

    var emptyTitle: String {
        switch self {
        case .bookmarks: "No bookmarks yet"
        case .history: "No history yet"
        }
    }

    var emptyDescription: String {
        switch self {
        case .bookmarks: "Save a page from the page-actions menu and it will appear here."
        case .history: "Pages you visit appear here and stay on this device."
        }
    }
}
