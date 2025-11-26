//
//  SyncViewModel.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/26/24.
//

import Foundation
import Combine
import SQLite

@MainActor
class SyncViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var syncMessage: String = ""
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?

    // Manifest info
    @Published var currentDatabaseVersion: Int = 4
    @Published var latestDatabaseVersion: Int?
    @Published var updateAvailable: Bool = false

    // Image sync
    @Published var totalImages: Int = 0
    @Published var downloadedImages: Int = 0

    // MARK: - Dependencies

    private let databaseService: DatabaseService
    private let apiClient: APIClient

    // MARK: - Initialization

    init(databaseService: DatabaseService, apiClient: APIClient) {
        self.databaseService = databaseService
        self.apiClient = apiClient
        self.loadLastSyncDate()
    }

    // MARK: - Sync Operations

    /// Check if database update is available
    func checkForUpdates() async {
        do {
            let manifest = try await apiClient.getCardsManifest()
            latestDatabaseVersion = manifest.version
            updateAvailable = manifest.version > currentDatabaseVersion

            if updateAvailable {
                syncMessage = "Update available: v\(manifest.version) (Current: v\(currentDatabaseVersion))"
            } else {
                syncMessage = "Database is up to date (v\(currentDatabaseVersion))"
            }
        } catch {
            errorMessage = "Failed to check for updates: \(error.localizedDescription)"
        }
    }

    /// Sync database from server
    func syncDatabase() async {
        isSyncing = true
        syncProgress = 0.0
        syncMessage = "Checking for updates..."
        errorMessage = nil

        do {
            // 1. Get manifest
            syncProgress = 0.1
            let manifest = try await apiClient.getCardsManifest()

            // Check if update needed
            if manifest.version <= currentDatabaseVersion {
                syncMessage = "Database is up to date (v\(currentDatabaseVersion))"
                isSyncing = false
                lastSyncDate = Date()
                saveLastSyncDate()
                return
            }

            // 2. Download database
            syncProgress = 0.3
            let sizeMB = manifest.sizeBytes / 1024 / 1024
            syncMessage = "Downloading database (\(sizeMB) MB)..."
            let dbData = try await apiClient.downloadCardsDatabase(filename: manifest.filename)

            // 3. Save to temp file
            syncProgress = 0.7
            syncMessage = "Installing database..."
            let tempURL = try saveTempDatabase(data: dbData)

            // 4. Replace database (preserve user data)
            syncProgress = 0.9
            try await replaceCardsTable(from: tempURL)

            // 5. Update version
            syncProgress = 1.0
            currentDatabaseVersion = manifest.version
            lastSyncDate = Date()
            saveLastSyncDate()
            syncMessage = "Database updated to v\(manifest.version)! ✅"

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
            syncMessage = ""
        }

        isSyncing = false
    }

    /// Sync images from server
    func syncImages() async {
        isSyncing = true
        syncProgress = 0.0
        downloadedImages = 0
        errorMessage = nil
        syncMessage = "Checking for missing images..."

        do {
            // 1. Get all card IDs from database
            let cards = try await databaseService.getAllCards()
            totalImages = cards.count

            syncMessage = "Found \(totalImages) cards in database"

            // 2. Check which images are missing
            var missingCards: [Card] = []
            for card in cards {
                if ImageHelper.imageURL(for: card.id) == nil {
                    missingCards.append(card)
                }
            }

            if missingCards.isEmpty {
                syncMessage = "All images downloaded! ✅"
                lastSyncDate = Date()
                saveLastSyncDate()
                isSyncing = false
                return
            }

            syncMessage = "Downloading \(missingCards.count) missing images..."

            // 3. Download missing images
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagesBaseURL = documentsURL.appendingPathComponent("images/mobile")

            for (index, card) in missingCards.enumerated() {
                let cardId = card.id
                let first2 = String(cardId.prefix(2))
                let imagePath = "\(first2)/\(cardId).webp"

                do {
                    // Download image
                    let imageData = try await apiClient.downloadImage(path: imagePath)

                    // Create directory if needed
                    let dirURL = imagesBaseURL.appendingPathComponent(first2)
                    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)

                    // Save image
                    let fileURL = dirURL.appendingPathComponent("\(cardId).webp")
                    try imageData.write(to: fileURL)

                    downloadedImages = index + 1
                    syncProgress = Double(downloadedImages) / Double(missingCards.count)
                    syncMessage = "Downloaded \(downloadedImages) of \(missingCards.count) images..."

                } catch {
                    print("Failed to download image for \(cardId): \(error)")
                    // Continue with next image
                }
            }

            syncMessage = "Downloaded \(downloadedImages) images! ✅"
            lastSyncDate = Date()
            saveLastSyncDate()

        } catch {
            errorMessage = "Image sync failed: \(error.localizedDescription)"
            syncMessage = ""
        }

        isSyncing = false
    }

    // MARK: - Helper Methods

    /// Save database data to temp file
    private func saveTempDatabase(data: Data) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cards_temp.db")

        try data.write(to: tempURL)
        return tempURL
    }

    /// Replace cards table with new data (preserve user tables)
    /// Follows same strategy as Android app: DELETE + INSERT in transaction
    private func replaceCardsTable(from tempURL: URL) async throws {
        syncMessage = "Merging card data..."

        // Open the temp (downloaded) database
        let tempDb = try Connection(tempURL.path, readonly: true)

        // Get the user database path
        let userDbPath = databaseService.databasePath()
        let userDb = try Connection(userDbPath, readonly: false)

        var cardsUpdated = 0

        do {
            // Begin transaction for atomic operation
            try userDb.transaction {
                // Step 1: Clear existing card data (preserves user data)
                try userDb.run("DELETE FROM card_related_finishes")
                try userDb.run("DELETE FROM card_related_cards")
                try userDb.run("DELETE FROM cards")

                // Step 2: ATTACH the temp database and copy data
                // This is more efficient than iterating row by row
                try userDb.execute("ATTACH DATABASE '\(tempURL.path)' AS temp_db")

                // Copy all cards in one statement
                try userDb.run("""
                    INSERT INTO cards
                    SELECT * FROM temp_db.cards
                """)

                // Get count of cards inserted
                let count = try userDb.scalar("SELECT COUNT(*) FROM cards") as! Int64
                cardsUpdated = Int(count)

                // Copy related finishes
                try userDb.run("""
                    INSERT INTO card_related_finishes
                    SELECT * FROM temp_db.card_related_finishes
                """)

                // Copy related cards
                try userDb.run("""
                    INSERT INTO card_related_cards
                    SELECT * FROM temp_db.card_related_cards
                """)

                // Detach temp database
                try userDb.execute("DETACH DATABASE temp_db")

                syncMessage = "Merged \(cardsUpdated) cards successfully"
            }

            // Transaction succeeded
            print("✅ Database merge complete: \(cardsUpdated) cards updated")

        } catch {
            // Transaction failed - rollback automatic
            syncMessage = "Merge failed: \(error.localizedDescription)"
            throw error
        }
    }

    /// Load last sync date from UserDefaults
    private func loadLastSyncDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = timestamp
        }
    }

    /// Save last sync date to UserDefaults
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "lastSyncDate")
        }
    }
}
