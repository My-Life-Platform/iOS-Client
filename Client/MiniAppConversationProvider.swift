import Foundation

final class MiniAppConversationProvider {

    private static let baseHistoryKey = "my.life.history"

    private let encoder = JSONEncoder()

    private let decoder = JSONDecoder()

    func saveHistory(for appId: String, messages: [Message]) throws {
        let encoded = try self.encoder.encode(messages)

        UserDefaults.standard.set(encoded, forKey: Self.baseHistoryKey + "_\(appId)")
    }

    func getHistory(for appId: String) throws -> [[String: String]] {
        guard let data = UserDefaults.standard.data(forKey: Self.baseHistoryKey + "_\(appId)") else {
            return [[:]]
        }

        let decoded = try self.decoder.decode([Message].self, from: data)

        return decoded.sorted { lhs, rhs in
            lhs.timestamp < rhs.timestamp
        }.map { $0.dictionaryRepresentation() }
    }

}
