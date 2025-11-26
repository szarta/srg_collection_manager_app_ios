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

    // MARK: - Dependencies

    let databaseService: DatabaseService

    // MARK: - Initialization

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
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

    // MARK: - Card Operations

    /// Load cards in selected folder
    private func loadCardsInFolder(_ folderId: String) async {
        isLoading = true

        do {
            let results = try await databaseService.getCardsInFolder(folderId: folderId)
            cardsInFolder = results.map { ($0.card, $0.quantity) }
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
}
