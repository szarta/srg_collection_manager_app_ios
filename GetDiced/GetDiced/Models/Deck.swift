import Foundation

// MARK: - Enums

/// Spectacle type for a deck
enum SpectacleType: String, Codable {
    case newman = "NEWMAN"
    case valiant = "VALIANT"
}

/// Slot type for cards in a deck
enum DeckSlotType: String, Codable {
    case entrance = "ENTRANCE"
    case competitor = "COMPETITOR"
    case deck = "DECK"        // Deck cards 1-30
    case finish = "FINISH"
    case alternate = "ALTERNATE"
}

// MARK: - Deck Model

/// A deck within a deck folder
struct Deck: Identifiable, Codable, Hashable {
    let id: String
    let folderId: String
    let name: String
    let spectacleType: SpectacleType
    let createdAt: Int64
    let modifiedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case folderId = "folder_id"
        case name
        case spectacleType = "spectacle_type"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }

    init(
        id: String = UUID().uuidString,
        folderId: String,
        name: String,
        spectacleType: SpectacleType = .valiant,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        modifiedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.folderId = folderId
        self.name = name
        self.spectacleType = spectacleType
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - DeckCard Model

/// A card slot in a deck
struct DeckCard: Codable, Hashable {
    let deckId: String
    let cardUuid: String
    let slotType: DeckSlotType
    let slotNumber: Int  // 1-30 for DECK type, 0 for others, increments for multiple FINISH/ALTERNATE

    enum CodingKeys: String, CodingKey {
        case deckId = "deck_id"
        case cardUuid = "card_uuid"
        case slotType = "slot_type"
        case slotNumber = "slot_number"
    }

    init(
        deckId: String,
        cardUuid: String,
        slotType: DeckSlotType,
        slotNumber: Int = 0
    ) {
        self.deckId = deckId
        self.cardUuid = cardUuid
        self.slotType = slotType
        self.slotNumber = slotNumber
    }

    // Hashable conformance for composite key
    func hash(into hasher: inout Hasher) {
        hasher.combine(deckId)
        hasher.combine(slotType)
        hasher.combine(slotNumber)
    }

    static func == (lhs: DeckCard, rhs: DeckCard) -> Bool {
        lhs.deckId == rhs.deckId &&
        lhs.slotType == rhs.slotType &&
        lhs.slotNumber == rhs.slotNumber
    }
}

// MARK: - View Models

/// Deck with its card count
struct DeckWithCardCount: Identifiable {
    let deck: Deck
    let cardCount: Int

    var id: String {
        deck.id
    }
}

/// Card with its deck slot info
struct DeckCardWithDetails: Identifiable {
    let card: Card
    let slotType: DeckSlotType
    let slotNumber: Int

    var id: String {
        card.id
    }
}
