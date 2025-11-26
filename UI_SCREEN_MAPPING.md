# Get Diced iOS - UI Screen Mapping

Complete mapping of Android screens to iOS SwiftUI implementation.

## Overview

**Android**: 12 main screens using Jetpack Compose
**iOS**: 12 equivalent screens using SwiftUI

## App Structure

### Navigation Pattern

**Android (Bottom Navigation)**:
```
Bottom Nav Bar (4 tabs)
├─ Collection Tab
├─ Viewer Tab
├─ Decks Tab
└─ Settings Tab
```

**iOS (Tab View)**:
```swift
TabView {
    CollectionView()
        .tabItem { Label("Collection", systemImage: "folder") }

    CardSearchView()
        .tabItem { Label("Viewer", systemImage: "rectangle.grid.2x2") }

    DecksView()
        .tabItem { Label("Decks", systemImage: "square.stack.3d.up") }

    SettingsView()
        .tabItem { Label("Settings", systemImage: "gear") }
}
```

---

## Screen-by-Screen Mapping

### 1. Main Screen (App Container)

#### Android: `MainScreen.kt`
- Bottom navigation with 4 tabs
- NavHost for navigation
- Scaffold with bottom bar

#### iOS: `ContentView.swift`
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CollectionView()
            }
            .tabItem {
                Label("Collection", systemImage: "folder")
            }

            NavigationStack {
                CardSearchView()
            }
            .tabItem {
                Label("Viewer", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                DecksView()
            }
            .tabItem {
                Label("Decks", systemImage: "square.stack.3d.up")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}
```

**Key iOS Differences**:
- `NavigationStack` instead of NavHost
- `.tabItem` instead of BottomNavigation
- SF Symbols for icons

---

### 2. Collection Tab

#### 2.1. Folders Screen

**Android**: `FoldersScreen.kt`
- LazyColumn with folder list
- FloatingActionButton to add folder
- Navigate to FolderDetailScreen on tap

**iOS**: `FoldersView.swift`
```swift
struct FoldersView: View {
    @EnvironmentObject var viewModel: CollectionViewModel

    var body: some View {
        List {
            // Default folders section
            Section("Default Folders") {
                ForEach(defaultFolders) { folder in
                    NavigationLink(value: folder) {
                        FolderRow(folder: folder)
                    }
                }
            }

            // Custom folders section
            Section("Custom Folders") {
                ForEach(customFolders) { folder in
                    NavigationLink(value: folder) {
                        FolderRow(folder: folder)
                    }
                }
                .onDelete(perform: deleteFolder)
            }
        }
        .navigationTitle("Collection")
        .navigationDestination(for: Folder.self) { folder in
            FolderDetailView(folder: folder)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddFolder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddFolder) {
            AddFolderSheet()
        }
        .task {
            await viewModel.loadFolders()
        }
    }

    var defaultFolders: [Folder] {
        viewModel.folders.filter { $0.isDefault }
    }

    var customFolders: [Folder] {
        viewModel.folders.filter { !$0.isDefault }
    }
}
```

**Key iOS Patterns**:
- `List` instead of LazyColumn
- `NavigationLink` instead of click navigation
- `.sheet()` instead of Dialog
- `.toolbar()` instead of TopAppBar
- Swipe-to-delete with `.onDelete()`

---

#### 2.2. Folder Detail Screen

**Android**: `FolderDetailScreen.kt`
- LazyColumn with card list
- Show quantity per card
- FAB to add cards
- Long press for edit/delete

**iOS**: `FolderDetailView.swift`
```swift
struct FolderDetailView: View {
    let folder: Folder
    @EnvironmentObject var viewModel: CollectionViewModel
    @State private var showAddCard = false

    var body: some View {
        List {
            ForEach(viewModel.cardsInFolder, id: \.card.id) { item in
                NavigationLink(value: item.card) {
                    CardRowWithQuantity(card: item.card, quantity: item.quantity)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.removeCard(item.card, fromFolder: folder.id)
                        }
                    }

                    Button("Edit") {
                        selectedCard = item.card
                        showEditQuantity = true
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button("Edit Quantity") {
                        selectedCard = item.card
                        showEditQuantity = true
                    }

                    Button("Remove", role: .destructive) {
                        Task {
                            await viewModel.removeCard(item.card, fromFolder: folder.id)
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardToFolderView(folder: folder)
        }
        .sheet(isPresented: $showEditQuantity) {
            if let card = selectedCard {
                EditQuantitySheet(card: card, folder: folder)
            }
        }
        .task {
            await viewModel.selectFolder(folder)
        }
    }
}
```

**Key iOS Patterns**:
- `.swipeActions()` for swipe gestures
- `.contextMenu()` for long press
- Multiple sheets for different modals

---

#### 2.3. Add Card to Folder Screen

**Android**: `AddCardToFolderScreen.kt`
- SearchBar with TextField
- Filter chips (card type, division, etc.)
- LazyColumn with results
- Click to add card

**iOS**: `AddCardToFolderView.swift`
```swift
struct AddCardToFolderView: View {
    let folder: Folder
    @EnvironmentObject var viewModel: CardSearchViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(
                            title: "Type",
                            selection: $viewModel.selectedCardType,
                            options: viewModel.cardTypes
                        )

                        FilterChip(
                            title: "Division",
                            selection: $viewModel.selectedDivision,
                            options: viewModel.divisions
                        )

                        // More filters...
                    }
                    .padding(.horizontal)
                }

                // Results
                List(viewModel.searchResults) { card in
                    CardRow(card: card)
                        .onTapGesture {
                            Task {
                                await addCard(card)
                                dismiss()
                            }
                        }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchQuery)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.search()
            }
        }
    }

    private func addCard(_ card: Card) async {
        // Add to folder via CollectionViewModel
    }
}
```

**Key iOS Patterns**:
- `.searchable()` modifier for search bar
- `.environment(\.dismiss)` for closing sheets
- ScrollView for horizontal filter chips

---

### 3. Viewer Tab (Card Browser)

#### Android: `CardSearchScreen.kt`
- SearchBar + filters
- LazyVerticalGrid (2 columns)
- Card images
- Navigate to card detail

#### iOS: `CardSearchView.swift`
```swift
struct CardSearchView: View {
    @EnvironmentObject var viewModel: CardSearchViewModel

    var body: some View {
        ScrollView {
            // Filter section
            FilterSection(viewModel: viewModel)

            // Results grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.searchResults) { card in
                    NavigationLink(value: card) {
                        CardGridItem(card: card)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Card Viewer")
        .searchable(text: $viewModel.searchQuery)
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
        .task {
            await viewModel.loadFilterOptions()
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            Task {
                await viewModel.search()
            }
        }
    }
}
```

**Key iOS Patterns**:
- `LazyVGrid` instead of LazyVerticalGrid
- `GridItem(.flexible())` for responsive columns
- `.onChange()` for reactive search

---

### 4. Decks Tab

#### 4.1. Deck Folders Screen

**Android**: `DecksScreen.kt`
- List of deck folders (Singles, Tornado, Trios, Tag)
- FAB to add custom folder
- Navigate to DeckListScreen

**iOS**: `DecksView.swift`
```swift
struct DecksView: View {
    @EnvironmentObject var viewModel: DeckViewModel

    var body: some View {
        List {
            Section("Format Folders") {
                ForEach(viewModel.deckFolders.filter { $0.isDefault }) { folder in
                    NavigationLink(value: folder) {
                        DeckFolderRow(folder: folder)
                    }
                }
            }

            Section("Custom Folders") {
                ForEach(viewModel.deckFolders.filter { !$0.isDefault }) { folder in
                    NavigationLink(value: folder) {
                        DeckFolderRow(folder: folder)
                    }
                }
                .onDelete(perform: deleteFolder)
            }
        }
        .navigationTitle("Decks")
        .navigationDestination(for: DeckFolder.self) { folder in
            DeckListView(folder: folder)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddFolder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadDeckFolders()
        }
    }
}
```

---

#### 4.2. Deck List Screen

**Android**: `DeckListScreen.kt`
- LazyColumn with decks
- Show card count
- FAB to create deck
- Navigate to DeckEditorScreen

**iOS**: `DeckListView.swift`
```swift
struct DeckListView: View {
    let folder: DeckFolder
    @EnvironmentObject var viewModel: DeckViewModel

    var body: some View {
        List {
            ForEach(viewModel.decks) { deckWithCount in
                NavigationLink(value: deckWithCount.deck) {
                    DeckRow(
                        deck: deckWithCount.deck,
                        cardCount: deckWithCount.cardCount
                    )
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.deleteDeck(deckWithCount.deck)
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationDestination(for: Deck.self) { deck in
            DeckEditorView(deck: deck)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateDeck = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateDeck) {
            CreateDeckSheet(folder: folder)
        }
        .task {
            await viewModel.loadDecks(inFolder: folder.id)
        }
    }
}
```

---

#### 4.3. Deck Editor Screen

**Android**: `DeckEditorScreen.kt`
- Sections: Entrance, Competitor(s), Deck (1-30), Finishes, Alternates
- Slot-based UI
- Click slot to pick card
- Export/Import buttons

**iOS**: `DeckEditorView.swift`
```swift
struct DeckEditorView: View {
    let deck: Deck
    @EnvironmentObject var viewModel: DeckViewModel

    var body: some View {
        List {
            // Entrance section
            Section("Entrance") {
                SlotView(
                    slotType: .entrance,
                    slotNumber: 0,
                    card: getCard(for: .entrance, slot: 0)
                )
            }

            // Competitor section
            Section("Competitors") {
                ForEach(0..<competitorCount, id: \.self) { index in
                    SlotView(
                        slotType: .competitor,
                        slotNumber: index,
                        card: getCard(for: .competitor, slot: index)
                    )
                }
            }

            // Deck cards section (1-30)
            Section("Deck (30 cards)") {
                ForEach(1...30, id: \.self) { number in
                    SlotView(
                        slotType: .deck,
                        slotNumber: number,
                        card: getCard(for: .deck, slot: number)
                    )
                }
            }

            // Finishes section
            Section("Finishes") {
                ForEach(finishCards) { cardWithDetails in
                    SlotView(
                        slotType: .finish,
                        slotNumber: cardWithDetails.slotNumber,
                        card: cardWithDetails.card
                    )
                }
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Export Deck") {
                        exportDeck()
                    }

                    Button("Import Deck") {
                        showImport = true
                    }

                    Button("Share Deck") {
                        shareDeck()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.selectDeck(deck)
        }
    }

    var competitorCount: Int {
        // Singles: 1, Tornado: 2, Trios: 3, Tag: 4
        switch deck.folderId {
        case "singles": return 1
        case "tornado": return 2
        case "trios": return 3
        case "tag": return 4
        default: return 1
        }
    }
}
```

**Key iOS Patterns**:
- Sectioned List for slot organization
- `Menu` for action overflow
- Share sheet for deck sharing

---

### 5. Settings Tab

#### Android: `SettingsScreen.kt`
- Database sync section
- Image sync section
- About section (version, license)

#### iOS: `SettingsView.swift`
```swift
struct SettingsView: View {
    @EnvironmentObject var syncViewModel: SyncViewModel

    var body: some View {
        Form {
            // Database sync section
            Section {
                Button {
                    Task {
                        await syncViewModel.syncDatabase()
                    }
                } label: {
                    HStack {
                        Text("Sync Database")
                        Spacer()
                        if syncViewModel.isSyncing {
                            ProgressView()
                        }
                    }
                }
                .disabled(syncViewModel.isSyncing)

                if let lastSync = syncViewModel.lastSyncDate {
                    Text("Last sync: \(lastSync, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if syncViewModel.updateAvailable {
                    Text("Update available!")
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Database")
            } footer: {
                Text("Sync card database from get-diced.com. Your collection data will be preserved.")
            }

            // Image sync section
            Section {
                Button("Sync Images") {
                    Task {
                        await syncViewModel.syncImages()
                    }
                }
                .disabled(syncViewModel.isSyncing)
            } header: {
                Text("Images")
            } footer: {
                Text("Download missing card images (may take several minutes).")
            }

            // About section
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Database Version", value: "v\(syncViewModel.currentDatabaseVersion)")
                LabeledContent("Card Count", value: "3,923")

                Link("Privacy Policy", destination: URL(string: "https://get-diced.com/privacy")!)
                Link("SRG Website", destination: URL(string: "https://srgsupershow.com")!)
            }
        }
        .navigationTitle("Settings")
        .task {
            await syncViewModel.checkForUpdates()
        }
    }
}
```

**Key iOS Patterns**:
- `Form` for settings layout
- `LabeledContent` for key-value pairs
- `Link` for external URLs
- Section headers and footers

---

## Component Library

### Reusable Components

#### 1. CardRow
```swift
struct CardRow: View {
    let card: Card

    var body: some View {
        HStack(spacing: 12) {
            // Card image
            AsyncImage(url: imageURL(for: card)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.3))
            }
            .frame(width: 60, height: 84)
            .cornerRadius(4)

            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text(card.cardType)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let set = card.releaseSet {
                    Text(set)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if card.isBanned {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}
```

#### 2. FolderRow
```swift
struct FolderRow: View {
    let folder: Folder
    let cardCount: Int?

    var body: some View {
        HStack {
            Image(systemName: folder.isDefault ? "folder.fill" : "folder")
                .foregroundStyle(folder.isDefault ? .blue : .gray)

            Text(folder.name)

            Spacer()

            if let count = cardCount {
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
```

#### 3. FilterChip
```swift
struct FilterChip: View {
    let title: String
    @Binding var selection: String?
    let options: [String]

    var body: some View {
        Menu {
            Button("All") {
                selection = nil
            }

            Divider()

            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection ?? title)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .cornerRadius(16)
        }
    }
}
```

---

## iOS-Specific Features

### 1. Pull-to-Refresh
```swift
List {
    // content
}
.refreshable {
    await viewModel.refresh()
}
```

### 2. Search
```swift
.searchable(text: $searchQuery)
.searchSuggestions {
    ForEach(suggestions) { suggestion in
        Text(suggestion).searchCompletion(suggestion)
    }
}
```

### 3. Context Menu (Long Press)
```swift
.contextMenu {
    Button("Edit") { /* action */ }
    Button("Delete", role: .destructive) { /* action */ }
}
```

### 4. Swipe Actions
```swift
.swipeActions(edge: .trailing) {
    Button("Delete", role: .destructive) { /* action */ }
}
```

### 5. Sheets (Modals)
```swift
.sheet(isPresented: $showSheet) {
    DetailView()
}
```

---

## Image Loading Strategy

### Using AsyncImage (Built-in)
```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable().aspectRatio(contentMode: .fit)
    case .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
```

### Using Kingfisher (Recommended)
```swift
import Kingfisher

KFImage(imageURL)
    .placeholder {
        ProgressView()
    }
    .retry(maxCount: 3, interval: .seconds(1))
    .fade(duration: 0.25)
    .resizable()
    .aspectRatio(contentMode: .fit)
```

**Image Path Logic**:
```swift
func imageURL(for card: Card) -> URL? {
    // Priority: Bundle → Documents → Server
    let uuid = card.id
    let first2 = String(uuid.prefix(2))
    let path = "images/mobile/\(first2)/\(uuid).webp"

    // 1. Check bundle
    if let bundleURL = Bundle.main.url(forResource: path, withExtension: nil) {
        return bundleURL
    }

    // 2. Check Documents
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let localURL = documentsURL.appendingPathComponent(path)
    if FileManager.default.fileExists(atPath: localURL.path) {
        return localURL
    }

    // 3. Return server URL
    return URL(string: "https://get-diced.com/\(path)")
}
```

---

## Screen Count Summary

| Category | Android | iOS | Status |
|----------|---------|-----|--------|
| Main Container | MainScreen | ContentView | ✅ Mapped |
| Collection Tab | 3 screens | 3 views | ✅ Mapped |
| Viewer Tab | 1 screen | 1 view | ✅ Mapped |
| Decks Tab | 3 screens | 3 views | ✅ Mapped |
| Settings Tab | 1 screen | 1 view | ✅ Mapped |
| **Total** | **8 screens** | **8 views** | ✅ Complete |

**Additional Components**: ~10 reusable components

---

## Implementation Priority

### Phase 1: Core Navigation (Week 1-2)
1. ✅ ContentView with TabView
2. ✅ Empty tab views with navigation

### Phase 2: Collection Tab (Week 2-3)
3. ✅ FoldersView
4. ✅ FolderDetailView
5. ✅ AddCardToFolderView

### Phase 3: Viewer Tab (Week 3)
6. ✅ CardSearchView
7. ✅ CardDetailView

### Phase 4: Decks Tab (Week 3-4)
8. ✅ DecksView
9. ✅ DeckListView
10. ✅ DeckEditorView

### Phase 5: Settings Tab (Week 4)
11. ✅ SettingsView
12. ✅ Sync functionality

### Phase 6: Polish (Week 4-5)
13. ✅ Image loading
14. ✅ Error handling
15. ✅ Loading states
16. ✅ Empty states

---

## Summary

- **Complete 1:1 mapping** from Android to iOS
- **SwiftUI best practices** throughout
- **Native iOS patterns**: SwiftUI, NavigationStack, TabView
- **Reusable components** for consistency
- **Ready for implementation** with code examples

All screens are documented and ready to build! 🎉
