# Get Diced - iOS Card Collection Manager

A native iOS app for managing your SRG (Super Rare Games) card collection and building competitive decks. Built with SwiftUI and SQLite for fast, offline-first performance.

## Features

### Collection Management
- **Card Database**: Browse and search through your entire card collection
- **Smart Search**: Filter by name, set, type, rarity, and more
- **Folder Organization**: Organize cards into custom folders (Binders, Decks, Boxes, etc.)
- **Collection Tracking**: Track quantity and location for every card
- **Quick Add/Remove**: Easily adjust card quantities with intuitive UI

### Card Viewer
- **High-Resolution Images**: View full card artwork and details
- **Complete Card Info**: Name, set, type, rarity, stats, abilities, and flavor text
- **Collection Context**: See quantity and folder information while viewing
- **Add to Collection**: Quick access to add cards while browsing

### Deck Building
- **Deck Management**: Create and organize decks in custom folders (Singles, Tag, Tornado, Trios)
- **Complete Deck Editor**: Build tournament-ready decks with:
  - Entrance card (1)
  - Competitor card (1)
  - Main deck (30 cards, slots 27-30 are finish slots)
  - Alternates (multiple)
- **Deck Validation**: Real-time validation ensures decks meet tournament requirements
- **Quick Card Search**: Search and add cards directly from the deck editor
- **Intuitive Card Management**:
  - Tap any card to view full details
  - Long-press for context menu (Replace/Remove)
  - Swipe-to-delete on Main Deck and Alternates
- **Rename Support**: Rename decks and folders with a single tap

### Data Sync
- **API Integration**: Sync with centralized card database
- **Offline-First**: All data stored locally with SQLite for instant access
- **Sync Progress**: Real-time progress tracking during sync operations
- **Smart Updates**: Only fetch new or updated cards to minimize bandwidth

## Quick Start

### Requirements
- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building the App

1. Clone the repository:
```bash
git clone <repository-url>
cd srg_collection_manager_app_ios
```

2. Open the project in Xcode:
```bash
open GetDiced/GetDiced.xcodeproj
```

3. Install dependencies (SQLite.swift is included via Swift Package Manager)

4. Build and run (⌘R)

### First Launch

On first launch, the app will:
1. Initialize the local SQLite database
2. Create default folders (Binder 1-4, Deck Box, Trade Binder)
3. Create default deck folders (Singles, Tornado, Trios, Tag Team)
4. Be ready to sync data from the API

## App Structure

### Architecture
The app follows MVVM (Model-View-ViewModel) architecture with clear separation of concerns:

```
GetDiced/
├── Models/                    # Data models (Card, Folder, Deck, etc.)
├── Services/                  # Business logic layer
│   ├── DatabaseService.swift  # SQLite operations
│   └── APIClient.swift        # Network operations
├── ViewModels/                # View state management
│   ├── CollectionViewModel.swift
│   ├── CardSearchViewModel.swift
│   ├── SyncViewModel.swift
│   └── DeckViewModel.swift
├── Views/                     # UI components
│   └── ContentView.swift      # Main tab-based UI
└── GetDicedApp.swift          # App entry point
```

### Key Components

#### DatabaseService
- Complete SQLite abstraction layer
- Type-safe queries using SQLite.swift
- Transaction support for atomic operations
- Handles cards, folders, collection items, decks, and deck cards

#### ViewModels
- **CollectionViewModel**: Manages card collection and folder operations
- **CardSearchViewModel**: Handles card search and filtering
- **SyncViewModel**: Controls API sync operations
- **DeckViewModel**: Manages deck building and validation

#### ContentView
- Tab-based navigation (Collection, Viewer, Decks, Sync)
- Reusable UI components (CardRow, FolderRow, DeckRow)
- Modular view architecture for maintainability

## Development Timeline

This app was built in 4 days with the following progression:

- **Day 1**: Project setup, models, database layer, API client
- **Day 2**: Collection tab with folder management and card collection
- **Day 3**: Viewer tab with search and card details
- **Day 4**: Decks tab with complete deck building functionality

Total: **3,567 lines** of production-quality Swift code

## Technical Highlights

### Performance
- Offline-first architecture for instant access
- Efficient SQLite queries with proper indexing
- Lazy loading for large collections
- Image caching for smooth scrolling

### Data Integrity
- Foreign key constraints
- Transaction-based updates
- Type-safe database operations
- Validation at model and UI layers

### User Experience
- Native iOS design patterns
- Intuitive navigation
- Real-time search and filtering
- Clear error messaging
- Progress indicators for long operations

## Documentation

- [PROGRESS.md](PROGRESS.md) - Detailed development history and accomplishments
- [Models README](GetDiced/GetDiced/Models/README.md) - Data model documentation

## Future Enhancements

Potential areas for expansion:
- iCloud sync for cross-device collection access
- Card price tracking and collection valuation
- Trade management and wishlist features
- Deck statistics and analytics
- Export/import deck lists
- Barcode scanning for quick card entry

## License

[Your license here]

## Contact

[Your contact information here]
