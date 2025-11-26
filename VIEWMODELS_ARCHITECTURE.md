# Get Diced iOS - ViewModels Architecture

SwiftUI state management architecture using `@ObservableObject` and `@Published` properties.

## Overview

ViewModels handle:
- **State management**: UI state and data
- **Business logic**: Data transformations, validations
- **Service coordination**: DatabaseService + APIClient calls
- **Error handling**: User-facing error messages

## Architecture Pattern

```
SwiftUI View
    ↓ observes
ViewModel (@ObservableObject)
    ↓ calls
Services (DatabaseService, APIClient)
    ↓ accesses
Data (SQLite, Network)
```

## Core ViewModels

### 1. CollectionViewModel

**Purpose**: Manages user's card collection (folders + cards)

```swift
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

    private let databaseService: DatabaseService

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
```

---

### 2. CardSearchViewModel

**Purpose**: Manages card search and filtering (Viewer tab)

```swift
@MainActor
class CardSearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var searchQuery: String = ""
    @Published var searchResults: [Card] = []
    @Published var selectedCardType: String?
    @Published var selectedAtkType: String?
    @Published var selectedPlayOrder: String?
    @Published var selectedDivision: String?
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?

    // Filter options
    @Published var cardTypes: [String] = []
    @Published var divisions: [String] = []

    // MARK: - Dependencies

    private let databaseService: DatabaseService

    // MARK: - Initialization

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }

    // MARK: - Search Operations

    /// Load filter options (call once on init)
    func loadFilterOptions() async {
        do {
            cardTypes = try await databaseService.getAllCardTypes()
            divisions = try await databaseService.getAllDivisions()
        } catch {
            errorMessage = "Failed to load filters: \(error.localizedDescription)"
        }
    }

    /// Perform search with current filters
    func search() async {
        isSearching = true
        errorMessage = nil

        do {
            searchResults = try await databaseService.searchCards(
                query: searchQuery.isEmpty ? nil : searchQuery,
                cardType: selectedCardType,
                atkType: selectedAtkType,
                playOrder: selectedPlayOrder,
                division: selectedDivision,
                releaseSet: nil,
                isBanned: nil,
                limit: 100
            )
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isSearching = false
    }

    /// Clear filters
    func clearFilters() {
        searchQuery = ""
        selectedCardType = nil
        selectedAtkType = nil
        selectedPlayOrder = nil
        selectedDivision = nil
        searchResults = []
    }
}
```

---

### 3. DeckViewModel

**Purpose**: Manages deck building

```swift
@MainActor
class DeckViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var deckFolders: [DeckFolder] = []
    @Published var decks: [DeckWithCardCount] = []
    @Published var selectedDeck: Deck?
    @Published var cardsInDeck: [DeckCardWithDetails] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let databaseService: DatabaseService

    // MARK: - Initialization

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }

    // MARK: - Folder Operations

    /// Load all deck folders
    func loadDeckFolders() async {
        // TODO: Implement when deck features are built
        // Similar pattern to CollectionViewModel
    }

    // MARK: - Deck Operations

    /// Load decks in folder
    func loadDecks(inFolder folderId: String) async {
        // TODO: Implement
    }

    /// Create new deck
    func createDeck(name: String, folderId: String, spectacleType: SpectacleType) async {
        // TODO: Implement
    }

    /// Delete deck
    func deleteDeck(_ deck: Deck) async {
        // TODO: Implement
    }

    /// Select deck and load cards
    func selectDeck(_ deck: Deck) async {
        // TODO: Implement
    }

    // MARK: - Card Operations

    /// Add card to deck slot
    func addCard(_ card: Card, toSlot slotType: DeckSlotType, slotNumber: Int) async {
        // TODO: Implement
    }

    /// Remove card from deck slot
    func removeCard(fromSlot slotType: DeckSlotType, slotNumber: Int) async {
        // TODO: Implement
    }

    /// Validate deck (e.g., must have 30 deck cards)
    func validateDeck() -> Bool {
        // TODO: Implement
        return true
    }
}
```

---

### 4. SyncViewModel

**Purpose**: Manages database and image sync from server

```swift
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

    // MARK: - Dependencies

    private let databaseService: DatabaseService
    private let apiClient: APIClient

    // MARK: - Initialization

    init(databaseService: DatabaseService, apiClient: APIClient) {
        self.databaseService = databaseService
        self.apiClient = apiClient
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
                return
            }

            // 2. Download database
            syncProgress = 0.2
            syncMessage = "Downloading database (\(manifest.sizeBytes / 1024 / 1024) MB)..."
            let dbData = try await apiClient.downloadCardsDatabase(filename: manifest.filename)

            // 3. Replace database (preserve user data)
            syncProgress = 0.8
            syncMessage = "Updating database..."
            try await replaceCardsTable(with: dbData)

            // 4. Update version
            syncProgress = 1.0
            currentDatabaseVersion = manifest.version
            lastSyncDate = Date()
            syncMessage = "Database updated to v\(manifest.version)"

        } catch {
            errorMessage = "Sync failed: \(error.localizedDescription)"
        }

        isSyncing = false
    }

    /// Replace cards table with new data (preserve user tables)
    private func replaceCardsTable(with data: Data) async throws {
        // TODO: Implement complex database replacement logic
        // 1. Save data to temp file
        // 2. Open temp database
        // 3. Copy cards table to main database
        // 4. Preserve user tables (folders, folder_cards, decks, deck_cards)
    }

    /// Sync images from server
    func syncImages() async {
        // TODO: Implement image sync
        // 1. Get image manifest
        // 2. Compare with local images
        // 3. Download missing/updated images
        // 4. Store in app's Documents/images/ directory
    }
}
```

---

## ViewModel Dependency Injection

### App-Level Setup

```swift
import SwiftUI

@main
struct GetDicedApp: App {

    // MARK: - Services (Singleton)

    @StateObject private var databaseService: DatabaseService
    @StateObject private var apiClient = APIClient()

    // MARK: - ViewModels (Shared)

    @StateObject private var collectionViewModel: CollectionViewModel
    @StateObject private var searchViewModel: CardSearchViewModel
    @StateObject private var deckViewModel: DeckViewModel
    @StateObject private var syncViewModel: SyncViewModel

    // MARK: - Initialization

    init() {
        // Initialize services
        let dbService = try! DatabaseService()

        // Initialize ViewModels with dependencies
        _databaseService = StateObject(wrappedValue: dbService)
        _collectionViewModel = StateObject(wrappedValue: CollectionViewModel(databaseService: dbService))
        _searchViewModel = StateObject(wrappedValue: CardSearchViewModel(databaseService: dbService))
        _deckViewModel = StateObject(wrappedValue: DeckViewModel(databaseService: dbService))
        _syncViewModel = StateObject(wrappedValue: SyncViewModel(databaseService: dbService, apiClient: APIClient()))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(collectionViewModel)
                .environmentObject(searchViewModel)
                .environmentObject(deckViewModel)
                .environmentObject(syncViewModel)
        }
    }
}
```

### View Usage

```swift
struct CollectionView: View {
    @EnvironmentObject var viewModel: CollectionViewModel

    var body: some View {
        List(viewModel.folders) { folder in
            FolderRow(folder: folder)
                .onTapGesture {
                    Task {
                        await viewModel.selectFolder(folder)
                    }
                }
        }
        .task {
            await viewModel.loadFolders()
        }
    }
}
```

---

## State Management Patterns

### 1. Loading States

```swift
// Show loading indicator
@Published var isLoading: Bool = false

// In view
if viewModel.isLoading {
    ProgressView()
}
```

### 2. Error Handling

```swift
// Error message
@Published var errorMessage: String?

// In view
.alert("Error", isPresented: $showError) {
    Button("OK") { viewModel.errorMessage = nil }
} message: {
    Text(viewModel.errorMessage ?? "Unknown error")
}
```

### 3. Async Operations with Task

```swift
// In SwiftUI view
.task {
    await viewModel.loadData()
}

.onAppear {
    Task {
        await viewModel.loadData()
    }
}

Button("Save") {
    Task {
        await viewModel.save()
    }
}
```

### 4. Debounced Search

```swift
@Published var searchQuery: String = ""
private var searchTask: Task<Void, Never>?

// Watch for changes
init() {
    $searchQuery
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] query in
            self?.searchTask?.cancel()
            self?.searchTask = Task {
                await self?.search()
            }
        }
        .store(in: &cancellables)
}
```

---

## Testing ViewModels

```swift
import XCTest
@testable import GetDiced

@MainActor
class CollectionViewModelTests: XCTestCase {

    var viewModel: CollectionViewModel!
    var mockDatabaseService: MockDatabaseService!

    override func setUp() {
        mockDatabaseService = MockDatabaseService()
        viewModel = CollectionViewModel(databaseService: mockDatabaseService)
    }

    func testLoadFolders() async {
        // Given
        let folders = [
            Folder(id: "1", name: "Owned", isDefault: true),
            Folder(id: "2", name: "Wanted", isDefault: true)
        ]
        mockDatabaseService.foldersToReturn = folders

        // When
        await viewModel.loadFolders()

        // Then
        XCTAssertEqual(viewModel.folders.count, 2)
        XCTAssertEqual(viewModel.folders[0].name, "Owned")
    }
}
```

---

## Key Points

### 1. @MainActor
- All ViewModels marked with `@MainActor`
- Ensures UI updates happen on main thread
- Required for `@Published` properties

### 2. async/await
- Use async functions for database/network operations
- Call with `await` keyword
- Wrap in `Task { }` from SwiftUI views

### 3. Error Handling
- Use `do-catch` blocks
- Store error messages in `@Published` properties
- Show in UI with `.alert()` modifier

### 4. Dependency Injection
- Pass services via initializer
- Use `@EnvironmentObject` for view access
- Single source of truth

### 5. Combine Integration
- Use `$property` syntax for publishers
- Use `.sink()` for observing changes
- Store cancellables in `Set<AnyCancellable>`

---

## Summary

- **4 main ViewModels**: Collection, Search, Deck, Sync
- **Responsibilities**: State + Logic + Service coordination
- **Pattern**: ObservableObject + @Published + async/await
- **Dependency Injection**: Services passed via init
- **Error Handling**: User-facing error messages
- **Testing**: Unit testable with mock services

All ViewModel architecture is ready for implementation! 🎉
