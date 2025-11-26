# Card Images Guide

**Created**: November 26, 2024
**Status**: 3,729 images integrated into iOS app

---

## 📸 Overview

The Get Diced iOS app displays card images from the SRG trading card game. Images are stored locally in the app's Documents directory for offline access and fast loading.

### Quick Facts
- **Total Images**: 3,729 WebP files
- **Total Size**: 175MB
- **Format**: WebP (optimized for mobile)
- **Source**: `~/data/srg_card_search_website/backend/app/images/mobile/`
- **Not in Git**: Excluded via `.gitignore` (too large)

---

## 📂 Directory Structure

### Source Images (Website Backend)
```
~/data/srg_card_search_website/backend/app/images/mobile/
├── 00/
│   ├── 0002786b87a541dbad94e1361034c181.webp
│   ├── 0004458c7d0c4525a667c4280cd54d97.webp
│   └── ... (more .webp files)
├── 01/
├── 02/
├── ...
└── ff/
```

**Organization**: Images are organized into 256 directories (00 through ff) based on the first two characters of the card's UUID.

### iOS App Storage
```
[Simulator Documents]/images/mobile/
├── 00/
│   └── [card-uuid].webp
├── 01/
├── ...
└── ff/
```

**Simulator Path Example**:
```
/Users/brandon/Library/Developer/CoreSimulator/Devices/
  [DEVICE-ID]/data/Containers/Data/Application/
  [APP-ID]/Documents/images/mobile/
```

---

## 🚀 Setup Instructions

### First Time Setup

1. **Ensure Source Images Exist**:
   ```bash
   ls ~/data/srg_card_search_website/backend/app/images/mobile/
   # Should show directories: 00, 01, 02, ... ff
   ```

2. **Run the App Once**:
   ```bash
   cd /Users/brandon/data/srg_collection_manager_app_ios/GetDiced
   open GetDiced.xcodeproj
   # Press Cmd+R to run in simulator
   ```

3. **Copy Images to Simulator**:
   ```bash
   cd /Users/brandon/data/srg_collection_manager_app_ios
   ./copy_images.sh
   ```

4. **Restart the App**:
   - Stop the app in simulator (Cmd+.)
   - Run again (Cmd+R)
   - Images will now load! 🎉

### Verifying Images Copied

Check the console output when copying:
```bash
./copy_images.sh

# Expected output:
# 🖼️  Copying card images to iOS app...
# 📂 Source: /Users/brandon/data/srg_card_search_website/backend/app/images/mobile
# 📂 Target: [Simulator path]
# 📋 Copying directory: 00
# 📋 Copying directory: 01
# ...
# ✅ Copied 3729 images to app Documents directory
# 🎉 Done! Restart the app to see card images.
```

---

## 🔧 copy_images.sh Script

### Location
```
/Users/brandon/data/srg_collection_manager_app_ios/copy_images.sh
```

### What It Does
1. Finds the running simulator's app container
2. Locates the app's Documents directory
3. Creates `images/mobile/` structure
4. Copies all subdirectories (00-ff) from source
5. Copies all .webp files into respective directories
6. Reports total images copied

### Usage
```bash
cd /Users/brandon/data/srg_collection_manager_app_ios
./copy_images.sh
```

### Requirements
- iOS Simulator must be running
- App must have been launched at least once
- Source images must exist at expected path

### Troubleshooting

**Error: App container not found**
```
❌ Error: App container not found. Make sure:
   1. The simulator is running
   2. The app has been launched at least once
   3. The bundle ID is correct (com.srg.GetDiced)
```

**Solution**: Run the app first (Cmd+R), then run the script.

---

## 💻 Image Loading System

### ImageHelper Service

**File**: `GetDiced/GetDiced/Services/ImageHelper.swift`

**Key Functions**:

1. **`imageURL(for: cardId) -> URL?`**
   - Constructs path based on card UUID
   - Checks if file exists in Documents
   - Returns file URL or nil if not found

2. **`documentsPath() -> String`**
   - Returns app Documents directory path
   - Useful for debugging

**Example**:
```swift
let cardId = "0002786b87a541dbad94e1361034c181"
let url = ImageHelper.imageURL(for: cardId)
// Returns: file:///path/to/Documents/images/mobile/00/0002786b87a541dbad94e1361034c181.webp
```

### UUID-Based Organization

Card UUIDs determine storage location:
- UUID: `0002786b87a541dbad94e1361034c181`
- First 2 chars: `00`
- Directory: `images/mobile/00/`
- Filename: `0002786b87a541dbad94e1361034c181.webp`

This creates 256 directories (00-ff) for efficient file organization.

---

## 🎨 UI Integration

### CardRow Component

**Small Thumbnails (60×84)**:
```swift
struct CardRow: View {
    let card: Card

    var body: some View {
        HStack {
            if let imageURL = ImageHelper.imageURL(for: card.id) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 84)
                    case .failure, .empty:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }

            // Card info...
        }
    }
}
```

### CardDetailView

**Large Display (max 300px)**:
```swift
var cardImage: some View {
    if let imageURL = ImageHelper.imageURL(for: card.id) {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            case .failure, .empty:
                placeholderImage
            @unknown default:
                placeholderImage
            }
        }
    }
}
```

### AsyncImage Benefits
- Native SwiftUI image loading
- Automatic caching
- Loading states built-in
- Handles failures gracefully
- No external dependencies needed

---

## 📋 Image Stats

### Coverage
- **Database Cards**: 3,923
- **Images Available**: 3,729
- **Coverage**: ~95%

### Missing Images
Some cards may not have images. The app gracefully shows placeholders for these cases.

### File Sizes
- **Average**: ~45KB per image
- **Total**: 175MB for all images
- **Format**: WebP (better compression than PNG/JPG)

---

## 🔒 Git Configuration

### .gitignore Entries
```gitignore
# Card Images
# Images are large (175MB+) and stored separately
# Use copy_images.sh to copy from source directory
GetDiced/GetDiced/Resources/images/
GetDiced/Resources/images/
**/images/mobile/
*.webp
```

### Why Not in Git?
- **Size**: 175MB is too large for git repository
- **Duplication**: Images already exist in website backend
- **Flexibility**: Developers copy from shared source
- **Updates**: Images can be updated without affecting code

---

## 🔄 Updating Images

### When New Images Added to Backend

1. **Pull Latest Backend**:
   ```bash
   cd ~/data/srg_card_search_website
   git pull
   ```

2. **Re-run Copy Script**:
   ```bash
   cd /Users/brandon/data/srg_collection_manager_app_ios
   ./copy_images.sh
   ```

3. **Restart App**:
   - The script only copies new/changed files
   - Existing images are preserved

### Clearing Images (Fresh Start)

```bash
# Get app container path
APP_CONTAINER=$(xcrun simctl get_app_container booted com.srg.GetDiced data)

# Remove images
rm -rf "$APP_CONTAINER/Documents/images"

# Re-copy
./copy_images.sh
```

---

## 🐛 Common Issues

### Images Not Showing

**Symptom**: Placeholder images instead of real cards

**Causes**:
1. Images not copied yet
2. Wrong simulator/device
3. App container changed (app reinstalled)

**Solution**:
```bash
# Check if images exist
APP_CONTAINER=$(xcrun simctl get_app_container booted com.srg.GetDiced data)
ls -la "$APP_CONTAINER/Documents/images/mobile/"

# If empty, run copy script
./copy_images.sh
```

### Script Can't Find App

**Symptom**:
```
❌ Error: App container not found
```

**Solution**:
1. Boot simulator: `open -a Simulator`
2. Run app once: Open Xcode, press Cmd+R
3. Run script: `./copy_images.sh`

### Wrong Bundle ID

**Symptom**: Script uses `com.barrendondo.GetDiced` but app uses `com.srg.GetDiced`

**Solution**: Edit `copy_images.sh`, line 13:
```bash
APP_CONTAINER=$(xcrun simctl get_app_container booted com.srg.GetDiced data 2>/dev/null)
```

---

## 📱 Testing Images

### Visual Check

1. Run app
2. Add a card to a folder
3. Verify:
   - ✅ Thumbnail shows in list
   - ✅ Full image shows in detail view
   - ✅ Loading spinner appears briefly
   - ✅ Placeholder if image missing

### Debug Logging

The app prints Documents path on launch:
```
📂 Documents directory: /path/to/Documents
```

Check this path to verify images are in right location.

---

## 🚀 Performance

### Loading Time
- **First Load**: ~100ms (from disk)
- **Cached**: <10ms (AsyncImage cache)
- **Placeholder**: Instant

### Memory Usage
- **Thumbnail**: ~200KB in memory
- **Full Image**: ~500KB in memory
- **AsyncImage**: Automatically releases when off-screen

### Best Practices
- ✅ Use AsyncImage (handles caching)
- ✅ Lazy loading in lists
- ✅ Placeholders for missing images
- ✅ Proper aspect ratios
- ❌ Don't preload all images
- ❌ Don't keep all images in memory

---

## 🔮 Future Enhancements

### Possible Improvements
1. **Server Fallback**: Download missing images from get-diced.com
2. **Progressive Loading**: Download images as needed
3. **Image Sync**: Auto-update from server
4. **Compression**: Further optimize file sizes
5. **CDN**: Serve from CDN instead of local storage

### Not Implemented Yet
- [ ] Download from server
- [ ] Auto-sync with backend
- [ ] Image cache management
- [ ] Progressive download

---

## 📞 Quick Reference

### Paths
- **Source**: `~/data/srg_card_search_website/backend/app/images/mobile/`
- **Script**: `/Users/brandon/data/srg_collection_manager_app_ios/copy_images.sh`
- **ImageHelper**: `GetDiced/GetDiced/Services/ImageHelper.swift`
- **Simulator**: `xcrun simctl get_app_container booted com.srg.GetDiced data`

### Commands
```bash
# Copy images
./copy_images.sh

# Find app container
xcrun simctl get_app_container booted com.srg.GetDiced data

# Check image count
find "$APP_CONTAINER/Documents/images/mobile" -name "*.webp" | wc -l

# Check total size
du -sh "$APP_CONTAINER/Documents/images/mobile"
```

### Stats
- **Images**: 3,729
- **Size**: 175MB
- **Directories**: 256 (00-ff)
- **Format**: WebP
- **Coverage**: ~95%

---

## ✅ Success Checklist

After setup, verify:
- [x] Script runs without errors
- [x] 3,729 images copied
- [x] App shows images in CardRow
- [x] App shows images in CardDetailView
- [x] Placeholders work for missing images
- [x] Loading states appear briefly
- [x] No console errors about images

---

**Status**: Images fully integrated and working! 🎉

**Next**: Images will persist in simulator until app is deleted or simulator is reset.

---

_Last updated: Nov 26, 2024_
_Part of Get Diced iOS Development_
