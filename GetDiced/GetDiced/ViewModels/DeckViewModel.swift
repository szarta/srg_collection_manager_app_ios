//
//  DeckViewModel.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/26/24.
//

import Foundation
import Combine

@MainActor
class DeckViewModel: ObservableObject {

    // MARK: - Published Properties

    // Deck Folders
    @Published var deckFolders: [DeckFolder] = []
    @Published var selectedFolder: DeckFolder?

    // Decks
    @Published var decks: [DeckWithCardCount] = []
    @Published var selectedDeck: Deck?

    // Deck Cards
    @Published var deckCards: [DeckCardWithDetails] = []
    @Published var entrance: Card?
    @Published var competitor: Card?
    @Published var mainDeckCards: [DeckCardWithDetails] = []  // Slots 1-30
    @Published var finishCards: [DeckCardWithDetails] = []
    @Published var alternateCards: [DeckCardWithDetails] = []

    // UI State
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

    // MARK: - Deck Folder Operations

    /// Load all deck folders
    func loadDeckFolders() async {
        isLoading = true
        errorMessage = nil

        do {
            deckFolders = try await databaseService.getAllDeckFolders()
        } catch {
            errorMessage = "Failed to load deck folders: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Create new custom deck folder
    func createDeckFolder(name: String) async {
        let folder = DeckFolder(name: name, isDefault: false, displayOrder: deckFolders.count)

        do {
            try await databaseService.saveDeckFolder(folder)
            await loadDeckFolders()
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }

    /// Delete deck folder
    func deleteDeckFolder(_ folder: DeckFolder) async {
        guard !folder.isDefault else {
            errorMessage = "Cannot delete default folders"
            return
        }

        do {
            try await databaseService.deleteDeckFolder(byId: folder.id)
            await loadDeckFolders()
        } catch {
            errorMessage = "Failed to delete folder: \(error.localizedDescription)"
        }
    }

    /// Rename deck folder
    func renameDeckFolder(folderId: String, newName: String) async {
        do {
            try await databaseService.updateDeckFolderName(folderId, name: newName)
            await loadDeckFolders()
        } catch {
            errorMessage = "Failed to rename folder: \(error.localizedDescription)"
        }
    }

    // MARK: - Deck Operations

    /// Load decks in selected folder
    func loadDecks(in folderId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            decks = try await databaseService.getDecksWithCardCount(folderId)
        } catch {
            errorMessage = "Failed to load decks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Create new deck
    func createDeck(in folderId: String, name: String, spectacleType: SpectacleType = .valiant) async {
        let deck = Deck(
            folderId: folderId,
            name: name,
            spectacleType: spectacleType
        )

        do {
            try await databaseService.saveDeck(deck)
            await loadDecks(in: folderId)
        } catch {
            errorMessage = "Failed to create deck: \(error.localizedDescription)"
        }
    }

    /// Delete deck
    func deleteDeck(_ deck: Deck) async {
        do {
            try await databaseService.deleteDeck(byId: deck.id)
            await loadDecks(in: deck.folderId)
        } catch {
            errorMessage = "Failed to delete deck: \(error.localizedDescription)"
        }
    }

    /// Update deck spectacle type
    func updateDeckSpectacleType(_ deckId: String, spectacleType: SpectacleType) async {
        do {
            try await databaseService.updateDeckSpectacleType(deckId, spectacleType: spectacleType)
            // Reload the deck to get updated spectacle type
            selectedDeck = try await databaseService.getDeck(byId: deckId)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to update spectacle type: \(error.localizedDescription)"
        }
    }

    /// Rename a deck
    func renameDeck(deckId: String, newName: String) async {
        do {
            try await databaseService.updateDeckName(deckId, name: newName)
            // Reload the deck to get updated name
            selectedDeck = try await databaseService.getDeck(byId: deckId)
            // Reload decks list if we're in a folder
            if let folderId = selectedDeck?.folderId {
                await loadDecks(in: folderId)
            }
        } catch {
            errorMessage = "Failed to rename deck: \(error.localizedDescription)"
        }
    }

    // MARK: - Deck Card Operations

    /// Load cards in selected deck
    func loadDeckCards(_ deckId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            deckCards = try await databaseService.getCardsInDeck(deckId)

            // Organize cards by slot type
            entrance = deckCards.first(where: { $0.slotType == .entrance })?.card
            competitor = deckCards.first(where: { $0.slotType == .competitor })?.card
            mainDeckCards = deckCards.filter { $0.slotType == .deck }.sorted { $0.slotNumber < $1.slotNumber }
            finishCards = deckCards.filter { $0.slotType == .finish }.sorted { $0.slotNumber < $1.slotNumber }
            alternateCards = deckCards.filter { $0.slotType == .alternate }.sorted { $0.slotNumber < $1.slotNumber }
        } catch {
            errorMessage = "Failed to load deck cards: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Set entrance card
    func setEntrance(_ card: Card, in deckId: String) async {
        do {
            try await databaseService.setEntrance(deckId: deckId, cardUuid: card.id)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to set entrance: \(error.localizedDescription)"
        }
    }

    /// Set competitor card
    func setCompetitor(_ card: Card, in deckId: String) async {
        do {
            try await databaseService.setCompetitor(deckId: deckId, cardUuid: card.id)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to set competitor: \(error.localizedDescription)"
        }
    }

    /// Set deck card at slot number (1-30)
    func setDeckCard(_ card: Card, in deckId: String, slotNumber: Int) async {
        do {
            try await databaseService.setDeckCard(deckId: deckId, cardUuid: card.id, slotNumber: slotNumber)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to set deck card: \(error.localizedDescription)"
        }
    }

    /// Add finish card
    func addFinish(_ card: Card, to deckId: String) async {
        do {
            try await databaseService.addFinish(deckId: deckId, cardUuid: card.id)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to add finish: \(error.localizedDescription)"
        }
    }

    /// Add alternate card
    func addAlternate(_ card: Card, to deckId: String) async {
        do {
            try await databaseService.addAlternate(deckId: deckId, cardUuid: card.id)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to add alternate: \(error.localizedDescription)"
        }
    }

    /// Remove card from deck
    func removeCard(from deckId: String, slotType: DeckSlotType, slotNumber: Int) async {
        do {
            try await databaseService.removeCardFromDeck(deckId: deckId, slotType: slotType, slotNumber: slotNumber)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to remove card: \(error.localizedDescription)"
        }
    }

    /// Clear all cards from deck
    func clearDeck(_ deckId: String) async {
        do {
            try await databaseService.clearDeck(deckId)
            await loadDeckCards(deckId)
        } catch {
            errorMessage = "Failed to clear deck: \(error.localizedDescription)"
        }
    }

    // MARK: - Validation

    /// Check if deck is valid for play
    func validateDeck(_ deckId: String) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        // Must have entrance
        if entrance == nil {
            errors.append("Missing Entrance card")
        }

        // Must have competitor
        if competitor == nil {
            errors.append("Missing Competitor card")
        }

        // Must have exactly 30 deck cards
        let deckCardCount = mainDeckCards.count
        if deckCardCount != 30 {
            errors.append("Deck must have exactly 30 cards (currently has \(deckCardCount))")
        }

        // At least one finish card
        if finishCards.isEmpty {
            errors.append("Must have at least one Finish card")
        }

        return (errors.isEmpty, errors)
    }

    /// Get next available slot number for deck cards
    func nextAvailableSlot() -> Int? {
        let occupiedSlots = Set(mainDeckCards.map { $0.slotNumber })
        for slot in 1...30 {
            if !occupiedSlots.contains(slot) {
                return slot
            }
        }
        return nil
    }

    // MARK: - Sharing

    /// Share deck as QR code
    func shareDeckAsQRCode(deckId: String, deckName: String, spectacleType: SpectacleType) async {
        isSharing = true
        errorMessage = nil
        shareUrl = nil

        do {
            // Get all cards in the deck
            let deckCards = try await databaseService.getCardsInDeck(deckId)

            guard !deckCards.isEmpty else {
                errorMessage = "Cannot share an empty deck"
                isSharing = false
                return
            }

            // Build card UUIDs list
            let cardUuids = deckCards.map { $0.card.id }

            // Build deck slots with proper structure
            let slots = deckCards.map { cardWithDetails in
                DeckSlot(
                    slotType: cardWithDetails.slotType.rawValue,
                    slotNumber: cardWithDetails.slotNumber,
                    cardUuid: cardWithDetails.card.id
                )
            }

            // Create deck data
            let deckData = DeckData(
                spectacleType: spectacleType.rawValue,
                slots: slots
            )

            // Call API
            let response = try await apiClient.createSharedList(
                name: deckName,
                description: "Shared from SRG Collection Manager iOS",
                cardUuids: cardUuids,
                listType: "DECK",
                deckData: deckData
            )

            // Build full URL
            let fullUrl = "https://get-diced.com\(response.url)"
            shareUrl = fullUrl

        } catch {
            errorMessage = "Failed to share deck: \(error.localizedDescription)"
        }

        isSharing = false
    }

    /// Clear share URL
    func clearShareUrl() {
        shareUrl = nil
    }

    // MARK: - Importing

    /// Import deck from shared URL
    func importDeckFromSharedList(sharedListId: String, toFolderId folderId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch shared list from API
            let sharedList = try await apiClient.getSharedList(byId: sharedListId)

            guard sharedList.listType == "DECK" else {
                errorMessage = "This is not a deck. Please use collection import."
                isLoading = false
                return
            }

            guard let deckData = sharedList.deckData else {
                errorMessage = "Deck data is missing from shared list"
                isLoading = false
                return
            }

            // Get deck folder to determine deck type
            let deckFolder = try await databaseService.getDeckFolder(byId: folderId)

            // Create new deck
            let deckName = sharedList.name ?? "Imported Deck"
            let spectacleType = SpectacleType(rawValue: deckData.spectacleType) ?? .valiant

            let newDeck = Deck(
                folderId: folderId,
                name: deckName,
                spectacleType: spectacleType
            )

            try await databaseService.saveDeck(newDeck)

            // Import each card slot
            var successCount = 0
            for slot in deckData.slots {
                do {
                    guard let slotType = DeckSlotType(rawValue: slot.slotType) else {
                        continue
                    }

                    switch slotType {
                    case .entrance:
                        try await databaseService.setEntrance(deckId: newDeck.id, cardUuid: slot.cardUuid)
                    case .competitor:
                        try await databaseService.setCompetitor(deckId: newDeck.id, cardUuid: slot.cardUuid)
                    case .deck:
                        try await databaseService.setDeckCard(deckId: newDeck.id, cardUuid: slot.cardUuid, slotNumber: slot.slotNumber)
                    case .finish:
                        try await databaseService.addFinish(deckId: newDeck.id, cardUuid: slot.cardUuid)
                    case .alternate:
                        try await databaseService.addAlternate(deckId: newDeck.id, cardUuid: slot.cardUuid)
                    }
                    successCount += 1
                } catch {
                    // Card not found or invalid slot, continue
                    print("Failed to import card \(slot.cardUuid): \(error)")
                }
            }

            // Reload decks
            await loadDecks(in: folderId)

            print("Imported \"\(deckName)\" with \(successCount) cards")

        } catch {
            errorMessage = "Failed to import deck: \(error.localizedDescription)"
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

    /// Export deck to CSV format
    func exportDeckToCSV(deckId: String, deckName: String) async -> String? {
        do {
            let deckCards = try await databaseService.getCardsInDeck(deckId)
            return CSVHelper.exportDeck(deckName: deckName, cards: deckCards)
        } catch {
            errorMessage = "Failed to export deck: \(error.localizedDescription)"
            return nil
        }
    }

    /// Import deck from CSV data
    func importDeckFromCSV(csvData: String, deckName: String, folderId: String, spectacleType: SpectacleType) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let parsedData = CSVHelper.parseDeckCSV(csvData) else {
                errorMessage = "Invalid CSV format"
                isLoading = false
                return
            }

            // Create new deck
            let newDeck = Deck(
                folderId: folderId,
                name: deckName,
                spectacleType: spectacleType
            )

            try await databaseService.saveDeck(newDeck)

            // Import cards by name
            var successCount = 0
            for (slotTypeString, slotNumber, cardName) in parsedData {
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

                    guard let slotType = DeckSlotType(rawValue: slotTypeString) else {
                        continue
                    }

                    // Add to deck based on slot type
                    switch slotType {
                    case .entrance:
                        try await databaseService.setEntrance(deckId: newDeck.id, cardUuid: card.id)
                    case .competitor:
                        try await databaseService.setCompetitor(deckId: newDeck.id, cardUuid: card.id)
                    case .deck:
                        try await databaseService.setDeckCard(deckId: newDeck.id, cardUuid: card.id, slotNumber: slotNumber)
                    case .finish:
                        try await databaseService.addFinish(deckId: newDeck.id, cardUuid: card.id)
                    case .alternate:
                        try await databaseService.addAlternate(deckId: newDeck.id, cardUuid: card.id)
                    }

                    successCount += 1
                } catch {
                    print("Failed to import card \(cardName): \(error)")
                }
            }

            // Reload decks
            await loadDecks(in: folderId)

            print("Imported \"\(deckName)\" with \(successCount) of \(parsedData.count) cards")

        } catch {
            errorMessage = "Failed to import deck: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
