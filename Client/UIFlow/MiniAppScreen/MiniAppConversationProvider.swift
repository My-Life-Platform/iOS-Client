import Foundation

final class MiniAppConversationProvider {

    private static let baseHistoryKey = "my.life.history"

    private static let baseSystemPrompt = "You are a helpful assistant"

    private let encoder = JSONEncoder()

    private let decoder = JSONDecoder()

    // forgive me
    static let shared = MiniAppConversationProvider()

    func saveHistory(for appId: String, messages: [Message]) throws {
        let encoded = try self.encoder.encode(messages)

        UserDefaults.standard.set(encoded, forKey: Self.baseHistoryKey + "_\(appId)")
    }

    func getHistory(for appId: String) throws -> [Message] {
        guard let data = UserDefaults.standard.data(forKey: Self.baseHistoryKey + "_\(appId)") else {
            return [Message(role: .system, content: Self.baseSystemPrompt, timestamp: Date(), miniAppId: appId)]
        }

        let decoded = try self.decoder.decode([Message].self, from: data)

        if decoded.isEmpty {
            return [Message(role: .system, content: Self.baseSystemPrompt, timestamp: Date(), miniAppId: appId)]
        }

        return decoded.sorted { lhs, rhs in
            lhs.timestamp < rhs.timestamp
        }
    }

}
