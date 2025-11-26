import Foundation

// MARK: - Card Model

/// Entity representing a card from the SRG database (synced from get-diced.com)
/// Supports all 7 card types with optional fields for type-specific attributes
struct Card: Identifiable, Codable {
    let id: String
    let name: String
    let cardType: String  // MainDeckCard, SingleCompetitorCard, TornadoCompetitorCard, etc.
    let rulesText: String?
    let errataText: String?
    let isBanned: Bool
    let releaseSet: String?
    let srgUrl: String?
    let srgpcUrl: String?
    let comments: String?
    let tags: String?  // Stored as comma-separated string

    // Competitor-specific fields (nil for non-competitor cards)
    let power: Int?
    let agility: Int?
    let strike: Int?
    let submission: Int?
    let grapple: Int?
    let technique: Int?
    let division: String?
    let gender: String?  // For SingleCompetitorCard only

    // MainDeckCard-specific fields (nil for non-main-deck cards)
    let deckCardNumber: Int?
    let atkType: String?  // Strike, Grapple, Submission
    let playOrder: String?  // Lead, Followup, Finish

    let syncedAt: Int64

    // CodingKeys to match database column names
    enum CodingKeys: String, CodingKey {
        case id = "db_uuid"
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
        case syncedAt = "synced_at"
    }

    // MARK: - Initializers

    init(
        id: String,
        name: String,
        cardType: String,
        rulesText: String? = nil,
        errataText: String? = nil,
        isBanned: Bool = false,
        releaseSet: String? = nil,
        srgUrl: String? = nil,
        srgpcUrl: String? = nil,
        comments: String? = nil,
        tags: String? = nil,
        power: Int? = nil,
        agility: Int? = nil,
        strike: Int? = nil,
        submission: Int? = nil,
        grapple: Int? = nil,
        technique: Int? = nil,
        division: String? = nil,
        gender: String? = nil,
        deckCardNumber: Int? = nil,
        atkType: String? = nil,
        playOrder: String? = nil,
        syncedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.cardType = cardType
        self.rulesText = rulesText
        self.errataText = errataText
        self.isBanned = isBanned
        self.releaseSet = releaseSet
        self.srgUrl = srgUrl
        self.srgpcUrl = srgpcUrl
        self.comments = comments
        self.tags = tags
        self.power = power
        self.agility = agility
        self.strike = strike
        self.submission = submission
        self.grapple = grapple
        self.technique = technique
        self.division = division
        self.gender = gender
        self.deckCardNumber = deckCardNumber
        self.atkType = atkType
        self.playOrder = playOrder
        self.syncedAt = syncedAt
    }

    // MARK: - Helper Properties

    var isCompetitor: Bool {
        cardType.contains("Competitor")
    }

    var isMainDeck: Bool {
        cardType == "MainDeckCard"
    }

    var tagList: [String] {
        tags?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? []
    }
}

// MARK: - Card Related Finishes

/// Entity for card finish relationships (e.g., foil variants)
struct CardRelatedFinish: Codable {
    let cardUuid: String
    let finishUuid: String

    enum CodingKeys: String, CodingKey {
        case cardUuid = "card_uuid"
        case finishUuid = "finish_uuid"
    }
}

// MARK: - Card Related Cards

/// Entity for related card relationships
struct CardRelatedCard: Codable {
    let cardUuid: String
    let relatedUuid: String

    enum CodingKeys: String, CodingKey {
        case cardUuid = "card_uuid"
        case relatedUuid = "related_uuid"
    }
}
