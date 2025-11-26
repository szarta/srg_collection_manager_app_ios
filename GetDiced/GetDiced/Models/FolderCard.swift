import Foundation

// MARK: - FolderCard Model

/// Junction table representing many-to-many relationship between folders and cards
/// A card can exist in multiple folders with different quantities
struct FolderCard: Codable, Hashable {
    let folderId: String
    let cardUuid: String
    let quantity: Int
    let addedAt: Int64

    enum CodingKeys: String, CodingKey {
        case folderId = "folder_id"
        case cardUuid = "card_uuid"
        case quantity
        case addedAt = "added_at"
    }

    init(
        folderId: String,
        cardUuid: String,
        quantity: Int = 1,
        addedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.folderId = folderId
        self.cardUuid = cardUuid
        self.quantity = quantity
        self.addedAt = addedAt
    }

    // Hashable conformance for composite key
    func hash(into hasher: inout Hasher) {
        hasher.combine(folderId)
        hasher.combine(cardUuid)
    }

    static func == (lhs: FolderCard, rhs: FolderCard) -> Bool {
        lhs.folderId == rhs.folderId && lhs.cardUuid == rhs.cardUuid
    }
}
