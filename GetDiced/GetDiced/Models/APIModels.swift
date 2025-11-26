import Foundation

// MARK: - API Response Models

/// Paginated card response from search endpoint
struct PaginatedCardResponse: Codable {
    let totalCount: Int
    let items: [CardDTO]

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case items
    }
}

/// Card Data Transfer Object from API
struct CardDTO: Codable {
    let dbUuid: String
    let name: String
    let cardType: String
    let rulesText: String?
    let errataText: String?
    let isBanned: Bool
    let releaseSet: String?
    let srgUrl: String?
    let srgpcUrl: String?
    let comments: String?
    let tags: [String]?

    // Competitor fields
    let power: Int?
    let agility: Int?
    let strike: Int?
    let submission: Int?
    let grapple: Int?
    let technique: Int?
    let division: String?
    let gender: String?

    // MainDeck fields
    let deckCardNumber: Int?
    let atkType: String?
    let playOrder: String?

    enum CodingKeys: String, CodingKey {
        case dbUuid = "db_uuid"
        case name
        case cardType = "card_type"
        case rulesText = "rules_text"
        case errataText = "errata_text"
        case isBanned = "is_banned"
        case releaseSet = "release_set"
        case srgUrl = "srg_url"
        case srgpcUrl = "srgpc_url"
        case comments
        case tags
        case power
        case agility
        case strike
        case submission
        case grapple
        case technique
        case division
        case gender
        case deckCardNumber = "deck_card_number"
        case atkType = "atk_type"
        case playOrder = "play_order"
    }

    /// Convert CardDTO to Card model
    func toCard() -> Card {
        Card(
            id: dbUuid,
            name: name,
            cardType: cardType,
            rulesText: rulesText,
            errataText: errataText,
            isBanned: isBanned,
            releaseSet: releaseSet,
            srgUrl: srgUrl,
            srgpcUrl: srgpcUrl,
            comments: comments,
            tags: tags?.joined(separator: ", "),  // Convert array to comma-separated string
            power: power,
            agility: agility,
            strike: strike,
            submission: submission,
            grapple: grapple,
            technique: technique,
            division: division,
            gender: gender,
            deckCardNumber: deckCardNumber,
            atkType: atkType,
            playOrder: playOrder
        )
    }
}

/// Request for batch card lookup
struct CardBatchRequest: Codable {
    let uuids: [String]
}

/// Response for batch card lookup
struct CardBatchResponse: Codable {
    let rows: [CardDTO]
    let missing: [String]
}

/// Request to create a shared list
struct SharedListRequest: Codable {
    let name: String?
    let description: String?
    let cardUuids: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case cardUuids = "card_uuids"
    }
}

/// Response from shared list GET
struct SharedListResponse: Codable {
    let id: String
    let name: String?
    let description: String?
    let cardUuids: [String]
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case cardUuids = "card_uuids"
        case createdAt = "created_at"
    }
}

/// Response from shared list creation
struct SharedListCreateResponse: Codable {
    let id: String
    let url: String
    let message: String
}

/// Cards database manifest for sync
struct CardsManifest: Codable {
    let version: Int
    let generated: String
    let filename: String
    let hash: String
    let sizeBytes: Int64
    let cardCount: Int
    let relatedFinishesCount: Int
    let relatedCardsCount: Int

    enum CodingKeys: String, CodingKey {
        case version
        case generated
        case filename
        case hash
        case sizeBytes = "size_bytes"
        case cardCount = "card_count"
        case relatedFinishesCount = "related_finishes_count"
        case relatedCardsCount = "related_cards_count"
    }
}

/// Image manifest for sync
struct ImageManifest: Codable {
    let version: Int
    let generated: String
    let imageCount: Int
    let images: [String: ImageInfo]

    enum CodingKeys: String, CodingKey {
        case version
        case generated
        case imageCount = "image_count"
        case images
    }
}

/// Image info for a single image
struct ImageInfo: Codable {
    let path: String
    let hash: String
}
