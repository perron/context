// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Combine
import Foundation

struct SavedPage: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    let urlString: String
    var savedAt: Date

    var url: URL? {
        URL(string: urlString)
    }
}

@MainActor
final class BrowserLibraryStore: ObservableObject {
    @Published private(set) var bookmarks: [SavedPage] = [] {
        didSet { persist(bookmarks, key: bookmarksKey) }
    }

    @Published private(set) var history: [SavedPage] = [] {
        didSet { persist(history, key: historyKey) }
    }

    private let defaults: UserDefaults
    private let bookmarksKey: String
    private let historyKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "context.library"
    ) {
        self.defaults = defaults
        self.bookmarksKey = "\(keyPrefix).bookmarks"
        self.historyKey = "\(keyPrefix).history"
        self.bookmarks = Self.load(
            key: self.bookmarksKey,
            defaults: defaults,
            decoder: decoder
        )
        self.history = Self.load(
            key: self.historyKey,
            defaults: defaults,
            decoder: decoder
        )
    }

    func isBookmarked(_ url: URL?) -> Bool {
        guard let url, let normalizedURL = normalized(url) else {
            return false
        }
        return bookmarks.contains { $0.urlString == normalizedURL }
    }

    func toggleBookmark(title: String, url: URL?) {
        guard let url, let normalizedURL = normalized(url) else {
            return
        }

        if let index = bookmarks.firstIndex(where: { $0.urlString == normalizedURL }) {
            bookmarks.remove(at: index)
            return
        }

        bookmarks.insert(
            SavedPage(
                id: UUID(),
                title: displayTitle(title, url: url),
                urlString: normalizedURL,
                savedAt: .now
            ),
            at: 0
        )
    }

    func recordHistory(title: String, url: URL?) {
        guard let url, let normalizedURL = normalized(url) else {
            return
        }

        let page = SavedPage(
            id: UUID(),
            title: displayTitle(title, url: url),
            urlString: normalizedURL,
            savedAt: .now
        )

        if let existingIndex = history.firstIndex(
            where: { $0.urlString == normalizedURL }
        ) {
            history.remove(at: existingIndex)
        }
        history.insert(page, at: 0)
        if history.count > 500 {
            history.removeLast(history.count - 500)
        }
    }

    func refreshTitle(_ title: String, for url: URL?) {
        guard let url,
              let normalizedURL = normalized(url),
              let index = history.firstIndex(
                  where: { $0.urlString == normalizedURL }
              ) else {
            return
        }

        history[index].title = displayTitle(title, url: url)
    }

    func removeBookmark(_ page: SavedPage) {
        bookmarks.removeAll { $0.id == page.id }
    }

    func removeHistory(_ page: SavedPage) {
        history.removeAll { $0.id == page.id }
    }

    func clearHistory() {
        history.removeAll()
    }

    private func normalized(_ url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.url?.absoluteString
    }

    private func displayTitle(_ title: String, url: URL) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? (url.host() ?? url.absoluteString) : trimmedTitle
    }

    private func persist(_ pages: [SavedPage], key: String) {
        guard let data = try? encoder.encode(pages) else {
            return
        }
        defaults.set(data, forKey: key)
    }

    private static func load(
        key: String,
        defaults: UserDefaults,
        decoder: JSONDecoder
    ) -> [SavedPage] {
        guard let data = defaults.data(forKey: key),
              let pages = try? decoder.decode([SavedPage].self, from: data) else {
            return []
        }
        return pages
    }
}
