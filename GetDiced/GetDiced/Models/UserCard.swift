import Foundation

// MARK: - UserCard Model

/// Entity representing a card in the user's collection or wishlist
/// NOTE: This model may be deprecated in favor of the Folder/FolderCard system
struct UserCard: Identifiable, Codable {
    let id: String  // UUID from card database or custom identifier
    let cardName: String  // Display name
    let quantityOwned: Int
    let quantityWanted: Int
    let isCustom: Bool  // True if not found in card database
    let addedTimestamp: Int64

    enum CodingKeys: String, CodingKey {
        case id = "card_id"
        case cardName = "card_name"
        case quantityOwned = "quantity_owned"
        case quantityWanted = "quantity_wanted"
        case isCustom = "is_custom"
        case addedTimestamp = "added_timestamp"
    }

    init(
        id: String,
        cardName: String,
        quantityOwned: Int = 0,
        quantityWanted: Int = 0,
        isCustom: Bool = false,
        addedTimestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.cardName = cardName
        self.quantityOwned = quantityOwned
        self.quantityWanted = quantityWanted
        self.isCustom = isCustom
        self.addedTimestamp = addedTimestamp
    }
}
