// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case xAI
    case openAI
    case anthropic
    case gemini
    case openRouter
    case kimi
    case deepSeek
    case mistral

    var id: String { rawValue }

    var name: String {
        switch self {
        case .xAI: "Grok"
        case .openAI: "OpenAI"
        case .anthropic: "Claude"
        case .gemini: "Gemini"
        case .openRouter: "OpenRouter"
        case .kimi: "Kimi"
        case .deepSeek: "DeepSeek"
        case .mistral: "Mistral"
        }
    }

    var companyName: String {
        switch self {
        case .xAI: "xAI"
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .gemini: "Google"
        case .openRouter: "OpenRouter"
        case .kimi: "Moonshot AI"
        case .deepSeek: "DeepSeek"
        case .mistral: "Mistral AI"
        }
    }

    var settingsName: String {
        switch self {
        case .xAI: "Grok (xAI API)"
        case .openAI: "OpenAI API"
        case .anthropic: "Claude (Anthropic API)"
        case .gemini: "Gemini API"
        case .openRouter: "OpenRouter"
        case .kimi: "Kimi (Moonshot API)"
        case .deepSeek: "DeepSeek API"
        case .mistral: "Mistral API"
        }
    }

    var defaultModel: String {
        switch self {
        case .xAI: "grok-4.6"
        case .openAI: "gpt-5.6-luna"
        case .anthropic: "claude-sonnet-5"
        case .gemini: "gemini-3.6-flash"
        case .openRouter: "~openai/gpt-latest"
        case .kimi: "kimi-k3"
        case .deepSeek: "deepseek-v4-pro"
        case .mistral: "mistral-small-latest"
        }
    }

    var keyCreationURL: URL {
        switch self {
        case .xAI: URL(string: "https://console.x.ai/")!
        case .openAI: URL(string: "https://platform.openai.com/api-keys")!
        case .anthropic: URL(string: "https://console.anthropic.com/settings/keys")!
        case .gemini: URL(string: "https://aistudio.google.com/app/apikey")!
        case .openRouter: URL(string: "https://openrouter.ai/settings/keys")!
        case .kimi: URL(string: "https://platform.kimi.ai/console/api-keys")!
        case .deepSeek: URL(string: "https://platform.deepseek.com/api_keys")!
        case .mistral: URL(string: "https://console.mistral.ai/api-keys")!
        }
    }

    var symbolName: String {
        switch self {
        case .xAI: "sparkles.rectangle.stack.fill"
        case .openAI: "circle.hexagongrid"
        case .anthropic: "text.bubble"
        case .gemini: "diamond.inset.filled"
        case .openRouter: "arrow.triangle.branch"
        case .kimi: "moon.stars"
        case .deepSeek: "wave.3.right"
        case .mistral: "wind"
        }
    }

    var apiStyle: AIAPIStyle {
        switch self {
        case .xAI, .openAI: .responses
        case .anthropic: .anthropicMessages
        case .gemini: .geminiInteractions
        case .openRouter, .kimi, .deepSeek, .mistral: .chatCompletions
        }
    }

    var endpoint: URL {
        switch self {
        case .xAI: URL(string: "https://api.x.ai/v1/responses")!
        case .openAI: URL(string: "https://api.openai.com/v1/responses")!
        case .anthropic: URL(string: "https://api.anthropic.com/v1/messages")!
        case .gemini: URL(string: "https://generativelanguage.googleapis.com/v1beta/interactions")!
        case .openRouter: URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        case .kimi: URL(string: "https://api.moonshot.ai/v1/chat/completions")!
        case .deepSeek: URL(string: "https://api.deepseek.com/chat/completions")!
        case .mistral: URL(string: "https://api.mistral.ai/v1/chat/completions")!
        }
    }
}

enum AIAPIStyle: Sendable {
    case responses
    case anthropicMessages
    case geminiInteractions
    case chatCompletions
}

enum AIProviderPreferences {
    static let selectedProviderKey = "ai.selected-provider"

    static func selectedProvider(defaults: UserDefaults = .standard) -> AIProvider {
        guard let rawValue = defaults.string(forKey: selectedProviderKey),
              let provider = AIProvider(rawValue: rawValue) else {
            return .xAI
        }
        return provider
    }

    static func setSelectedProvider(
        _ provider: AIProvider,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(provider.rawValue, forKey: selectedProviderKey)
    }

    static func model(
        for provider: AIProvider,
        defaults: UserDefaults = .standard
    ) -> String {
        let stored = defaults.string(forKey: modelKey(for: provider))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let stored, !stored.isEmpty else {
            return provider.defaultModel
        }
        return stored
    }

    static func setModel(
        _ model: String,
        for provider: AIProvider,
        defaults: UserDefaults = .standard
    ) {
        let cleaned = model.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.isEmpty || cleaned == provider.defaultModel {
            defaults.removeObject(forKey: modelKey(for: provider))
        } else {
            defaults.set(cleaned, forKey: modelKey(for: provider))
        }
    }

    private static func modelKey(for provider: AIProvider) -> String {
        "ai.model.\(provider.rawValue)"
    }
}
