# Get Diced iOS - Database Schema Documentation

Complete schema documentation for the SQLite database (`cards_initial.db`).

## Database Overview

- **File**: `cards_initial.db`
- **Size**: 1.4 MB
- **Version**: 4
- **Total Cards**: 3,923 cards
- **Pre-populated**: Yes (bundled with app)
- **Location (iOS)**: Copy from bundle to Documents directory on first launch

## Tables

### 1. `cards` - Card Database (Read-Heavy, Sync from Server)

Main table containing all SRG cards synced from get-diced.com.

```sql
CREATE TABLE cards (
    db_uuid TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    card_type TEXT NOT NULL,
    rules_text TEXT,
    errata_text TEXT,
    is_banned INTEGER NOT NULL,
    release_set TEXT,
    srg_url TEXT,
    srgpc_url TEXT,
    comments TEXT,
    tags TEXT,
    power INTEGER,
    agility INTEGER,
    strike INTEGER,
    submission INTEGER,
    grapple INTEGER,
    technique INTEGER,
    division TEXT,
    gender TEXT,
    deck_card_number INTEGER,
    atk_type TEXT,
    play_order TEXT,
    synced_at INTEGER NOT NULL
);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `db_uuid` | TEXT | NO | Primary key (UUID) |
| `name` | TEXT | NO | Card name (e.g., "John Cena") |
| `card_type` | TEXT | NO | MainDeckCard, SingleCompetitorCard, etc. |
| `rules_text` | TEXT | YES | Card rules/effects |
| `errata_text` | TEXT | YES | Official errata/clarifications |
| `is_banned` | INTEGER | NO | 0 = legal, 1 = banned |
| `release_set` | TEXT | YES | Set name (e.g., "Series 1") |
| `srg_url` | TEXT | YES | Official card page URL |
| `srgpc_url` | TEXT | YES | Card price/info URL |
| `comments` | TEXT | YES | Additional notes |
| `tags` | TEXT | YES | Comma-separated tags |
| `power` | INTEGER | YES | Competitor stat (MainDeck: null) |
| `agility` | INTEGER | YES | Competitor stat (MainDeck: null) |
| `strike` | INTEGER | YES | Competitor stat (MainDeck: null) |
| `submission` | INTEGER | YES | Competitor stat (MainDeck: null) |
| `grapple` | INTEGER | YES | Competitor stat (MainDeck: null) |
| `technique` | INTEGER | YES | Competitor stat (MainDeck: null) |
| `division` | TEXT | YES | Competitor division |
| `gender` | TEXT | YES | For SingleCompetitorCard only |
| `deck_card_number` | INTEGER | YES | MainDeck card number (1-30) |
| `atk_type` | TEXT | YES | Strike, Grapple, Submission |
| `play_order` | TEXT | YES | Lead, Followup, Finish |
| `synced_at` | INTEGER | NO | Timestamp (milliseconds) |

**Card Types:**
1. `MainDeckCard` - Deck cards (1-30)
2. `SingleCompetitorCard` - Singles format competitor
3. `TornadoCompetitorCard` - Tornado format competitor
4. `TriosCompetitorCard` - Trios format competitor
5. `TagCompetitorCard` - Tag format competitor
6. `EntranceCard` - Entrance cards
7. `FinishCard` - Finish cards

**Indices:**
- Primary Key: `db_uuid`
- Recommended: Index on `name` for search
- Recommended: Index on `card_type` for filtering

---

### 2. `folders` - Collection Folders (User Data)

User's collection organization (Owned, Wanted, Trade, custom folders).

```sql
CREATE TABLE folders (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    is_default INTEGER NOT NULL,
    display_order INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `id` | TEXT | NO | Primary key (UUID or predefined: 'owned', 'wanted', 'trade') |
| `name` | TEXT | NO | Folder name |
| `is_default` | INTEGER | NO | 1 = system folder, 0 = custom |
| `display_order` | INTEGER | NO | Sort order |
| `created_at` | INTEGER | NO | Timestamp (milliseconds) |

**Default Folders** (pre-populated):
| ID | Name | is_default | display_order |
|----|------|------------|---------------|
| `'owned'` | Owned | 1 | 0 |
| `'wanted'` | Wanted | 1 | 1 |
| `'trade'` | Trade | 1 | 2 |

**Indices:**
- Primary Key: `id`
- Recommended: Index on `is_default, display_order`

---

### 3. `folder_cards` - Junction Table (User Data)

Many-to-many relationship: A card can be in multiple folders with different quantities.

```sql
CREATE TABLE folder_cards (
    folder_id TEXT NOT NULL,
    card_uuid TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    added_at INTEGER NOT NULL,
    PRIMARY KEY (folder_id, card_uuid),
    FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE,
    FOREIGN KEY (card_uuid) REFERENCES cards(db_uuid) ON DELETE CASCADE
);

CREATE INDEX index_folder_cards_folder_id ON folder_cards(folder_id);
CREATE INDEX index_folder_cards_card_uuid ON folder_cards(card_uuid);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `folder_id` | TEXT | NO | Foreign key → folders.id |
| `card_uuid` | TEXT | NO | Foreign key → cards.db_uuid |
| `quantity` | INTEGER | NO | Number of cards (default: 1) |
| `added_at` | INTEGER | NO | Timestamp (milliseconds) |

**Composite Primary Key**: `(folder_id, card_uuid)`

**Relationships:**
- `CASCADE DELETE`: Deleting a folder removes all its card entries
- `CASCADE DELETE`: Deleting a card removes all folder entries (unlikely in practice)

---

### 4. `deck_folders` - Deck Organization (User Data)

Folders for organizing decks by format.

```sql
CREATE TABLE deck_folders (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    display_order INTEGER NOT NULL DEFAULT 0
);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `id` | TEXT | NO | Primary key (UUID or predefined) |
| `name` | TEXT | NO | Folder name |
| `is_default` | INTEGER | NO | 1 = system folder, 0 = custom |
| `display_order` | INTEGER | NO | Sort order |

**Default Folders** (pre-populated):
| ID | Name | is_default | display_order |
|----|------|------------|---------------|
| `'singles'` | Singles | 1 | 0 |
| `'tornado'` | Tornado | 1 | 1 |
| `'trios'` | Trios | 1 | 2 |
| `'tag'` | Tag | 1 | 3 |

---

### 5. `decks` - User Decks (User Data)

Individual decks within deck folders.

```sql
CREATE TABLE decks (
    id TEXT PRIMARY KEY NOT NULL,
    folder_id TEXT NOT NULL,
    name TEXT NOT NULL,
    spectacle_type TEXT NOT NULL DEFAULT 'VALIANT',
    created_at INTEGER NOT NULL,
    modified_at INTEGER NOT NULL,
    FOREIGN KEY (folder_id) REFERENCES deck_folders(id) ON DELETE CASCADE
);

CREATE INDEX index_decks_folder_id ON decks(folder_id);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `id` | TEXT | NO | Primary key (UUID) |
| `folder_id` | TEXT | NO | Foreign key → deck_folders.id |
| `name` | TEXT | NO | Deck name |
| `spectacle_type` | TEXT | NO | 'NEWMAN' or 'VALIANT' |
| `created_at` | INTEGER | NO | Timestamp (milliseconds) |
| `modified_at` | INTEGER | NO | Timestamp (milliseconds) |

**Spectacle Types:**
- `'NEWMAN'` - Newman Spectacle
- `'VALIANT'` - Valiant Spectacle (default)

---

### 6. `deck_cards` - Deck Card Slots (User Data)

Junction table for cards in a deck with slot information.

```sql
CREATE TABLE deck_cards (
    deck_id TEXT NOT NULL,
    card_uuid TEXT NOT NULL,
    slot_type TEXT NOT NULL,
    slot_number INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (deck_id, slot_type, slot_number),
    FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
);

CREATE INDEX index_deck_cards_deck_id ON deck_cards(deck_id);
CREATE INDEX index_deck_cards_card_uuid ON deck_cards(card_uuid);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `deck_id` | TEXT | NO | Foreign key → decks.id |
| `card_uuid` | TEXT | NO | Reference to cards.db_uuid |
| `slot_type` | TEXT | NO | 'ENTRANCE', 'COMPETITOR', 'DECK', 'FINISH', 'ALTERNATE' |
| `slot_number` | INTEGER | NO | 0 for single slots, 1-30 for deck slots |

**Composite Primary Key**: `(deck_id, slot_type, slot_number)`

**Slot Types:**
| slot_type | slot_number | Description |
|-----------|-------------|-------------|
| `'ENTRANCE'` | 0 | Single entrance card |
| `'COMPETITOR'` | 0, 1, 2, 3 | 1 for Singles, 2 for Tornado, 3 for Trios, 4 for Tag |
| `'DECK'` | 1-30 | Main deck cards (30 cards) |
| `'FINISH'` | 0, 1, 2... | Finish cards (can have multiple) |
| `'ALTERNATE'` | 0, 1, 2... | Alternate cards (can have multiple) |

---

### 7. `card_related_finishes` - Card Relationships (Read-Heavy)

Junction table for foil variants and alternate finishes.

```sql
CREATE TABLE card_related_finishes (
    card_uuid TEXT NOT NULL,
    finish_uuid TEXT NOT NULL,
    PRIMARY KEY (card_uuid, finish_uuid),
    FOREIGN KEY (card_uuid) REFERENCES cards(db_uuid) ON DELETE CASCADE,
    FOREIGN KEY (finish_uuid) REFERENCES cards(db_uuid) ON DELETE CASCADE
);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `card_uuid` | TEXT | NO | Base card UUID |
| `finish_uuid` | TEXT | NO | Finish variant UUID |

**Example**: Standard John Cena → Foil John Cena

---

### 8. `card_related_cards` - Card Relationships (Read-Heavy)

Junction table for related cards (e.g., different versions).

```sql
CREATE TABLE card_related_cards (
    card_uuid TEXT NOT NULL,
    related_uuid TEXT NOT NULL,
    PRIMARY KEY (card_uuid, related_uuid),
    FOREIGN KEY (card_uuid) REFERENCES cards(db_uuid) ON DELETE CASCADE,
    FOREIGN KEY (related_uuid) REFERENCES cards(db_uuid) ON DELETE CASCADE
);
```

**Columns:**
| Column | Type | Null | Description |
|--------|------|------|-------------|
| `card_uuid` | TEXT | NO | Base card UUID |
| `related_uuid` | TEXT | NO | Related card UUID |

---

### 9. `user_cards` - Legacy Table (Deprecated)

**Status**: ⚠️ Kept for migration purposes only. Use `folders` + `folder_cards` instead.

```sql
CREATE TABLE user_cards (
    card_id TEXT PRIMARY KEY NOT NULL,
    card_name TEXT NOT NULL,
    quantity_owned INTEGER NOT NULL,
    quantity_wanted INTEGER NOT NULL,
    is_custom INTEGER NOT NULL,
    added_timestamp INTEGER NOT NULL
);
```

**Note**: This table was used in Version 1 of the Android app. Version 2+ uses the folder system.

---

## Database Initialization (iOS)

### 1. Bundle Database with App
```swift
// Copy from app bundle to Documents directory on first launch
func initializeDatabase() async throws {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let dbURL = documentsURL.appendingPathComponent("user_cards.db")

    // Check if database already exists
    if !fileManager.fileExists(atPath: dbURL.path) {
        // Copy from bundle
        guard let bundleURL = Bundle.main.url(forResource: "cards_initial", withExtension: "db") else {
            throw DatabaseError.bundleDatabaseNotFound
        }
        try fileManager.copyItem(at: bundleURL, to: dbURL)
    }
}
```

### 2. Verify Pre-populated Data
After copying, verify:
- ✅ 3,923 cards in `cards` table
- ✅ 3 default folders in `folders` table (owned, wanted, trade)
- ✅ 4 default deck folders in `deck_folders` table (singles, tornado, trios, tag)
- ✅ 0 user cards in `folder_cards` (user starts with empty collection)
- ✅ 0 decks in `decks` table (user starts with no decks)

---

## Common Query Patterns

### Get All Cards in a Folder (with Quantities)
```sql
SELECT c.*, fc.quantity, fc.added_at
FROM cards c
INNER JOIN folder_cards fc ON c.db_uuid = fc.card_uuid
WHERE fc.folder_id = ?
ORDER BY c.name ASC;
```

### Search Cards with Filters
```sql
SELECT * FROM cards
WHERE (:searchQuery IS NULL OR name LIKE '%' || :searchQuery || '%' COLLATE NOCASE)
  AND (:cardType IS NULL OR card_type = :cardType)
  AND (:atkType IS NULL OR atk_type = :atkType)
  AND (:division IS NULL OR division = :division)
ORDER BY name ASC
LIMIT 100;
```

### Get All Cards in a Deck (Ordered by Slot)
```sql
SELECT c.*, dc.slot_type, dc.slot_number
FROM deck_cards dc
INNER JOIN cards c ON dc.card_uuid = c.db_uuid
WHERE dc.deck_id = ?
ORDER BY
    CASE dc.slot_type
        WHEN 'ENTRANCE' THEN 1
        WHEN 'COMPETITOR' THEN 2
        WHEN 'DECK' THEN 3
        WHEN 'FINISH' THEN 4
        WHEN 'ALTERNATE' THEN 5
    END,
    dc.slot_number ASC;
```

### Get Decks with Card Count
```sql
SELECT d.*, COUNT(dc.card_uuid) as card_count
FROM decks d
LEFT JOIN deck_cards dc ON d.id = dc.deck_id
WHERE d.folder_id = ?
GROUP BY d.id
ORDER BY d.name ASC;
```

---

## Data Types Mapping

### SQLite → Swift
| SQLite Type | Swift Type | Notes |
|-------------|-----------|--------|
| `TEXT` | `String` | |
| `INTEGER` (boolean) | `Bool` | 0 = false, 1 = true |
| `INTEGER` (number) | `Int` or `Int64` | |
| `INTEGER` (timestamp) | `Int64` | Milliseconds since epoch |
| `NULL` | `Optional<T>` | Use Swift optionals |

### iOS Timestamp Conversion
```swift
// Current timestamp (matches Android)
let now = Int64(Date().timeIntervalSince1970 * 1000)

// Convert to Date
let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
```

---

## Database Sync Strategy

### Cards Table
- **Source**: get-diced.com API
- **Sync Method**: Full download via `/api/cards/manifest`
- **Frequency**: Manual (user-initiated) or on app update
- **Strategy**: Download new `cards.db`, replace entire `cards` table
- **Preserve**: User data (`folders`, `folder_cards`, `decks`, `deck_cards`)

### User Tables (No Sync)
Currently, user data is local-only:
- `folders`, `folder_cards`
- `deck_folders`, `decks`, `deck_cards`

**Future Enhancement**: Cloud sync with user accounts (not in v1.0)

---

## SQLite.swift Usage

### Installation
```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.0")
]
```

### Type-Safe Queries Example
```swift
import SQLite

let db = try Connection("\(documentsDirectory)/user_cards.db")

// Define table
let cards = Table("cards")
let id = Expression<String>("db_uuid")
let name = Expression<String>("name")
let cardType = Expression<String>("card_type")

// Query
let query = cards.filter(name.like("%John%"))
for card in try db.prepare(query) {
    print(card[id], card[name])
}
```

---

## Testing Checklist

When implementing DatabaseService:
- [ ] Verify database copies from bundle correctly
- [ ] Test all CRUD operations for each table
- [ ] Verify foreign key cascades work (delete folder → delete folder_cards)
- [ ] Test transaction support for batch operations
- [ ] Verify timestamp handling matches Android (milliseconds)
- [ ] Test search queries with COLLATE NOCASE
- [ ] Verify composite key queries (folder_cards, deck_cards)
- [ ] Test NULL handling for optional fields
- [ ] Verify enum string values match database ('NEWMAN', 'VALIANT', etc.)

---

## Migration Notes (For Future Versions)

If schema changes in future versions:

1. **Check Version**: Query `PRAGMA user_version;`
2. **Run Migrations**: Execute ALTER TABLE or CREATE TABLE statements
3. **Update Version**: `PRAGMA user_version = X;`

**Android Migrations** (for reference):
- Version 1 → 2: Added folders system
- Version 2 → 3: Added deckbuilding system
- Version 3 → 4: Added card relationships (finishes, related cards)

---

## Performance Considerations

### Indices
Already created:
- ✅ `folder_cards`: `folder_id`, `card_uuid`
- ✅ `deck_cards`: `deck_id`, `card_uuid`
- ✅ `decks`: `folder_id`

Consider adding for iOS:
- `cards(name)` - For search performance
- `cards(card_type)` - For filtering

### Query Optimization
- Use `LIMIT` on search queries (default: 100)
- Use `COLLATE NOCASE` for case-insensitive search
- Batch inserts using transactions

---

## Summary

- **9 tables** (6 active + 3 junction tables)
- **3,923 cards** pre-populated
- **Version 4** schema
- **User data**: Folders, collections, decks (local-only)
- **Sync**: Cards table from API, user data stays local
- **Size**: ~1.4 MB bundled, grows with user data

All schema information is ready for DatabaseService implementation! 🎉
