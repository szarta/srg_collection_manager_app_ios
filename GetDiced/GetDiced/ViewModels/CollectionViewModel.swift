//
//  CollectionViewModel.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/25/25.
//

import Foundation
import Combine

@MainActor
class CollectionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var folders: [Folder] = []
    @Published var selectedFolder: Folder?
    @Published var cardsInFolder: [(card: Card, quantity: Int)] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSharing: Bool = false
    @Published var shareUrl: String?

    // MARK: - Dependencies

    let databaseService: DatabaseService
    private let apiClient = APIClient()

    // MARK: - Initialization

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }

    // MARK: - Sorting

    /// Sort cards by type order (matching Android logic)
    private func sortCardsByType(cards: [(card: Card, quantity: Int)]) -> [(card: Card, quantity: Int)] {
        let typeOrder: [String: Int] = [
            "EntranceCard": 1,
            "SingleCompetitorCard": 2,
            "TornadoCompetitorCard": 3,
            "TrioCompetitorCard": 4,
            "MainDeckCard": 5,
            "SpectacleCard": 6,
            "CrowdMeterCard": 7
        ]

        return cards.sorted { first, second in
            let card1 = first.card
            let card2 = second.card

            // Primary: sort by card type order
            let order1 = typeOrder[card1.cardType] ?? 99
            let order2 = typeOrder[card2.cardType] ?? 99
            if order1 != order2 {
                return order1 < order2
            }

            // Secondary: for MainDeckCard, sort by deck card number
            if card1.cardType == "MainDeckCard" {
                let num1 = card1.deckCardNumber ?? Int.max
                let num2 = card2.deckCardNumber ?? Int.max
                if num1 != num2 {
                    return num1 < num2
                }
            }

            // Tertiary: for SpectacleCard, Valiant before Newman
            if card1.cardType == "SpectacleCard" {
                let isValiant1 = card1.name.lowercased().contains("valiant")
                let isValiant2 = card2.name.lowercased().contains("valiant")
                if isValiant1 != isValiant2 {
                    return isValiant1
                }
            }

            // Final: alphabetical by name
            return card1.name.lowercased() < card2.name.lowercased()
        }
    }

    // MARK: - Folder Operations

    /// Load all folders
    func loadFolders() async {
        isLoading = true
        errorMessage = nil

        do {
            folders = try await databaseService.getAllFolders()
        } catch {
            errorMessage = "Failed to load folders: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Select folder and load its cards
    func selectFolder(_ folder: Folder) async {
        selectedFolder = folder
        await loadCardsInFolder(folder.id)
    }

    /// Create new custom folder
    func createFolder(name: String) async {
        let folder = Folder(name: name, isDefault: false, displayOrder: folders.count)

        do {
            try await databaseService.saveFolder(folder)
            await loadFolders()
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }

    /// Delete folder
    func deleteFolder(_ folder: Folder) async {
        guard !folder.isDefault else {
            errorMessage = "Cannot delete default folders"
            return
        }

        do {
            try await databaseService.deleteFolder(byId: folder.id)
            await loadFolders()
        } catch {
            errorMessage = "Failed to delete folder: \(error.localizedDescription)"
        }
    }

    func renameFolder(folderId: String, newName: String) async {
        do {
            try await databaseService.updateFolderName(folderId, name: newName)
            await loadFolders()
        } catch {
            errorMessage = "Failed to rename folder: \(error.localizedDescription)"
        }
    }

    // MARK: - Card Operations

    /// Load cards in selected folder
    private func loadCardsInFolder(_ folderId: String) async {
        isLoading = true

        do {
            let results = try await databaseService.getCardsInFolder(folderId: folderId)
            let unsorted = results.map { ($0.card, $0.quantity) }
            cardsInFolder = sortCardsByType(cards: unsorted)
        } catch {
            errorMessage = "Failed to load cards: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Add card to folder
    func addCard(_ card: Card, toFolder folderId: String, quantity: Int = 1) async {
        do {
            try await databaseService.addCardToFolder(
                cardUuid: card.id,
                folderId: folderId,
                quantity: quantity
            )

            // Refresh if current folder
            if selectedFolder?.id == folderId {
                await loadCardsInFolder(folderId)
            }
        } catch {
            errorMessage = "Failed to add card: \(error.localizedDescription)"
        }
    }

    /// Update card quantity
    func updateQuantity(card: Card, inFolder folderId: String, newQuantity: Int) async {
        do {
            try await databaseService.updateQuantity(
                cardUuid: card.id,
                inFolder: folderId,
                quantity: newQuantity
            )
            await loadCardsInFolder(folderId)
        } catch {
            errorMessage = "Failed to update quantity: \(error.localizedDescription)"
        }
    }

    /// Remove card from folder
    func removeCard(_ card: Card, fromFolder folderId: String) async {
        do {
            try await databaseService.removeCardFromFolder(
                cardUuid: card.id,
                folderId: folderId
            )
            await loadCardsInFolder(folderId)
        } catch {
            errorMessage = "Failed to remove card: \(error.localizedDescription)"
        }
    }

    // MARK: - Sharing

    /// Share folder as QR code
    func shareFolderAsQRCode(folderId: String, folderName: String) async {
        isSharing = true
        errorMessage = nil
        shareUrl = nil

        do {
            // Get all cards in the folder
            let cardsInFolder = try await databaseService.getCardsInFolder(folderId: folderId)

            guard !cardsInFolder.isEmpty else {
                errorMessage = "Cannot share an empty folder"
                isSharing = false
                return
            }

            // Extract card UUIDs
            let cardUuids = cardsInFolder.map { $0.card.id }

            // Call API
            let response = try await apiClient.createSharedList(
                name: folderName,
                description: "Shared from SRG Collection Manager iOS",
                cardUuids: cardUuids,
                listType: "COLLECTION",
                deckData: nil
            )

            // Build full URL
            let fullUrl = "https://get-diced.com\(response.url)"
            shareUrl = fullUrl

        } catch {
            errorMessage = "Failed to share folder: \(error.localizedDescription)"
        }

        isSharing = false
    }

    /// Clear share URL
    func clearShareUrl() {
        shareUrl = nil
    }

    // MARK: - Importing

    /// Import collection from shared URL
    func importCollectionFromSharedList(sharedListId: String, toFolderId folderId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch shared list from API
            let sharedList = try await apiClient.getSharedList(byId: sharedListId)

            guard sharedList.listType == "COLLECTION" else {
                errorMessage = "This is not a collection. Please use deck import."
                isLoading = false
                return
            }

            // Import each card with quantity 1
            var successCount = 0
            for cardUuid in sharedList.cardUuids {
                do {
                    // Check if card exists in database
                    if let _ = try await databaseService.getCard(byId: cardUuid) {
                        try await databaseService.addCardToFolder(
                            cardUuid: cardUuid,
                            folderId: folderId,
                            quantity: 1
                        )
                        successCount += 1
                    }
                } catch {
                    // Card not found, continue
                    print("Failed to import card \(cardUuid): \(error)")
                }
            }

            // Reload folder
            await loadCardsInFolder(folderId)

            let collectionName = sharedList.name ?? "Imported Collection"
            print("Imported \"\(collectionName)\" with \(successCount) cards to folder")

        } catch {
            errorMessage = "Failed to import collection: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Extract shared list ID from URL
    func extractSharedListId(from url: String) -> String? {
        // Check if it's already just the UUID
        if url.contains("http") || url.contains("get-diced.com") {
            // Parse query parameter: https://get-diced.com/shared?shared={id}
            if let components = URLComponents(string: url),
               let sharedParam = components.queryItems?.first(where: { $0.name == "shared" })?.value {
                return sharedParam
            }
            return nil
        } else {
            // Assume it's already the UUID
            return url
        }
    }

    // MARK: - CSV Export/Import

    /// Export collection to CSV format
    func exportCollectionToCSV(folderId: String, folderName: String) async -> String? {
        do {
            let cardsInFolder = try await databaseService.getCardsInFolder(folderId: folderId)
            let cardsWithQuantity = cardsInFolder.map { (card: $0.card, quantity: $0.quantity) }
            return CSVHelper.exportCollection(folderName: folderName, cards: cardsWithQuantity)
        } catch {
            errorMessage = "Failed to export collection: \(error.localizedDescription)"
            return nil
        }
    }

    /// Import collection from CSV data
    func importCollectionFromCSV(csvData: String, folderId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let parsedData = CSVHelper.parseCollectionCSV(csvData) else {
                errorMessage = "Invalid CSV format"
                isLoading = false
                return
            }

            // Import cards by name
            var successCount = 0
            for (cardName, quantity) in parsedData {
                do {
                    // Find card by name
                    let cards = try await databaseService.searchCards(
                        query: cardName,
                        searchScope: "name",
                        cardType: nil,
                        atkType: nil,
                        playOrder: nil,
                        division: nil,
                        releaseSet: nil,
                        isBanned: nil,
                        deckCardNumber: nil,
                        limit: 10
                    )

                    // Find exact match
                    guard let card = cards.first(where: { $0.name == cardName }) else {
                        print("Card not found: \(cardName)")
                        continue
                    }

                    // Add to folder
                    try await databaseService.addCardToFolder(
                        cardUuid: card.id,
                        folderId: folderId,
                        quantity: quantity
                    )

                    successCount += 1
                } catch {
                    print("Failed to import card \(cardName): \(error)")
                }
            }

            // Reload folder
            await loadCardsInFolder(folderId)

            print("Imported \(successCount) of \(parsedData.count) cards to folder")

        } catch {
            errorMessage = "Failed to import collection: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
