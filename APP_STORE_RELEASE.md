# App Store Release Checklist - Get Diced v1.0.0

**Status**: Pre-release preparation
**Version**: 1.0.0 (Build 1)
**Target**: iOS 16.0+
**Bundle ID**: com.srg.GetDiced

---

## Prerequisites

### Apple Developer Account
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] Enrolled at [developer.apple.com](https://developer.apple.com)
- [ ] Access to App Store Connect
- [ ] Two-factor authentication enabled

### Development Environment
- [x] Xcode 15.0+ installed
- [x] Valid development certificate
- [ ] Valid distribution certificate
- [ ] App Store provisioning profile created

---

## 1. App Preparation

### Code & Build
- [x] App builds without errors or warnings
- [x] Version set to 1.0.0
- [x] Build number set to 1
- [x] Bundle identifier correct: `com.srg.GetDiced`
- [ ] Remove all TODO/FIXME comments
- [ ] Remove all debug print statements (or wrap in DEBUG flag)
- [ ] Test on physical device (not just simulator)
- [ ] Test on multiple iOS versions (16.0, 17.0, 18.0)
- [ ] Test on different screen sizes (iPhone SE, iPhone 15, iPhone 15 Pro Max, iPad)
- [ ] Fix any crashes or major bugs
- [ ] Performance testing (memory leaks, smooth scrolling)

### Features Testing
- [ ] Collection tab: Add/remove cards, create folders, edit quantities
- [ ] Viewer tab: Search, filter, view card details
- [ ] Decks tab: Create deck folders, build decks, validate decks
- [ ] Sync tab: Initial sync, incremental sync, error handling
- [ ] Test offline functionality
- [ ] Test with empty database
- [ ] Test with full collection (3,923 cards synced)
- [ ] Test data persistence after app restart

### Privacy & Security
- [ ] Review all network requests (only to trusted API)
- [ ] No hardcoded secrets or API keys
- [ ] User data stored locally (privacy-friendly)
- [ ] No tracking or analytics (unless disclosed)
- [ ] No third-party SDKs that collect data

---

## 2. Assets & Metadata

### App Icons
- [ ] App icon 1024x1024 (required for App Store)
- [ ] All required icon sizes generated
- [ ] Icon follows Apple Human Interface Guidelines
- [ ] No alpha channel in icon
- [ ] No rounded corners (iOS adds them automatically)

**Icon Sizes Needed**:
- 1024x1024 (App Store)
- 180x180 (iPhone @3x)
- 120x120 (iPhone @2x)
- 167x167 (iPad Pro @2x)
- 152x152 (iPad @2x)
- 76x76 (iPad)

### Screenshots
Required screenshots for App Store listing:

**iPhone 6.7" Display** (iPhone 15 Pro Max) - Required:
- [ ] Screenshot 1: Collection tab with cards
- [ ] Screenshot 2: Card viewer with details
- [ ] Screenshot 3: Deck builder interface
- [ ] Screenshot 4: Sync progress
- [ ] Screenshot 5: (Optional) Additional feature

**iPhone 6.5" Display** (iPhone 15 Plus) - Required:
- [ ] Same 3-5 screenshots as above

**iPad Pro 12.9" Display** - Required if supporting iPad:
- [ ] Same 3-5 screenshots optimized for iPad

**Guidelines**:
- No status bar with personal info
- No notch or home indicator
- Clean, professional presentation
- Show key features
- High quality (no blur or pixelation)

### App Preview Video (Optional but Recommended)
- [ ] 15-30 second video showing app in action
- [ ] Portrait orientation
- [ ] Shows main features (Collection, Viewer, Decks)
- [ ] No audio or appropriate background music

---

## 3. App Store Connect Setup

### App Information
- [ ] Create new app in App Store Connect
- [ ] App name: "Get Diced" (or preferred name)
- [ ] Subtitle: (50 chars max) e.g., "SRG Card Collection Manager"
- [ ] Bundle ID: com.srg.GetDiced
- [ ] SKU: Unique identifier (e.g., "getdiced-ios-001")
- [ ] Primary language: English (U.S.)

### Category
- [ ] Primary category: **Games** → Card
  - Alternative: **Utilities** → Reference
- [ ] Secondary category: (Optional) **Entertainment**

### Pricing & Availability
- [ ] Price: **Free** (recommended for v1.0)
- [ ] Availability: All countries (or select specific regions)
- [ ] Pre-order: No (not needed for v1.0)

### Age Rating
Complete questionnaire for age rating:
- [ ] No objectionable content
- [ ] No violence
- [ ] No gambling or contests
- [ ] No unrestricted web access
- [ ] Likely rating: **4+** (All Ages)

---

## 4. App Metadata

### Description
Write compelling App Store description (4000 char max):

**Suggested Structure**:
```
[One-line hook - what problem it solves]

[3-5 key features with bullets]
• Manage your complete card collection
• Build tournament-ready decks
• Search and filter thousands of cards
• Offline-first for instant access

[Additional details about features]

[Technical highlights - offline, sync, etc.]

[Call to action]
```

- [ ] Write full description
- [ ] Include keywords naturally
- [ ] Proofread for typos
- [ ] No promotional language ("Best app ever!")
- [ ] No competitor mentions

### Keywords
100 characters max, comma-separated:

**Suggested Keywords**:
```
SRG,trading card,collection,deck builder,card game,TCG,wrestler,super rare games,deck manager
```

- [ ] Choose relevant keywords
- [ ] No spaces after commas
- [ ] Total ≤ 100 characters
- [ ] No app name repetition
- [ ] Research popular search terms

### Promotional Text (Optional)
170 characters max, editable without new version:
- [ ] Write promotional text (can be updated anytime)

### Support URL
- [ ] Provide website or support page URL
- [ ] Could use: GitHub issues page or simple webpage

### Marketing URL (Optional)
- [ ] Landing page for the app (if available)

### Copyright
- [ ] Copyright year and owner: "2024 [Your Name/Company]"

---

## 5. Privacy & Compliance

### Privacy Policy
- [ ] Create privacy policy page
- [ ] Host at accessible URL
- [ ] Include in App Store Connect
- [ ] Cover:
  - What data is collected (local only)
  - How data is used
  - No third-party sharing
  - User rights

**If no data leaves device**: Simple privacy policy stating "all data stored locally, no collection, no sharing"

### App Privacy Details
Answer questionnaire in App Store Connect:

- [ ] **Data Collection**:
  - Likely "No" to most questions if fully local
  - "Yes" if syncing with API (network requests)

- [ ] **Data Types**:
  - If syncing: "User Content" (card collection data)
  - Purpose: App Functionality
  - Linked to User: No
  - Used for Tracking: No

- [ ] **Third-Party SDKs**:
  - SQLite.swift: No data collection
  - No analytics, ads, or tracking

### Export Compliance
- [ ] Answer encryption questions
- [ ] If using HTTPS only: Select "No" (standard encryption)
- [ ] No special encryption beyond standard iOS/HTTPS

---

## 6. Build & Upload

### Archive Build
1. [ ] Select "Any iOS Device (arm64)" as build destination
2. [ ] Clean build folder (Product → Clean Build Folder)
3. [ ] Archive app (Product → Archive)
4. [ ] Wait for archive to complete

### Validate Archive
1. [ ] Open Organizer (Window → Organizer)
2. [ ] Select archive
3. [ ] Click "Validate App"
4. [ ] Choose distribution method: App Store Connect
5. [ ] Select distribution options:
   - [ ] Include bitcode: No (deprecated)
   - [ ] Upload symbols: Yes (for crash reports)
   - [ ] Manage Version and Build Number: Automatically
6. [ ] Sign with App Store distribution certificate
7. [ ] Complete validation (should pass with no errors)

### Upload to App Store Connect
1. [ ] Click "Distribute App" in Organizer
2. [ ] Choose "App Store Connect"
3. [ ] Same settings as validation
4. [ ] Upload (may take 5-30 minutes)
5. [ ] Confirm build appears in App Store Connect

### Build Processing
- [ ] Wait for build to process (10-60 minutes)
- [ ] Check for email from Apple about processing complete
- [ ] Verify build shows "Ready to Submit" status

---

## 7. TestFlight (Recommended Before Release)

### Internal Testing
- [ ] Add internal testers in App Store Connect
- [ ] Distribute build to internal testers
- [ ] Gather feedback (1-3 days)
- [ ] Fix critical bugs if found

### External Testing (Optional)
- [ ] Create external test group
- [ ] Add beta testers via email or public link
- [ ] Provide test instructions
- [ ] Collect feedback (1-2 weeks recommended)
- [ ] Iterate on feedback

**Benefits**:
- Real device testing
- Crash reports
- User feedback before public release
- Builds confidence in stability

---

## 8. Pre-Submission Checklist

### Final Testing
- [ ] Test on actual device (not simulator)
- [ ] Complete user flow from onboarding to deck building
- [ ] Test all tabs and features
- [ ] Test error states (no network, empty data, etc.)
- [ ] Verify no crashes
- [ ] Check loading states and performance
- [ ] Verify images load correctly (copy_images.sh)

### Review Guidelines Compliance
Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/):

- [ ] **2.1** App completeness: Fully functional
- [ ] **2.3** Accurate metadata: Description matches functionality
- [ ] **4.0** Design: Follows iOS design patterns
- [ ] **4.2** Minimum functionality: Not just a website wrapper
- [ ] **5.1** Privacy: Complies with privacy requirements

### Common Rejection Reasons to Avoid
- [ ] Crashes on launch
- [ ] Incomplete functionality
- [ ] Broken links or features
- [ ] Missing privacy policy
- [ ] Inaccurate screenshots
- [ ] Poor performance
- [ ] Placeholder content

---

## 9. Submit for Review

### In App Store Connect
1. [ ] Go to app page
2. [ ] Select version 1.0.0
3. [ ] Add uploaded build
4. [ ] Complete all required fields:
   - [ ] Screenshots
   - [ ] Description
   - [ ] Keywords
   - [ ] Support URL
   - [ ] Privacy policy URL
5. [ ] Review all information
6. [ ] Click "Submit for Review"

### Review Notes (Optional but Helpful)
Provide notes to Apple reviewers:

```
Get Diced is a card collection manager for the Super Rare Games trading card game.

To test:
1. Tap Sync tab and sync card database (requires internet)
2. Browse cards in Viewer tab
3. Add cards to collection in Collection tab
4. Build decks in Decks tab

The app is fully functional offline after initial sync.
All data is stored locally using SQLite.

Test account: Not required (no login)
```

- [ ] Write review notes
- [ ] Include testing instructions
- [ ] Mention any special requirements

---

## 10. Review Process

### Timeline
- **Waiting for Review**: 1-3 days (typically)
- **In Review**: Few hours to 1 day
- **Total**: Usually 24-48 hours, up to 7 days possible

### During Review
- [ ] Monitor App Store Connect for status updates
- [ ] Check email for messages from Apple
- [ ] Be ready to respond to questions within 48 hours

### Possible Outcomes

**✅ Approved ("Ready for Sale")**
- [ ] Celebrate!
- [ ] App goes live automatically (or on scheduled date)
- [ ] Share with users
- [ ] Monitor crash reports and reviews

**❌ Rejected**
- [ ] Read rejection reason carefully
- [ ] Fix issues mentioned
- [ ] Update build if code changes needed
- [ ] Resubmit with explanation of fixes

**❓ Metadata Rejected**
- [ ] Fix metadata issues (screenshots, description, etc.)
- [ ] No new build needed
- [ ] Resubmit for review

---

## 11. Post-Release

### Launch Day
- [ ] Verify app is live in App Store
- [ ] Test download and installation
- [ ] Share app link with users
- [ ] Monitor for any critical issues

### Monitoring
- [ ] Check App Store Connect daily for:
  - Crash reports
  - User reviews
  - Download stats
- [ ] Set up email notifications
- [ ] Monitor user feedback

### User Support
- [ ] Respond to reviews (especially negative ones)
- [ ] Fix critical bugs quickly
- [ ] Plan updates based on feedback
- [ ] Build update roadmap

### Marketing (Optional)
- [ ] Share on social media
- [ ] Email to beta testers
- [ ] Post on relevant forums/communities
- [ ] Create landing page
- [ ] Write blog post about launch

---

## 12. Future Updates

### Version 1.1 Planning
Based on user feedback, consider:
- [ ] iCloud sync for cross-device collections
- [ ] Card price tracking
- [ ] Trade management
- [ ] Deck statistics
- [ ] Export/import features
- [ ] Barcode scanning

### Update Process
1. [ ] Fix bugs from user reports
2. [ ] Implement new features
3. [ ] Increment version (1.0.0 → 1.1.0)
4. [ ] Test thoroughly
5. [ ] Submit update via same process

---

## Critical Assets Needed Before Submission

### Must Have:
1. **App Icon** (1024x1024 PNG, no transparency)
2. **Screenshots** (minimum 3 for each required device size)
3. **Privacy Policy** (URL accessible via web)
4. **App Description** (compelling, accurate, proofread)
5. **Support URL** (website, GitHub, or email)
6. **Valid Distribution Certificate** (from Apple Developer)
7. **App Store Provisioning Profile**

### Nice to Have:
1. App Preview video
2. TestFlight beta testing results
3. Marketing website
4. Social media presence
5. Press kit

---

## Estimated Timeline

| Phase | Duration |
|-------|----------|
| Asset creation (icons, screenshots) | 1-2 days |
| Final testing & bug fixes | 2-3 days |
| App Store Connect setup | 1 day |
| TestFlight beta testing | 1-2 weeks (optional) |
| Submit for review | 1 hour |
| **Apple review** | **1-7 days** |
| Launch & monitoring | Ongoing |

**Total to launch**: ~1-2 weeks (2-4 weeks with beta testing)

---

## Resources

### Official Apple Documentation
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Product Page](https://developer.apple.com/app-store/product-page/)

### Tools
- [App Store Screenshot Generator](https://www.appscreenshots.io/) - Create screenshots
- [App Icon Generator](https://appicon.co/) - Generate all icon sizes
- [App Store Review Times](https://appreviewtimes.com/) - Track average review times

### Community
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [r/iOSProgramming](https://reddit.com/r/iOSProgramming)
- [Stack Overflow - ios](https://stackoverflow.com/questions/tagged/ios)

---

## Quick Command Reference

### Build Commands
```bash
# Clean build
xcodebuild clean -project GetDiced.xcodeproj -scheme GetDiced

# Archive for distribution
xcodebuild archive -project GetDiced.xcodeproj \
  -scheme GetDiced \
  -archivePath ~/Desktop/GetDiced.xcarchive

# Export archive (requires exportOptions.plist)
xcodebuild -exportArchive \
  -archivePath ~/Desktop/GetDiced.xcarchive \
  -exportPath ~/Desktop/GetDiced \
  -exportOptionsPlist exportOptions.plist
```

### Version Check
```bash
# Check current version
grep -A 1 "MARKETING_VERSION" GetDiced/GetDiced.xcodeproj/project.pbxproj
```

---

## Notes

### Current Status (v1.0.0)
- ✅ All features implemented
- ✅ Version set to 1.0.0
- ✅ Default folders match Android (Owned, Wanted only)
- ⏳ Ready for asset creation and testing
- ⏳ Ready for App Store submission

### Known Considerations
- **Images**: 3,729 card images (175MB) stored locally - not in git
- **First Launch**: Requires network for initial card database sync
- **Offline**: Fully functional offline after initial sync
- **Database**: SQLite with 3,923 cards from SRG TCG

---

**Version**: 1.0.0
**Last Updated**: November 26, 2024
**Status**: Ready for pre-release preparation

---

_Good luck with your App Store submission! 🚀_
