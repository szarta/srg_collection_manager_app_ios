import Foundation

// MARK: - Folder Model

/// Entity representing a collection folder (Owned, Wanted, Trade, or custom)
struct Folder: Identifiable, Codable {
    let id: String
    let name: String
    let isDefault: Bool  // true for Owned, Wanted, Trade
    let displayOrder: Int
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDefault = "is_default"
        case displayOrder = "display_order"
        case createdAt = "created_at"
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        isDefault: Bool = false,
        displayOrder: Int = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.displayOrder = displayOrder
        self.createdAt = createdAt
    }
}
