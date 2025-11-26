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

    // MARK: - Dependencies

    let databaseService: DatabaseService

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
}
