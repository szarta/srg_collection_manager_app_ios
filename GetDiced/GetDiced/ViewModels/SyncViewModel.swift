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
    @Published var currentDatabaseVersion: Int = 0
    @Published var latestDatabaseVersion: Int?
    @Published var updateAvailable: Bool = false

    // Image sync
    @Published var totalImages: Int = 0
    @Published var downloadedImages: Int = 0

    // MARK: - Dependencies

    private let databaseService: DatabaseService
    private let apiClient: APIClient
    private let imageSyncService = ImageSyncService()

    // MARK: - Initialization

    init(databaseService: DatabaseService, apiClient: APIClient) {
        self.databaseService = databaseService
        self.apiClient = apiClient
        self.loadLastSyncDate()
        self.loadDatabaseVersion()
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
            saveDatabaseVersion()
            syncMessage = "Database updated to v\(manifest.version)! ✅"

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
            syncMessage = ""
        }

        isSyncing = false
    }

    /// Sync images from server using manifest-based approach
    func syncImages() async {
        isSyncing = true
        syncProgress = 0.0
        downloadedImages = 0
        errorMessage = nil
        syncMessage = "Checking for missing images..."

        do {
            // Use the new manifest-based sync
            let (downloaded, total) = try await imageSyncService.syncImages { downloaded, total in
                Task { @MainActor in
                    self.downloadedImages = downloaded
                    self.totalImages = total
                    self.syncProgress = Double(downloaded) / Double(total)
                    self.syncMessage = "Downloading images: \(downloaded)/\(total)"
                }
            }

            if downloaded == 0 {
                syncMessage = "All images up to date! ✅"
            } else {
                syncMessage = "Downloaded \(downloaded) images! ✅"
            }

            lastSyncDate = Date()
            saveLastSyncDate()

        } catch {
            errorMessage = "Image sync failed: \(error.localizedDescription)"
            syncMessage = ""
        }

        isSyncing = false
    }

    /// Get image sync status without downloading
    func checkImageSyncStatus() async {
        do {
            let (needSync, total) = try await imageSyncService.getSyncStatus()
            totalImages = total

            if needSync == 0 {
                syncMessage = "All \(total) images synced ✅"
            } else {
                syncMessage = "\(needSync) of \(total) images need syncing"
            }
        } catch {
            errorMessage = "Failed to check image status: \(error.localizedDescription)"
        }
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
                print("🔄 Starting database merge transaction...")

                // Step 1: Clear existing card data (preserves user data)
                // Use DELETE OR IGNORE to handle cases where tables might be empty
                print("🗑️ Clearing existing card data...")
                do {
                    try userDb.execute("DELETE FROM card_related_finishes")
                    print("✅ Cleared card_related_finishes")
                } catch {
                    print("⚠️ Warning clearing card_related_finishes: \(error)")
                }

                do {
                    try userDb.execute("DELETE FROM card_related_cards")
                    print("✅ Cleared card_related_cards")
                } catch {
                    print("⚠️ Warning clearing card_related_cards: \(error)")
                }

                do {
                    try userDb.execute("DELETE FROM cards")
                    print("✅ Cleared cards")
                } catch {
                    print("⚠️ Warning clearing cards: \(error)")
                }

                // Step 2: ATTACH the temp database and copy data
                print("📎 Attaching temporary database...")
                try userDb.execute("ATTACH DATABASE '\(tempURL.path)' AS temp_db")

                // Copy all cards in one statement
                print("📥 Copying cards from temp database...")
                try userDb.execute("""
                    INSERT INTO cards
                    SELECT * FROM temp_db.cards
                """)

                // Get count of cards inserted
                let count = try userDb.scalar("SELECT COUNT(*) FROM cards") as! Int64
                cardsUpdated = Int(count)
                print("✅ Inserted \(cardsUpdated) cards")

                // Copy related finishes
                print("📥 Copying related finishes...")
                try userDb.execute("""
                    INSERT INTO card_related_finishes
                    SELECT * FROM temp_db.card_related_finishes
                """)
                let finishCount = try userDb.scalar("SELECT COUNT(*) FROM card_related_finishes") as! Int64
                print("✅ Inserted \(finishCount) related finishes")

                // Copy related cards
                print("📥 Copying related cards...")
                try userDb.execute("""
                    INSERT INTO card_related_cards
                    SELECT * FROM temp_db.card_related_cards
                """)
                let relatedCount = try userDb.scalar("SELECT COUNT(*) FROM card_related_cards") as! Int64
                print("✅ Inserted \(relatedCount) related cards")

                syncMessage = "Merged \(cardsUpdated) cards successfully"
                print("✅ Data copy complete!")
            }

            // Detach AFTER transaction completes (outside transaction block)
            // This prevents "database is locked" errors
            print("📌 Detaching temporary database...")
            try userDb.execute("DETACH DATABASE temp_db")
            print("✅ Database detached successfully")

            // Transaction succeeded
            print("✅ Database merge complete: \(cardsUpdated) cards updated")

        } catch let error as NSError {
            // Transaction failed - rollback automatic
            print("❌ Database merge failed: \(error)")
            print("❌ Error domain: \(error.domain), code: \(error.code)")
            print("❌ Error description: \(error.localizedDescription)")
            if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("❌ Underlying error: \(underlying)")
            }
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

    /// Load database version from UserDefaults
    private func loadDatabaseVersion() {
        currentDatabaseVersion = UserDefaults.standard.integer(forKey: "currentDatabaseVersion")
        // If it's 0 (default), we haven't synced yet
    }

    /// Save database version to UserDefaults
    private func saveDatabaseVersion() {
        UserDefaults.standard.set(currentDatabaseVersion, forKey: "currentDatabaseVersion")
    }
}
