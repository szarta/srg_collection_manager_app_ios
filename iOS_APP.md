# iOS App Development Plan

## Context
Building an iOS companion app for Get Diced (SRG Supershow card collection manager). Android app is complete and released on Google Play Store. iOS version will achieve feature parity using SwiftUI.

## Repository Strategy

### Recommendation: Separate Repository

**Rationale:**
- Android app uses Kotlin + Jetpack Compose
- iOS app will use Swift + SwiftUI (native approach)
- Different build systems (Gradle vs Xcode)
- Independent release cycles
- Easier CI/CD setup
- Clean separation of concerns

**Shared Components:**
- API contract (same endpoints)
- Data models (translate to Swift)
- Business logic patterns
- UI/UX design (adapt to iOS conventions)

**Repository Name:** `srg_collection_manager_ios` or `get-diced-ios`

---

## Phase 0: Mac Setup & Prerequisites

### Hardware
- ✅ M4 Mac Mini ordered
- ✅ USB converters for keyboard/mouse ordered
- 🖥️ **Setup**: Mac Mini with monitor/keyboard/mouse connected
- 💻 **Development**: Primary development via SSH from Linux laptop/PC

### Development Environment Architecture
```
Linux Dev Machine (Primary)
    ↓ SSH
Mac Mini (Build Server + GUI when needed)
    - Monitor/keyboard/mouse attached
    - Runs Xcode, simulator, GUI tools
    - SSH server enabled
    - Can work directly on Mac or via SSH
```

### Software Setup
1. **macOS Setup**
   - Complete initial macOS setup
   - Create Apple ID (if needed)
   - Enable developer mode: `sudo DevToolsSecurity -enable`
   - Enable SSH: `sudo systemsetup -setremotelogin on`

2. **Xcode Installation**
   - Download Xcode from Mac App Store (free, ~15GB)
   - Install command line tools: `xcode-select --install`
   - Accept license: `sudo xcodebuild -license accept`

3. **Apple Developer Program**
   - ✅ Enrolled at developer.apple.com ($99/year)
   - Required for TestFlight and App Store distribution
   - Processing takes 24-48 hours

4. **Development Tools**
   - Xcode 16+ (includes Swift 6, SwiftUI)
   - SF Symbols app (Apple's icon library)
   - Git (comes with Xcode command line tools)
   - **Homebrew** (required): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
   - **Node.js + npm** (for Claude Code): `brew install node`
   - **Claude Code CLI**: `npm install -g @anthropic-ai/claude-code`

### Remote Development Setup (Linux → Mac)
```bash
# On Mac Mini (first time):
sudo systemsetup -setremotelogin on

# On Linux dev machine:
ssh brandon@mac-mini-ip

# Optional: VS Code Remote SSH for full IDE experience
# Install "Remote - SSH" extension in VS Code
# Connect to Mac Mini for full Swift development environment
```

---

## Phase 1: Project Setup

### 1.1 Create New Repository
```bash
mkdir get-diced-ios
cd get-diced-ios
git init
```

### 1.2 Xcode Project Structure
- Create new iOS App project in Xcode
- Language: Swift
- Interface: SwiftUI
- Bundle ID: `com.srg.getdiced` (matches Android)
- Minimum deployment: iOS 16.0

### 1.3 Directory Structure
```
get-diced-ios/
├── GetDiced/
│   ├── GetDicedApp.swift          # App entry point
│   ├── Models/                     # Data models
│   │   ├── Card.swift
│   │   ├── Folder.swift
│   │   ├── Deck.swift
│   │   └── DeckCard.swift
│   ├── ViewModels/                 # State management
│   │   ├── CollectionViewModel.swift
│   │   └── DeckViewModel.swift
│   ├── Views/                      # UI screens
│   │   ├── ContentView.swift
│   │   ├── CollectionView.swift
│   │   ├── ViewerView.swift
│   │   ├── DecksView.swift
│   │   └── SettingsView.swift
│   ├── Services/                   # API & data layer
│   │   ├── APIClient.swift
│   │   ├── DatabaseService.swift
│   │   └── ImageCache.swift
│   ├── Utils/                      # Helper functions
│   └── Resources/                  # Assets, DB, images
│       ├── Assets.xcassets
│       ├── cards_initial.db
│       └── images/
├── GetDicedTests/
└── GetDiced.xcodeproj
```

### 1.4 Dependencies (Swift Package Manager)
- **Alamofire** - Networking (alternative: native URLSession)
- **SQLite.swift** - Database access
- **Kingfisher** - Image loading/caching
- **SwiftUI** - UI framework (built-in)

---

## Phase 2: Core Features (Feature Parity)

### 2.1 Data Layer
**Goal:** Match Android app's data structure

**Tasks:**
1. **Swift Models**
   - `Card.swift` - All 7 card types with Codable
   - `Folder.swift` - Collection folders
   - `FolderCard.swift` - Junction table
   - `Deck.swift`, `DeckFolder.swift`, `DeckCard.swift`

2. **SQLite Database**
   - Bundle `cards_initial.db` (same as Android)
   - SQLite.swift wrapper
   - Copy bundled DB to Documents on first launch
   - Database version 4 (matches Android)

3. **API Client**
   - `APIClient.swift` - get-diced.com endpoints
   - Match Android's `GetDicedApi.kt` interface
   - Endpoints: manifest, database, shared lists
   - Codable for JSON parsing

### 2.2 UI/UX (SwiftUI)
**Goal:** Native iOS feel with same features

**Screens:**
1. **Tab Navigation** (TabView)
   - Collection
   - Decks
   - Viewer
   - Settings

2. **Collection Tab**
   - Folder list (default + custom)
   - Folder detail with card list
   - Add card with search & filters
   - Edit quantity sheet

3. **Viewer Tab**
   - Card browser with search
   - Type-specific filters
   - Card detail modal

4. **Decks Tab**
   - Deck folders (Singles, Tornado, Trios, Tag)
   - Deck list
   - Deck editor with slot-based UI
   - Card picker with smart filtering

5. **Settings Tab**
   - Database sync
   - Image sync
   - About section

### 2.3 Image Handling
**Strategy:** Same as Android

1. **Bundle Images**
   - Copy mobile-optimized images (158MB)
   - Add to Xcode project resources
   - Path: `Resources/images/mobile/{first2}/{uuid}.webp`

2. **Image Loading**
   - Kingfisher for async loading
   - Priority: Bundle → Cache → Server → Placeholder
   - Lazy loading in lists

---

## Phase 3: iOS-Specific Features

### 3.1 iOS Design Patterns
- **Navigation:** NavigationStack (iOS 16+)
- **Lists:** LazyVStack with ScrollView or List
- **Sheets:** .sheet() for modals
- **Alerts:** .alert() for confirmations
- **Toolbar:** .toolbar() for actions
- **Search:** .searchable() modifier

### 3.2 Data Persistence
- UserDefaults for preferences (last sync time, etc.)
- FileManager for image cache
- SQLite for structured data

### 3.3 iOS Conventions
- Pull-to-refresh for sync
- Swipe actions for delete/edit
- Long press for context menus
- SF Symbols for icons
- Native iOS typography and spacing

---

## Phase 4: Testing & Distribution

### 4.1 Local Testing
- Xcode Simulator (various iPhone/iPad sizes)
- Physical device testing (via cable)
- Debug builds via Xcode

### 4.2 TestFlight (Beta Testing)
1. Archive app in Xcode
2. Upload to App Store Connect
3. Add internal testers (Apple IDs)
4. Send TestFlight invites
5. Collect feedback

### 4.3 App Store Submission
1. **App Store Connect Setup**
   - App name: Get Diced
   - Bundle ID: com.srg.getdiced
   - Privacy policy: https://get-diced.com/privacy
   - Screenshots (iPhone 6.7" and iPad Pro 12.9")
   - App icon (1024x1024)

2. **Store Listing** (reuse Android content)
   - Short description
   - Full description
   - Keywords
   - Category: Entertainment or Games > Card

3. **Content Rating**
   - Same as Android (Everyone/4+)
   - Simulated fantasy violence (wrestling cards)

4. **Review Process**
   - Typically 1-3 days
   - May request demo account or instructions

---

## Technical Decisions

### SwiftUI vs UIKit
**Decision:** SwiftUI
- Modern, declarative (like Jetpack Compose)
- Native animations and transitions
- Better for rapid development
- iOS 16+ deployment target

### Networking
**Decision:** Native URLSession or Alamofire
- URLSession is built-in, no dependencies
- Alamofire if complex features needed
- async/await for modern Swift concurrency

### Database
**Decision:** SQLite.swift
- Matches Android Room approach
- SQL queries similar to Android DAOs
- Bundle same .db file
- Easy migration path

### Image Loading
**Decision:** Kingfisher or native
- Kingfisher: Feature-rich, widely used
- Native AsyncImage: Simple, no dependencies
- Both support WebP on iOS 14+

---

## Timeline Estimate

### Week 1: Setup & Foundation
- Day 1: Mac setup, Xcode install, Apple Developer enrollment
- Day 2-3: Create project, setup dependencies, bundle database
- Day 4-5: Data models and API client

### Week 2: Core UI
- Day 1-2: Tab navigation, Collection tab
- Day 3-4: Viewer tab with search/filters
- Day 5: Settings tab with sync

### Week 3: Deckbuilding
- Day 1-2: Decks tab, folder/list screens
- Day 3-4: Deck editor with slot system
- Day 5: CSV export/import, deck sharing

### Week 4: Polish & Testing
- Day 1-2: Image integration, UI refinements
- Day 3: Bug fixes, performance optimization
- Day 4: TestFlight build
- Day 5: Beta testing feedback

### Week 5: App Store
- Day 1-2: Screenshots, store listing
- Day 3: Submit for review
- Day 4-5: Address review feedback (if any)

**Total: 4-5 weeks** (assuming full-time development)

---

## Key Differences from Android

### Platform Conventions
| Aspect | Android | iOS |
|--------|---------|-----|
| Navigation | Bottom nav + back button | Tab bar + navigation stack |
| Icons | Material Icons | SF Symbols |
| Typography | Roboto/Material | San Francisco |
| Colors | Material 3 Dynamic Color | iOS system colors |
| Gestures | Back button, tap | Swipe back, long press |
| Lists | LazyColumn | List or LazyVStack |

### Code Translation Examples

**Android (Kotlin):**
```kotlin
@Composable
fun FoldersScreen(viewModel: CollectionViewModel) {
    LazyColumn {
        items(folders) { folder ->
            FolderCard(folder)
        }
    }
}
```

**iOS (Swift):**
```swift
struct FoldersView: View {
    @StateObject var viewModel = CollectionViewModel()

    var body: some View {
        List(folders) { folder in
            FolderRow(folder: folder)
        }
    }
}
```

---

## Success Metrics

### Feature Parity Checklist
- [ ] Browse 3,900+ cards with images
- [ ] Collection management (folders)
- [ ] Deck building (all 4 formats)
- [ ] Advanced search with filters
- [ ] Database sync from server
- [ ] Image sync
- [ ] CSV export/import
- [ ] Deck sharing via get-diced.com
- [ ] Offline-first architecture

### Performance Goals
- App launch < 2 seconds
- Smooth 60fps scrolling
- Image loading < 500ms (cached)
- Search results < 100ms
- Database sync < 10 seconds

### App Store Goals
- 4+ star rating
- < 5% crash rate
- < 200MB app size
- iOS 16+ support (covers 90%+ devices)

---

## Risks & Mitigation

### Risk 1: Learning Curve
**Risk:** First iOS app, unfamiliar with Swift/SwiftUI
**Mitigation:**
- Follow Apple's SwiftUI tutorials
- Reference similar open-source apps
- Start with simple screens, iterate

### Risk 2: Large App Size
**Risk:** 158MB of bundled images
**Mitigation:**
- iOS supports on-demand resources
- Consider smaller initial bundle + download
- Use App Thinning (automatic)

### Risk 3: Database Schema
**Risk:** SQLite schema differences between platforms
**Mitigation:**
- Use same .db file as Android
- Test migration thoroughly
- Document schema version 4

### Risk 4: Apple Review
**Risk:** App rejection for unclear reasons
**Mitigation:**
- Clear privacy policy
- Explain card content is licensed
- Provide demo instructions
- Responsive to reviewer questions

---

## Resources

### Apple Documentation
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Swift/SwiftUI Learning
- [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui)
- [SwiftUI by Example](https://www.hackingwithswift.com/quick-start/swiftui)
- [Swift Playgrounds](https://www.apple.com/swift/playgrounds/)

### Similar Apps (Reference)
- Pokémon TCG Card Dex
- MTG Companion
- Yu-Gi-Oh! Neuron

---

## Open Questions

1. **iPad Support?**
   - Universal app or iPhone-only?
   - iPad has larger screen, could show more
   - Recommendation: Universal (minimal extra work with SwiftUI)

2. **Widgets?**
   - Home screen widget showing random card or deck count?
   - Nice-to-have for future version

3. **Watch App?**
   - Probably overkill for card manager
   - Skip for v1.0

4. **Cross-Platform Sync?**
   - Sync collections between iOS and Android?
   - Would require backend user accounts
   - Skip for v1.0, keep local-only

5. **In-App Purchases?**
   - Pro version with extra features?
   - Currently all free, keep it that way

---

## Next Steps

### Immediate (This Week)
1. ✅ Order M4 Mac Mini
2. ✅ Order USB converters
3. 🔜 Mac arrives, complete setup
4. 🔜 Install Xcode
5. 🔜 Enroll in Apple Developer Program

### Week 1 (After Setup)
1. Create new Git repository
2. Initialize Xcode project
3. Set up project structure
4. Add SQLite.swift dependency
5. Bundle cards_initial.db
6. Create basic tab navigation

### Week 2 (Core Development)
1. Implement data models
2. Build API client
3. Create Collection tab
4. Implement search & filters

---

## Notes

- **Android repo:** `/home/brandon/data/srg_collection_manager_app`
- **iOS repo (planned):** `/Users/brandon/dev/get-diced-ios` (or similar)
- **Shared backend:** `https://get-diced.com/api`
- **Asset source:** `~/data/srg_card_search_website/backend/app/images`

---

## Conclusion

Building a separate iOS app in Swift/SwiftUI is the recommended approach. It allows for:
- Native iOS experience
- Independent development cycles
- Clean architecture
- Full access to iOS features

The Android app serves as a complete spec - every feature, API endpoint, and data structure is proven and documented. This significantly reduces risk and development time for iOS.

**Estimated timeline:** 4-5 weeks from Mac setup to App Store submission.
