import Foundation
import SQLite

/// Database service for managing SQLite operations
@MainActor
class DatabaseService {

    // MARK: - Properties

    private var db: Connection?
    private let dbPath: String

    // MARK: - Table Definitions

    // Cards table
    private let cards = Table("cards")
    private let card_dbUuid = Expression<String>("db_uuid")
    private let card_name = Expression<String>("name")
    private let card_cardType = Expression<String>("card_type")
    private let card_rulesText = Expression<String?>("rules_text")
    private let card_errataText = Expression<String?>("errata_text")
    private let card_isBanned = Expression<Bool>("is_banned")
    private let card_releaseSet = Expression<String?>("release_set")
    private let card_srgUrl = Expression<String?>("srg_url")
    private let card_srgpcUrl = Expression<String?>("srgpc_url")
    private let card_comments = Expression<String?>("comments")
    private let card_tags = Expression<String?>("tags")
    private let card_power = Expression<Int?>("power")
    private let card_agility = Expression<Int?>("agility")
    private let card_strike = Expression<Int?>("strike")
    private let card_submission = Expression<Int?>("submission")
    private let card_grapple = Expression<Int?>("grapple")
    private let card_technique = Expression<Int?>("technique")
    private let card_division = Expression<String?>("division")
    private let card_gender = Expression<String?>("gender")
    private let card_deckCardNumber = Expression<Int?>("deck_card_number")
    private let card_atkType = Expression<String?>("atk_type")
    private let card_playOrder = Expression<String?>("play_order")
    private let card_syncedAt = Expression<Int64>("synced_at")

    // Folders table
    private let folders = Table("folders")
    private let folder_id = Expression<String>("id")
    private let folder_name = Expression<String>("name")
    private let folder_isDefault = Expression<Bool>("is_default")
    private let folder_displayOrder = Expression<Int>("display_order")
    private let folder_createdAt = Expression<Int64>("created_at")

    // FolderCards junction table
    private let folderCards = Table("folder_cards")
    private let fc_folderId = Expression<String>("folder_id")
    private let fc_cardUuid = Expression<String>("card_uuid")
    private let fc_quantity = Expression<Int>("quantity")
    private let fc_addedAt = Expression<Int64>("added_at")

    // Decks tables
    private let deckFolders = Table("deck_folders")
    private let decks = Table("decks")
    private let deckCards = Table("deck_cards")

    // MARK: - Initialization

    init() throws {
        // Get Documents directory
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dbURL = documentsURL.appendingPathComponent("user_cards.db")
        self.dbPath = dbURL.path

        // Initialize database
        try initializeDatabase()
        try openConnection()
    }

    // MARK: - Database Setup

    /// Initialize database by copying from bundle if needed
    private func initializeDatabase() throws {
        let fileManager = FileManager.default
        let dbURL = URL(fileURLWithPath: dbPath)

        // Check if database already exists
        if !fileManager.fileExists(atPath: dbPath) {
            // Copy from bundle
            guard let bundleURL = Bundle.main.url(forResource: "cards_initial", withExtension: "db") else {
                throw DatabaseError.bundleDatabaseNotFound
            }

            try fileManager.copyItem(at: bundleURL, to: dbURL)
            print("✅ Database initialized from bundle")
        } else {
            print("✅ Database already exists at: \(dbPath)")
        }
    }

    /// Open database connection
    private func openConnection() throws {
        db = try Connection(dbPath)
        print("✅ Database connection opened")
    }

    /// Get the database file path
    func databasePath() -> String {
        return dbPath
    }

    /// Ensure default folders exist
    func ensureDefaultFolders() async throws {
        let defaultFolderNames = ["Owned", "Wanted", "Favorites", "For Trade"]

        for (index, name) in defaultFolderNames.enumerated() {
            let folderId = name.lowercased().replacingOccurrences(of: " ", with: "_")
            let existing = try await getFolder(byId: folderId)

            if existing == nil {
                let folder = Folder(
                    id: folderId,
                    name: name,
                    isDefault: true,
                    displayOrder: index
                )
                try await saveFolder(folder)
                print("✅ Created default folder: \(name)")
            }
        }
    }

    // MARK: - Card Queries

    /// Get all cards (WARNING: 3,923 cards - use with pagination or filters)
    func getAllCards() async throws -> [Card] {
        guard let db = db else { throw DatabaseError.notConnected }

        var results: [Card] = []
        for row in try db.prepare(cards.order(card_name)) {
            results.append(try parseCard(from: row))
        }
        return results
    }

    /// Get card by UUID
    func getCard(byId uuid: String) async throws -> Card? {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.filter(card_dbUuid == uuid)
        guard let row = try db.pluck(query) else { return nil }
        return try parseCard(from: row)
    }

    /// Get card by name (case-insensitive)
    func getCard(byName name: String) async throws -> Card? {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.filter(card_name.like(name, escape: nil)).limit(1)
        guard let row = try db.pluck(query) else { return nil }
        return try parseCard(from: row)
    }

    /// Search cards by name (case-insensitive, LIMIT 50)
    func searchCards(query: String, limit: Int = 50) async throws -> [Card] {
        guard let db = db else { throw DatabaseError.notConnected }

        let searchQuery = cards
            .filter(card_name.like("%\(query)%", escape: nil))
            .order(card_name)
            .limit(limit)

        var results: [Card] = []
        for row in try db.prepare(searchQuery) {
            results.append(try parseCard(from: row))
        }
        return results
    }

    /// Search cards with advanced filters
    func searchCards(
        query: String?,
        cardType: String?,
        atkType: String?,
        playOrder: String?,
        division: String?,
        releaseSet: String?,
        isBanned: Bool?,
        limit: Int = 100
    ) async throws -> [Card] {
        guard let db = db else { throw DatabaseError.notConnected }

        var searchQuery = cards.order(card_name).limit(limit)

        // Name/rules text search
        if let query = query, !query.isEmpty {
            let nameMatch = card_name.like("%\(query)%", escape: nil)
            let rulesMatch = card_rulesText.like("%\(query)%", escape: nil)
            searchQuery = searchQuery.filter(nameMatch || rulesMatch)
        }

        // Card type filter
        if let cardType = cardType {
            searchQuery = searchQuery.filter(card_cardType == cardType)
        }

        // Attack type filter
        if let atkType = atkType {
            searchQuery = searchQuery.filter(card_atkType == atkType)
        }

        // Play order filter
        if let playOrder = playOrder {
            searchQuery = searchQuery.filter(card_playOrder == playOrder)
        }

        // Division filter
        if let division = division {
            searchQuery = searchQuery.filter(card_division == division)
        }

        // Release set filter
        if let releaseSet = releaseSet {
            searchQuery = searchQuery.filter(card_releaseSet == releaseSet)
        }

        // Banned filter
        if let isBanned = isBanned {
            searchQuery = searchQuery.filter(card_isBanned == isBanned)
        }

        // Execute
        var results: [Card] = []
        for row in try db.prepare(searchQuery) {
            results.append(try parseCard(from: row))
        }
        return results
    }

    /// Get cards by type
    func getCards(byType cardType: String) async throws -> [Card] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.filter(card_cardType == cardType).order(card_name)
        var results: [Card] = []
        for row in try db.prepare(query) {
            results.append(try parseCard(from: row))
        }
        return results
    }

    /// Get all unique card types
    func getAllCardTypes() async throws -> [String] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.select(distinct: card_cardType).order(card_cardType)
        return try db.prepare(query).map { $0[card_cardType] }
    }

    /// Get all unique divisions
    func getAllDivisions() async throws -> [String] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.select(distinct: card_division).filter(card_division != nil).order(card_division)
        return try db.prepare(query).compactMap { $0[card_division] }
    }

    /// Get all unique release sets
    func getAllReleaseSets() async throws -> [String] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.select(distinct: card_releaseSet).filter(card_releaseSet != nil).order(card_releaseSet)
        return try db.prepare(query).compactMap { $0[card_releaseSet] }
    }

    /// Get total card count
    func getCardCount() async throws -> Int {
        guard let db = db else { throw DatabaseError.notConnected }
        return try db.scalar(cards.count)
    }

    /// Get last sync timestamp
    func getLastSyncTime() async throws -> Int64? {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = cards.select(card_syncedAt).order(card_syncedAt.desc).limit(1)
        return try db.pluck(query)?[card_syncedAt]
    }

    // MARK: - Folder Queries

    /// Get all folders (default + custom)
    func getAllFolders() async throws -> [Folder] {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = folders.order(folder_displayOrder, folder_createdAt)
        var results: [Folder] = []
        for row in try db.prepare(query) {
            results.append(try parseFolder(from: row))
        }
        return results
    }

    /// Get folder by ID
    func getFolder(byId folderId: String) async throws -> Folder? {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = folders.filter(folder_id == folderId)
        guard let row = try db.pluck(query) else { return nil }
        return try parseFolder(from: row)
    }

    /// Insert or update folder
    func saveFolder(_ folder: Folder) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        try db.run(folders.insert(or: .replace,
            folder_id <- folder.id,
            folder_name <- folder.name,
            folder_isDefault <- folder.isDefault,
            folder_displayOrder <- folder.displayOrder,
            folder_createdAt <- folder.createdAt
        ))
    }

    /// Delete folder (cascade deletes folder_cards)
    func deleteFolder(byId folderId: String) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let folder = folders.filter(folder_id == folderId)
        try db.run(folder.delete())
    }

    // MARK: - Folder-Card Relationship Queries

    /// Get all cards in a folder (with quantities)
    func getCardsInFolder(folderId: String) async throws -> [(card: Card, quantity: Int, addedAt: Int64)] {
        guard let db = db else { throw DatabaseError.notConnected }

        // Join cards with folder_cards
        let query = """
            SELECT c.*, fc.quantity, fc.added_at
            FROM cards c
            INNER JOIN folder_cards fc ON c.db_uuid = fc.card_uuid
            WHERE fc.folder_id = ?
            ORDER BY c.name ASC
        """

        var results: [(Card, Int, Int64)] = []
        for row in try db.prepare(query, [folderId]) {
            // Parse card (columns 0-22)
            let card = try parseCardFromRaw(row: row)
            let quantity = row[23] as! Int64  // quantity column
            let addedAt = row[24] as! Int64   // added_at column
            results.append((card, Int(quantity), addedAt))
        }
        return results
    }

    /// Get card count in folder
    func getCardCount(inFolder folderId: String) async throws -> Int {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = folderCards.filter(fc_folderId == folderId).count
        return try db.scalar(query)
    }

    /// Check if card is in folder
    func isCardInFolder(cardUuid: String, folderId: String) async throws -> Bool {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = folderCards.filter(fc_folderId == folderId && fc_cardUuid == cardUuid).count
        return try db.scalar(query) > 0
    }

    /// Get quantity of card in folder
    func getQuantity(cardUuid: String, inFolder folderId: String) async throws -> Int? {
        guard let db = db else { throw DatabaseError.notConnected }

        let query = folderCards
            .select(fc_quantity)
            .filter(fc_folderId == folderId && fc_cardUuid == cardUuid)

        guard let row = try db.pluck(query) else { return nil }
        return row[fc_quantity]
    }

    /// Add card to folder (or update quantity)
    func addCardToFolder(cardUuid: String, folderId: String, quantity: Int = 1) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        try db.run(folderCards.insert(or: .replace,
            fc_folderId <- folderId,
            fc_cardUuid <- cardUuid,
            fc_quantity <- quantity,
            fc_addedAt <- now
        ))
    }

    /// Update card quantity in folder
    func updateQuantity(cardUuid: String, inFolder folderId: String, quantity: Int) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let row = folderCards.filter(fc_folderId == folderId && fc_cardUuid == cardUuid)
        try db.run(row.update(fc_quantity <- quantity))
    }

    /// Remove card from folder
    func removeCardFromFolder(cardUuid: String, folderId: String) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        let row = folderCards.filter(fc_folderId == folderId && fc_cardUuid == cardUuid)
        try db.run(row.delete())
    }

    // MARK: - Deck Queries (TODO: Implement similar to above)

    // TODO: Implement deck-related queries when building deck features
    // - getAllDeckFolders()
    // - getDecks(inFolder:)
    // - getDeck(byId:)
    // - saveDeck(_:)
    // - deleteDeck(byId:)
    // - getCardsInDeck(deckId:)
    // - addCardToDeck(cardUuid:deckId:slotType:slotNumber:)
    // - removeCardFromDeck(deckId:slotType:slotNumber:)

    // MARK: - Batch Operations

    /// Insert multiple cards (for database sync)
    func insertCards(_ cards: [Card]) async throws {
        guard let db = db else { throw DatabaseError.notConnected }

        try db.transaction {
            for card in cards {
                try self.insertCard(card)
            }
        }
    }

    /// Insert single card
    private func insertCard(_ card: Card) throws {
        guard let db = db else { throw DatabaseError.notConnected }

        try db.run(cards.insert(or: .replace,
            card_dbUuid <- card.id,
            card_name <- card.name,
            card_cardType <- card.cardType,
            card_rulesText <- card.rulesText,
            card_errataText <- card.errataText,
            card_isBanned <- card.isBanned,
            card_releaseSet <- card.releaseSet,
            card_srgUrl <- card.srgUrl,
            card_srgpcUrl <- card.srgpcUrl,
            card_comments <- card.comments,
            card_tags <- card.tags,
            card_power <- card.power,
            card_agility <- card.agility,
            card_strike <- card.strike,
            card_submission <- card.submission,
            card_grapple <- card.grapple,
            card_technique <- card.technique,
            card_division <- card.division,
            card_gender <- card.gender,
            card_deckCardNumber <- card.deckCardNumber,
            card_atkType <- card.atkType,
            card_playOrder <- card.playOrder,
            card_syncedAt <- card.syncedAt
        ))
    }

    /// Delete all cards (for database replacement during sync)
    func deleteAllCards() async throws {
        guard let db = db else { throw DatabaseError.notConnected }
        try db.run(cards.delete())
    }

    // MARK: - Helper Methods

    /// Parse Card from SQLite row
    private func parseCard(from row: Row) throws -> Card {
        return Card(
            id: row[card_dbUuid],
            name: row[card_name],
            cardType: row[card_cardType],
            rulesText: row[card_rulesText],
            errataText: row[card_errataText],
            isBanned: row[card_isBanned],
            releaseSet: row[card_releaseSet],
            srgUrl: row[card_srgUrl],
            srgpcUrl: row[card_srgpcUrl],
            comments: row[card_comments],
            tags: row[card_tags],
            power: row[card_power],
            agility: row[card_agility],
            strike: row[card_strike],
            submission: row[card_submission],
            grapple: row[card_grapple],
            technique: row[card_technique],
            division: row[card_division],
            gender: row[card_gender],
            deckCardNumber: row[card_deckCardNumber],
            atkType: row[card_atkType],
            playOrder: row[card_playOrder],
            syncedAt: row[card_syncedAt]
        )
    }

    /// Parse Card from raw query result (for JOINs)
    private func parseCardFromRaw(row: [Binding?]) throws -> Card {
        // Column indices match cards table schema
        return Card(
            id: row[0] as! String,
            name: row[1] as! String,
            cardType: row[2] as! String,
            rulesText: row[3] as? String,
            errataText: row[4] as? String,
            isBanned: (row[5] as! Int64) != 0,
            releaseSet: row[6] as? String,
            srgUrl: row[7] as? String,
            srgpcUrl: row[8] as? String,
            comments: row[9] as? String,
            tags: row[10] as? String,
            power: row[11] as? Int64 != nil ? Int(row[11] as! Int64) : nil,
            agility: row[12] as? Int64 != nil ? Int(row[12] as! Int64) : nil,
            strike: row[13] as? Int64 != nil ? Int(row[13] as! Int64) : nil,
            submission: row[14] as? Int64 != nil ? Int(row[14] as! Int64) : nil,
            grapple: row[15] as? Int64 != nil ? Int(row[15] as! Int64) : nil,
            technique: row[16] as? Int64 != nil ? Int(row[16] as! Int64) : nil,
            division: row[17] as? String,
            gender: row[18] as? String,
            deckCardNumber: row[19] as? Int64 != nil ? Int(row[19] as! Int64) : nil,
            atkType: row[20] as? String,
            playOrder: row[21] as? String,
            syncedAt: row[22] as! Int64
        )
    }

    /// Parse Folder from SQLite row
    private func parseFolder(from row: Row) throws -> Folder {
        return Folder(
            id: row[folder_id],
            name: row[folder_name],
            isDefault: row[folder_isDefault],
            displayOrder: row[folder_displayOrder],
            createdAt: row[folder_createdAt]
        )
    }
}

// MARK: - Database Errors

enum DatabaseError: Error, LocalizedError {
    case notConnected
    case bundleDatabaseNotFound
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Database connection not established"
        case .bundleDatabaseNotFound:
            return "Bundled database file not found in app resources"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        }
    }
}
