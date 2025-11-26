# Pre-Mac Arrival Checklist

Complete these tasks **before your Mac and adapters arrive** to maximize productivity on Day 1.

---

## 🚨 CRITICAL - Do Immediately

### ✅ 1. Apple Developer Program Enrollment

**Status**: ⏳ **START THIS NOW!**

- **URL**: https://developer.apple.com/programs/enroll/
- **Cost**: $99/year
- **Processing Time**: 24-48 hours (can take up to 5 days)
- **Required For**: TestFlight, App Store, code signing

**Steps**:
1. Visit developer.apple.com
2. Sign in with Apple ID (create one if needed)
3. Complete enrollment form
4. Pay $99 fee
5. Wait for approval email

**Why Critical**: Without this, you can't:
- Test on physical devices beyond 7 days
- Use TestFlight for beta testing
- Submit to App Store
- Access App Store Connect

---

## ✅ 2. Prework Documentation (COMPLETE!)

- ✅ All Swift models created (7 files, ~610 lines)
- ✅ Database schema documented
- ✅ API client specified
- ✅ UI screens mapped (Android → iOS)
- ✅ ViewModels architecture defined
- ✅ Kotlin-to-Swift translation guide
- ✅ Complete development plan

**Estimated Time Saved**: 10-15 hours

---

## 📦 3. Asset Preparation

### App Icon (Required)

**Location on Linux**: `~/data/srg_collection_manager_app_ios/Assets/`

**Create**: `app_icon_1024.png`
- **Size**: 1024×1024 pixels
- **Format**: PNG (no transparency/alpha channel)
- **Content**: Get Diced branding
- **Design**: Simple, recognizable at small sizes

**Tools** (if needed):
```bash
# Install GIMP on Linux if needed
sudo apt install gimp

# Or use online tools:
# - Figma (free, web-based)
# - Canva (free tier)
# - Adobe Express (free)
```

**Reference**: Check Android app icon:
```bash
ls ~/data/srg_collection_manager_app/app/src/main/res/mipmap-*/ic_launcher.png
```

### Launch Screen (Optional for v1.0)

iOS apps show a launch screen briefly on startup. Can use:
- Simple logo centered on background
- Or delay until after first Xcode project is created

---

## 🗂️ 4. Assets Ready for Transfer

### ✅ Database File
```bash
Location: ~/data/srg_collection_manager_app/app/src/main/assets/cards_initial.db
Size: 1.4 MB
Status: ✅ Ready
```

### ✅ Card Images
```bash
Location: ~/data/srg_card_search_website/backend/app/images/mobile/
Size: 166 MB
Status: ✅ Ready
Structure: mobile/{first2}/{uuid}.webp
```

### Transfer Plan (When Mac Arrives)

**Recommended: SSH/SCP (Network Transfer)**
```bash
# On Mac Mini (first time):
sudo systemsetup -setremotelogin on

# From Linux, transfer via SCP:
scp ~/data/srg_collection_manager_app/app/src/main/assets/cards_initial.db \
    brandon@mac-mini-ip:~/dev/get-diced-ios/GetDiced/Resources/

scp -r ~/data/srg_card_search_website/backend/app/images/mobile \
    brandon@mac-mini-ip:~/dev/get-diced-ios/GetDiced/Resources/images/
```

**Alternative: Direct copy on Mac (if files on shared drive/USB)**
```bash
# On Mac Mini directly:
cp /path/to/cards_initial.db ~/dev/get-diced-ios/GetDiced/Resources/
cp -r /path/to/mobile ~/dev/get-diced-ios/GetDiced/Resources/images/
```

**Note**: You'll have Mac Mini connected with monitor/keyboard/mouse, so direct copying or SSH both work well.

---

## 📚 5. Learning Resources (Optional but Recommended)

### SwiftUI Fundamentals

**Apple's Official Tutorials** (Free):
- https://developer.apple.com/tutorials/swiftui
- Start with "SwiftUI Essentials" (2-3 hours)
- Learn: Views, State, Lists, Navigation

**100 Days of SwiftUI** (Free):
- https://www.hackingwithswift.com/100/swiftui
- Do Days 1-15 (basics + SwiftUI intro)
- ~30 minutes per day

**YouTube Channels**:
- Paul Hudson (Hacking with Swift)
- Sean Allen (iOS Dev)
- CodeWithChris

### Focus Areas
1. **SwiftUI basics**: Views, modifiers, state
2. **Lists and navigation**: List, NavigationStack, NavigationLink
3. **State management**: @State, @Published, @ObservableObject
4. **Data flow**: @Binding, @EnvironmentObject
5. **Async/await**: Task, async functions

**Time Commitment**: 5-10 hours (spread over multiple days)

---

## 🎨 6. Design Review

### Apple Human Interface Guidelines
- Read: https://developer.apple.com/design/human-interface-guidelines/
- Focus on:
  - Navigation patterns
  - Tab bars vs navigation
  - SF Symbols (icon library)
  - iOS typography
  - Spacing and layout

### SF Symbols (Icon Library)
- Browse: https://developer.apple.com/sf-symbols/
- Free, vector icons for iOS
- Integrated with Xcode
- Identify icons you'll use:
  - `folder` - Collections
  - `rectangle.grid.2x2` - Viewer
  - `square.stack.3d.up` - Decks
  - `gear` - Settings
  - `plus` - Add actions
  - `magnifyingglass` - Search

---

## 📱 7. Plan App Store Listing (Optional)

Can reuse Android content, but adapt for iOS audience.

### Screenshots Needed (Later)
- iPhone 6.7" (iPhone 15 Pro Max)
- iPad Pro 12.9" (if supporting iPad)
- 2-5 screenshots showing key features

### Description (Reuse from Android)
```
Short Description (30 chars):
"SRG Supershow card collection"

Full Description:
[Copy from Google Play Store, adapt as needed]
```

### Keywords (100 chars max)
```
wrestling, cards, collection, deck builder, SRG, supershow
```

### Privacy Policy
- Already exists: https://get-diced.com/privacy
- Verify it covers iOS app usage

---

## 💾 8. Backup Current Work

Before Mac arrives, ensure all work is backed up:

```bash
cd ~/data/srg_collection_manager_app_ios

# Initialize git if not already done
git init
git add .
git commit -m "Pre-Mac prework: models, docs, architecture"

# Push to GitHub (recommended)
# Create repo at: https://github.com/new
git remote add origin https://github.com/yourusername/get-diced-ios.git
git push -u origin main
```

**Why**: Easy to clone on Mac, version control, backup

---

## 🧪 9. Review Android App

Familiarize yourself with the final Android app:

**Test on Android device/emulator**:
- Navigate through all screens
- Test all features
- Note any quirks or edge cases
- Take screenshots for reference

**Study the codebase**:
```bash
cd ~/data/srg_collection_manager_app
# Review key files mentioned in your docs
```

---

## 📝 10. Create Quick Reference Cheat Sheet

Create a personal cheat sheet (optional but helpful):

**Kotlin → Swift Quick Reference**:
```swift
// Kotlin                    → // Swift
data class Foo              → struct Foo
val x: String               → let x: String
var x: String               → var x: String
List<T>                     → [T]
Map<K,V>                    → [K: V]
suspend fun                 → async func
viewModelScope.launch       → Task { }
Flow<T>                     → AsyncStream<T> or @Published
```

**Common SwiftUI Patterns**:
```swift
@State          - View-local state
@Binding        - Two-way binding
@ObservedObject - External observable object
@Published      - Property that publishes changes
.task { }       - Run async code on appear
.sheet          - Present modal
.alert          - Show alert
```

---

## ✅ Final Checklist Before Mac Arrives

### Critical
- [ ] Apple Developer Program enrollment submitted
- [ ] App icon created (1024×1024 PNG)

### Important
- [ ] All documentation reviewed
- [ ] Assets location verified (database + images)
- [ ] Transfer method planned (USB/network/cloud)
- [ ] Git repository initialized and pushed

### Recommended
- [ ] SwiftUI basics learned (Apple tutorials or 100 Days)
- [ ] SF Symbols browsed for icons
- [ ] iOS HIG reviewed
- [ ] Android app tested and understood

### Optional
- [ ] App Store listing drafted
- [ ] Privacy policy reviewed
- [ ] Quick reference cheat sheet created
- [ ] Learning resources bookmarked

---

## 🚀 Day 1 Plan (When Mac Arrives)

### Morning (2-3 hours) - On Mac Mini Directly
1. ✅ Unbox Mac, connect monitor/keyboard/mouse
2. ✅ Complete macOS setup wizard
3. ✅ Enable SSH: `sudo systemsetup -setremotelogin on`
4. ✅ Note IP address (System Settings → Network)
5. ✅ Install Xcode from Mac App Store (~15 GB, 30-60 min download)
6. ✅ Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
7. ✅ Install tools: `brew install node && npm install -g @anthropic-ai/claude-code`
8. ✅ Run `xcode-select --install` for command line tools
9. ✅ Accept Xcode license: `sudo xcodebuild -license accept`

### Afternoon (3-4 hours) - Can work via SSH from Linux or directly on Mac
10. ✅ Create new Xcode project (on Mac)
    - iOS App
    - Language: Swift
    - Interface: SwiftUI
    - Bundle ID: `com.srg.getdiced`
    - Minimum deployment: iOS 16.0

11. ✅ Transfer files from Linux (via SSH/SCP or git clone)
    - Git clone repository OR SCP files
    - Drag Swift files into Xcode

12. ✅ Add dependencies (Swift Package Manager)
    - SQLite.swift: https://github.com/stephencelis/SQLite.swift
    - (Optional) Kingfisher: https://github.com/onevcat/Kingfisher

13. ✅ Copy assets
    - `cards_initial.db` → Resources
    - `images/mobile/` → Resources/images
    - App icon → Assets.xcassets

14. ✅ Build project (Cmd+B)
    - Fix any import issues
    - Verify models compile

15. ✅ Run on simulator (Cmd+R)
    - Should see empty app with tab bar

### Evening - Test Remote Development Setup
16. ✅ From Linux, test SSH connection
17. ✅ Test VS Code Remote SSH (optional but recommended)
18. ✅ Verify Claude Code works via SSH

**Celebrate!** 🎉 You now have:
- Mac Mini ready for iOS development
- Can code from Linux via SSH
- Can use Mac directly when GUI needed
- Best of both worlds!

---

## 📊 Progress Tracking

**Current Status**: ~40% complete (prework phase)

**What's Done**:
- ✅ All data models (7 files, 610 lines)
- ✅ Complete documentation (75+ KB)
- ✅ Architecture defined
- ✅ Database schema documented
- ✅ UI screens mapped
- ✅ ViewModels planned

**What's Next** (After Mac arrives):
- [ ] Xcode project setup (1 day)
- [ ] Implement ViewModels (2 days)
- [ ] Build UI screens (7 days)
- [ ] Integration & testing (5 days)
- [ ] Polish & TestFlight (3 days)
- [ ] App Store submission (3 days)

**Total Timeline**: 4-5 weeks from Mac arrival to App Store

---

## 🆘 Troubleshooting

### If Apple Developer enrollment is delayed:
- You can still develop and test on simulator
- Physical device testing limited to 7 days per install
- TestFlight and App Store require approval

### If app icon creation is challenging:
- Use a simple colored square with "GD" text for now
- Can update later before App Store submission
- Focus on functionality first

### SSH Connection Issues:
```bash
# On Mac, verify SSH is enabled:
sudo systemsetup -getremotelogin

# Should show: Remote Login: On

# Get Mac's IP address:
ifconfig | grep "inet "
```

### If Claude Code or npm not found after installing:
```bash
# Add Homebrew to PATH:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

---

## 📞 Support Resources

### Apple Documentation
- SwiftUI: https://developer.apple.com/documentation/swiftui
- Swift: https://docs.swift.org/swift-book/
- Xcode: https://developer.apple.com/documentation/xcode

### Communities
- r/iOSProgramming
- r/swift
- Swift Forums: https://forums.swift.org
- Stack Overflow: [swift] [swiftui] tags

### Your Documentation
- All specs in this repository
- Reference Android app codebase
- Kotlin-to-Swift guide

---

## 🎯 Success Criteria

You're ready for Mac arrival when:
1. ✅ Apple Developer enrollment is submitted (or approved)
2. ✅ App icon is created
3. ✅ All documentation reviewed
4. ✅ Transfer plan is clear
5. ✅ Basic SwiftUI concepts understood (optional but helpful)

**Current Status**: 4/5 complete (just need enrollment + icon)

---

## 🎉 You're in Great Shape!

Your prework is **exceptional**. Most developers start iOS projects with zero planning. You have:

- Complete architecture
- All data models
- Database schema
- API client specs
- UI screens mapped
- ViewModels defined
- Translation guide
- Development plan

**Estimated time saved**: 10-15 hours

When your Mac arrives, you'll be able to start building immediately rather than spending days on planning and architecture.

---

**Last Updated**: November 24, 2024
**Next Milestone**: Mac + adapters arrival → Xcode setup
