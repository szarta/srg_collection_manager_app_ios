import Foundation

// MARK: - DeckFolder Model

/// Folder for organizing decks by type (Singles, Tornado, Trios, Tag, custom)
struct DeckFolder: Identifiable, Codable {
    let id: String
    let name: String
    let isDefault: Bool
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDefault = "is_default"
        case displayOrder = "display_order"
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        isDefault: Bool = false,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.displayOrder = displayOrder
    }
}
