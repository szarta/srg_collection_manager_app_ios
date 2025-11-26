# Get Diced iOS - Data Models

This directory contains all Swift data models ported from the Android Kotlin app.

## Model Overview

### Core Card Models

#### `Card.swift`
- **Purpose**: Represents a card from the SRG database
- **Supports**: All 7 card types (MainDeckCard, SingleCompetitorCard, TornadoCompetitorCard, TriosCompetitorCard, TagCompetitorCard, EntranceCard, FinishCard)
- **Fields**: 23 properties with type-specific nullable fields
- **Key Features**:
  - Computed properties: `isCompetitor`, `isMainDeck`, `tagList`
  - Codable for JSON and SQLite
  - Identifiable for SwiftUI Lists

#### `CardRelatedFinish.swift` (in Card.swift)
- Junction table for card finish relationships (foil variants, etc.)
- Composite key: `(card_uuid, finish_uuid)`

#### `CardRelatedCard.swift` (in Card.swift)
- Junction table for related card relationships
- Composite key: `(card_uuid, related_uuid)`

### Collection Models

#### `Folder.swift`
- **Purpose**: Collection folders (Owned, Wanted, Trade, or custom)
- **Key Fields**:
  - `id`: UUID
  - `name`: Folder name
  - `isDefault`: True for system folders (Owned, Wanted, Trade)
  - `displayOrder`: Sort order
  - `createdAt`: Timestamp

#### `FolderCard.swift`
- **Purpose**: Junction table linking folders to cards
- **Composite Key**: `(folder_id, card_uuid)`
- **Key Fields**:
  - `folderId`: Reference to Folder
  - `cardUuid`: Reference to Card
  - `quantity`: Number of cards in this folder
  - `addedAt`: Timestamp
- **Notes**: A card can exist in multiple folders with different quantities

### Deck Models

#### `DeckFolder.swift`
- **Purpose**: Folders for organizing decks by type
- **Default Folders**: Singles, Tornado, Trios, Tag
- **Similar to**: Collection Folder but for decks

#### `Deck.swift`
Contains multiple types:

##### `Deck`
- **Purpose**: A complete deck within a deck folder
- **Key Fields**:
  - `id`: UUID
  - `folderId`: Reference to DeckFolder
  - `name`: Deck name
  - `spectacleType`: Newman or Valiant
  - `createdAt`, `modifiedAt`: Timestamps

##### `DeckCard`
- **Purpose**: Junction table for cards in a deck
- **Composite Key**: `(deck_id, slot_type, slot_number)`
- **Key Fields**:
  - `deckId`: Reference to Deck
  - `cardUuid`: Reference to Card
  - `slotType`: ENTRANCE, COMPETITOR, DECK, FINISH, ALTERNATE
  - `slotNumber`: 0 for singles, 1-30 for deck slots

##### Enums
- `SpectacleType`: `.newman`, `.valiant`
- `DeckSlotType`: `.entrance`, `.competitor`, `.deck`, `.finish`, `.alternate`

##### View Models
- `DeckWithCardCount`: Deck + card count for list display
- `DeckCardWithDetails`: Card + slot info for deck editor

### Legacy Models

#### `UserCard.swift`
- **Status**: Possibly deprecated in favor of Folder/FolderCard system
- **Purpose**: Original user collection tracking
- **Keep**: For reference, may not be used in final iOS app

### API Models

#### `APIModels.swift`
Contains all API request/response models:

##### Response Models
- `PaginatedCardResponse`: Search results with pagination
- `CardDTO`: Card data from API (converts to `Card` model)
- `CardBatchResponse`: Batch card lookup results
- `SharedListResponse`: Shared deck/list data
- `SharedListCreateResponse`: New shared list confirmation
- `CardsManifest`: Database sync manifest
- `ImageManifest`: Image sync manifest

##### Request Models
- `CardBatchRequest`: Request multiple cards by UUID
- `SharedListRequest`: Create a shared list

##### Helper Methods
- `CardDTO.toCard()`: Converts API DTO to local Card model

## Database Mapping

All models use `CodingKeys` to match SQLite column names:

| Swift Property | Database Column | Example |
|----------------|-----------------|---------|
| `id` | `db_uuid` | Card primary key |
| `cardType` | `card_type` | "MainDeckCard" |
| `isDefault` | `is_default` | Boolean flag |
| `folderId` | `folder_id` | Foreign key |

## Usage in iOS

### SwiftUI Integration
All primary models conform to `Identifiable` for use in SwiftUI Lists:

```swift
struct CardListView: View {
    let cards: [Card]

    var body: some View {
        List(cards) { card in
            CardRow(card: card)
        }
    }
}
```

### SQLite.swift Integration
Models use `CodingKeys` that match database schema:

```swift
let card = try db.prepare(cards)
    .filter(Card.CodingKeys.id.rawValue == uuid)
    .first
```

### JSON Decoding
API models use Codable with proper snake_case mapping:

```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .useDefaultKeys  // We handle it with CodingKeys
let manifest = try decoder.decode(CardsManifest.self, from: data)
```

## Key Differences from Android

| Android (Kotlin) | iOS (Swift) | Notes |
|------------------|-------------|-------|
| `@Entity` | `struct` | No Room annotations |
| `@Dao` | Separate service layer | Will be in `Services/` |
| `Flow<T>` | `@Published` or Combine | Reactive updates |
| `data class` | `struct` | Value types by default |
| `Long` timestamp | `Int64` | Milliseconds since epoch |
| `System.currentTimeMillis()` | `Date().timeIntervalSince1970 * 1000` | Same epoch |

## Relationships

```
Card (db_uuid)
  ├─ FolderCard.cardUuid (many-to-many via Folder)
  ├─ DeckCard.cardUuid (many-to-many via Deck)
  ├─ CardRelatedFinish.cardUuid (many-to-many)
  └─ CardRelatedCard.cardUuid (many-to-many)

Folder (id)
  └─ FolderCard.folderId (one-to-many)

DeckFolder (id)
  └─ Deck.folderId (one-to-many)

Deck (id)
  └─ DeckCard.deckId (one-to-many)
```

## Next Steps

When setting up Xcode:

1. **Add to Xcode Project**:
   - Drag `Models/` folder into Xcode
   - Ensure "Copy items if needed" is checked
   - Add to target: GetDiced

2. **Add Dependencies** (via Swift Package Manager):
   - SQLite.swift: https://github.com/stephencelis/SQLite.swift
   - (Optional) Kingfisher for image loading

3. **Create Database Service**:
   - `Services/DatabaseService.swift` will handle SQLite operations
   - Will use these models with SQLite.swift library

4. **Create API Client**:
   - `Services/APIClient.swift` will use URLSession
   - Will decode JSON to API models, convert to local models

## Files Summary

- **Card.swift** (162 lines): Core card model + relationships
- **Folder.swift** (28 lines): Collection folders
- **FolderCard.swift** (40 lines): Folder-card junction
- **DeckFolder.swift** (24 lines): Deck organization folders
- **Deck.swift** (135 lines): Deck models, enums, view models
- **UserCard.swift** (34 lines): Legacy user card model
- **APIModels.swift** (185 lines): All API request/response types

**Total**: 7 files, ~610 lines of Swift code

All models are ready for Xcode integration! 🎉
