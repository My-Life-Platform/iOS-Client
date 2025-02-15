import Foundation

struct Message: Codable {

    let id: String

    let role: Role

    let content: String

    let timestamp: Date

    let miniAppId: String

    init(id: String = UUID().uuidString,
         role: Role,
         content: String,
         timestamp: Date,
         miniAppId: String) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.miniAppId = miniAppId
    }

    func dictionaryRepresentation() -> [String: String] {
        return [
            "role": self.role.rawValue,
            "content": self.content
        ]
    }

}
