# Feature Comparison: iOS vs Android App

Last Updated: 2025-12-08

This document compares the Get Diced iOS app with the Android app to track feature parity and identify gaps.

---

## Summary Statistics

| Metric | Android | iOS |
|--------|---------|-----|
| Cards in Database | 3,923 | 3,923 |
| Bundled Images | 3,481 (158MB) | 0 (on-demand only) |
| Database Version | v4 | v4 |
| Main Tabs | 5 | 4 |
| Max Card Quantity | 999 | 99 |

---

## Feature Comparison Matrix

### ✅ Core Features (Feature Parity)

| Feature | Android | iOS | Notes |
|---------|---------|-----|-------|
| Collection Folders | ✅ | ✅ | Both support default + custom folders |
| Deck Folders | ✅ | ✅ | Singles, Tornado, Trios, Tag Team |
| Card Search | ✅ | ✅ | Full-text search on names and rules |
| Advanced Filters | ✅ | ✅ | Type, Division, Attack Type, Play Order, Release Set, Banned |
| Deck Editor | ✅ | ✅ | Entrance, Competitor, 30 Main Deck slots |
| Spectacle Type | ✅ | ✅ | Newman/Valiant selection |
| Quantity Tracking | ✅ | ✅ | Track multiple copies per card |
| Database Sync | ✅ | ✅ | Download latest cards from API |
| Image Download | ✅ | ✅ | Download card images |
| Offline-First | ✅ | ✅ | Works without internet connection |
| SQLite Database | ✅ | ✅ | Room (Android) / SQLite.swift (iOS) |
| Card Detail View | ✅ | ✅ | View full card information |
| Alternate Cards | ✅ | ✅ | Multiple alternates per deck |

### 🔴 Missing Features (Android Has, iOS Doesn't)

| Feature | Android | iOS | Priority | Impact |
|---------|---------|-----|----------|--------|
| **QR Code Generation** | ✅ | ❌ | HIGH | Major sharing feature |
| **QR Code Scanning** | ✅ | ❌ | HIGH | Import from QR codes |
| **CSV Export** | ✅ | ❌ | HIGH | Data portability |
| **CSV Import** | ✅ | ❌ | HIGH | Data portability |
| **Share to get-diced.com** | ✅ | ❌ | HIGH | Community sharing |
| **Import from URL** | ✅ | ❌ | HIGH | Import shared decks/collections |
| **Multiple Finish Slots** | ✅ | ❌ | HIGH | Deck building limitation |
| **Search Scope Selector** | ✅ | ❌ | MEDIUM | All Fields, Name Only, Rules Only, Tags Only |
| **Deck Card Number Filter** | ✅ | ❌ | MEDIUM | Filter by specific deck slot (1-30) |
| **Search Within Folder** | ✅ | ❌ | MEDIUM | Search cards in specific folder |
| **Card Sorting** | ✅ | ❌ | MEDIUM | Sort by type or name |
| **Quantity 999 Max** | ✅ | ❌ | LOW | iOS caps at 99 |
| **Bundled Images** | ✅ | ❌ | LOW | Android ships with 3,481 images |
| **Image Manifest Sync** | ✅ | ❌ | LOW | Hash-based image sync |
| **Related Finishes UI** | ✅ | ❌ | LOW | Display finish variants |
| **Related Cards UI** | ✅ | ❌ | LOW | Display related cards |

### 🟢 iOS-Specific Features

| Feature | iOS | Android | Notes |
|---------|-----|---------|-------|
| SwiftUI Native UI | ✅ | ❌ | iOS uses SwiftUI, Android uses Jetpack Compose |
| App Store Ready | ✅ | ❌ | iOS is production-ready |

---

## Detailed Feature Analysis

### 1. QR Code Features (MISSING - HIGH PRIORITY)

**Android Implementation:**
- Generate QR codes for decks and collections
- Scan QR codes using device camera
- QR codes link to get-diced.com shareable URLs
- QRCodeScanScreen with ZXing library
- QRCodeDialog for displaying generated codes
- Handles orientation changes during scanning

**iOS Status:** ❌ Not implemented
- No QR generation capability
- No QR scanning capability
- No camera integration

**Implementation Requirements:**
- AVFoundation for camera access
- CoreImage for QR generation
- Camera permission handling
- QR code scanner view
- QR code display view
- Integration with sharing API

---

### 2. CSV Import/Export (MISSING - HIGH PRIORITY)

**Android Implementation:**
- Export folder contents to CSV format
- Export deck structure to CSV
- Import collections from CSV files
- Import decks from CSV files
- File picker integration
- Format: Card UUID, Card Name, Quantity

**iOS Status:** ❌ Not implemented
- No CSV generation
- No CSV parsing
- No file import/export

**Implementation Requirements:**
- CSV encoding/decoding
- DocumentPicker integration
- File sharing support
- CSV format validation
- Import dialog with folder/deck selection

---

### 3. Deck/Collection Sharing (MISSING - HIGH PRIORITY)

**Android Implementation:**
- POST to /api/shared-lists endpoint
- Returns unique shareable URL
- Generate QR code with URL
- Import from shared URLs
- Import from QR codes
- SharedListRequest/Response models

**iOS Status:** ❌ Not implemented
- No API integration for sharing
- No URL import
- No shareable link generation

**Implementation Requirements:**
- API client endpoints for shared lists
- Share sheet integration
- URL handling for import
- Import dialog with validation
- Success/error handling

---

### 4. Multiple Finish Slots (MISSING - HIGH PRIORITY)

**Android Implementation:**
- DeckSlotType.FINISH with incrementing slot numbers
- Multiple finish cards per deck
- Displayed in dedicated Finish section
- Smart filtering for finish-capable cards

**iOS Status:** ❌ Removed entirely
- Git history shows "remove finishes section" commit
- Only has: Entrance, Competitor, 30 Main Deck, Alternates
- No way to designate finish cards

**Implementation Requirements:**
- Add Finish section back to DeckEditor
- Support multiple finish slots with slot numbers
- Update DeckCard queries to handle FINISH slot type
- Add finish card picker with appropriate filtering
- Update deck validation logic

**Note:** According to git commit a6f51ba "Fix deck editor card filtering and remove finishes section", finishes were intentionally removed. Need to confirm if this was a bug fix or intentional design change.

---

### 5. Search Scope Selector (MISSING - MEDIUM PRIORITY)

**Android Implementation:**
- 4 search modes in searchCardsWithFilters()
  - ALL_FIELDS: Search name, rules, and tags
  - NAME_ONLY: Search card names only
  - RULES_ONLY: Search rules text only
  - TAGS_ONLY: Search tags only
- Dynamic search placeholder updates
- Enum-based implementation

**iOS Status:** ❌ Not implemented
- Only searches names and rules together
- No way to search tags separately
- No search scope UI

**Implementation Requirements:**
- Add SearchScope enum
- Update searchCards() in DatabaseService
- Add segmented control or picker to UI
- Update search placeholder text dynamically
- Modify WHERE clause based on scope

---

### 6. Deck Card Number Filter (MISSING - MEDIUM PRIORITY)

**Android Implementation:**
- Filter dropdown for deck card numbers 1-30
- Only applies to MainDeck cards
- Dynamically shows/hides based on card type filter
- getCardsByTypeAndNumber() in CardDao

**iOS Status:** ❌ Not implemented
- No deck card number filter in CardSearchView
- Filter exists in deck editor for slot-specific selection
- Not available in main viewer

**Implementation Requirements:**
- Add deckCardNumber to CardFilters struct
- Add filter UI (picker or chips)
- Update buildWhereClause() in DatabaseService
- Show/hide based on card type selection

---

### 7. Search Within Folder (MISSING - MEDIUM PRIORITY)

**Android Implementation:**
- Search bar in FolderDetailScreen
- Filters cards within current folder only
- Searches by name, rules, and tags
- Real-time filtering

**iOS Status:** ❌ Not implemented
- Must browse entire folder
- No search/filter in FolderDetailView

**Implementation Requirements:**
- Add search bar to FolderDetailView
- Filter folder cards by search text
- Update CollectionViewModel to support folder search
- Maintain same debouncing as main search

---

### 8. Card Sorting (MISSING - MEDIUM PRIORITY)

**Android Implementation:**
- Sort by card type (groups cards by type)
- Sort by name (alphabetical)
- Sorting in both folder view and search results
- Maintained in CardDao queries with ORDER BY

**iOS Status:** ❌ Not implemented
- Cards display in database order
- No sorting UI controls

**Implementation Requirements:**
- Add SortOption enum (type, name, etc.)
- Add sort picker/menu to views
- Update database queries with ORDER BY
- Persist sort preference

---

### 9. Max Quantity Limit (INCONSISTENT - LOW PRIORITY)

**Android Implementation:**
- Max quantity: 999
- Quantity control with +/- buttons
- No keyboard input required

**iOS Status:** ⚠️ Limited to 99
- Stepper control with 1-99 range
- Keyboard input for quantity

**Implementation Requirements:**
- Update quantity validation from 99 to 999
- Update UI to handle 3-digit display
- Update database constraints if any

---

### 10. Bundled Images (MISSING - LOW PRIORITY)

**Android Implementation:**
- 3,481 images bundled (158MB)
- WebP format for mobile optimization
- Organized by UUID first 2 characters
- Immediate offline availability
- Assets bundled in APK

**iOS Status:** ❌ No bundled images
- All images downloaded on-demand
- Stored in app's Documents/images/ directory
- Requires internet for initial image load

**Implementation Requirements:**
- Download WebP images for 3,481 cards
- Convert to iOS-compatible format (WebP or compressed PNG/JPEG)
- Add to Xcode project as bundled resources
- Update ImageHelper to check bundle first, then Documents
- Significant app size increase (~158MB)

**Trade-offs:**
- Pro: Faster initial experience, works offline immediately
- Con: Large app download size, App Store concerns

---

### 11. Hash-Based Image Manifest (MISSING - LOW PRIORITY)

**Android Implementation:**
- GET /api/images/manifest endpoint
- JSON manifest with image hashes
- Compare hashes to determine which images to download
- Efficient sync (only download changed images)
- ImageManifest model with hash tracking

**iOS Status:** ❌ Simple download approach
- Downloads images on-demand by UUID
- No manifest checking
- No hash comparison
- Re-downloads if file missing

**Implementation Requirements:**
- Add ImageManifest model
- Implement manifest download/parsing
- Store manifest locally
- Compare hashes before downloading
- Update SyncViewModel with manifest logic

---

### 12. Card Relationships (PARTIALLY IMPLEMENTED - LOW PRIORITY)

**Android Implementation:**
- card_related_finishes table (finish variants)
- card_related_cards table (related cards)
- CardRelatedFinish and CardRelatedCard entities
- UI to display related finishes and cards
- Synced during database updates

**iOS Status:** ⚠️ Database only, no UI
- Tables exist in database schema
- Synced from API during database updates
- No UI to display relationships
- No queries to fetch related cards

**Implementation Requirements:**
- Add queries to fetch related finishes/cards
- Add UI section to card detail view
- Display related finish variants
- Display related cards with links
- Handle navigation to related cards

---

### 13. Enhanced Card Detail View (PARTIALLY IMPLEMENTED)

**Android Implementation:**
- Full card image
- All stats displayed clearly
- Clickable SRG and SRGPC URLs
- Comprehensive stat display for competitors
- Clean Material 3 UI
- Errata text prominently shown

**iOS Status:** ⚠️ Basic implementation
- Card image displayed
- Some stats shown
- URLs may not be clickable
- UI could be enhanced

**Implementation Requirements:**
- Verify all card properties are displayed
- Make URLs clickable (Link or openURL)
- Enhance layout with better stat organization
- Add errata text prominence
- Match Android's comprehensive display

---

## Navigation Differences

### Android (5 Tabs)
1. Lists (Collection folders)
2. Decks (Deck folders and builder)
3. Viewer (Card browser with search)
4. Scan (QR code scanning)
5. Settings (Sync, images, info)

### iOS (4 Tabs)
1. Collection (Folders and cards)
2. Viewer (Card browser with search)
3. Decks (Deck folders and builder)
4. Settings (Sync, images, info)

**Difference:** iOS combines functionality into fewer tabs, Android has dedicated QR scan tab (which iOS doesn't have at all).

---

## API Endpoints Used

### Android APIs
- GET /cards - Card search
- GET /cards/{uuid} - Get card by UUID
- POST /cards/by-uuids - Batch card lookup
- POST /api/shared-lists - Create shareable list
- GET /api/shared-lists/{id} - Fetch shared list
- DELETE /api/shared-lists/{id} - Delete shared list
- GET /api/images/manifest - Image sync manifest
- GET /api/cards/manifest - Database sync manifest
- GET /api/cards/database - Download card database

### iOS APIs (Currently Used)
- GET /api/cards/manifest - Database sync manifest ✅
- GET /api/cards/database - Download card database ✅
- Individual image downloads by UUID ✅

### iOS APIs (Need to Add)
- POST /api/shared-lists - For deck/collection sharing
- GET /api/shared-lists/{id} - For importing shared lists
- GET /api/images/manifest - For hash-based image sync

---

## Architecture Comparison

| Aspect | Android | iOS |
|--------|---------|-----|
| UI Framework | Jetpack Compose | SwiftUI |
| Database | Room | SQLite.swift |
| Network | Retrofit + OkHttp | URLSession |
| Image Loading | Coil | AsyncImage |
| Async | Coroutines + Flow | async/await + Combine |
| Architecture | MVVM | MVVM |
| Navigation | Compose Navigation | NavigationStack |

---

## Priority Implementation Roadmap

### Phase 1: Critical Features (Must-Have)
1. Multiple Finish Slots - Required for correct deck building
2. QR Code Generation - Core sharing feature
3. QR Code Scanning - Core import feature
4. CSV Export - Data portability
5. CSV Import - Data portability
6. Share to get-diced.com - Community feature
7. Import from URL - Community feature

### Phase 2: Enhanced UX (Should-Have)
8. Search Scope Selector - Improved search precision
9. Deck Card Number Filter - Enhanced filtering
10. Search Within Folder - Better collection management
11. Card Sorting - Improved browsing

### Phase 3: Polish (Nice-to-Have)
12. Increase max quantity to 999
13. Bundled images (evaluate size impact)
14. Hash-based image manifest
15. Card relationships UI
16. Enhanced card detail view

---

## Testing Considerations

When implementing missing features, test:
- Cross-platform compatibility (QR codes, CSV formats)
- Import/export round-trip (export from Android, import to iOS)
- Share URL format compatibility
- Database migration safety
- Performance with large datasets
- Offline functionality
- Error handling and user feedback

---

## Notes

- Both apps share the same database schema (v4) which is good for consistency
- iOS was built in 4 days and is production-ready for core features
- Android has been developed longer and has more polish/features
- Focus should be on sharing features (QR, CSV, URLs) for parity
- Finish slots removal in iOS needs investigation - was it intentional?

---

## Git History References

iOS Recent Commits:
- a6f51ba - "Fix deck editor card filtering and remove finishes section"
- 5d9f16f - "Fix spectacle type persistence and add deck card filtering"
- a5fb8dc - "Move spectacle type selection to deck editor"
- 2cbf157 - "Streamline add card flow to single step"
- 64e1837 - "Fix blank card detail on first tap in search results"

The "remove finishes section" commit suggests finishes were causing issues and were removed. This needs to be re-evaluated as Android has multiple finish slots as a core feature.
