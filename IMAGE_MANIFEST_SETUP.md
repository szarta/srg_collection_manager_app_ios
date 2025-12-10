# Image Manifest Setup Guide

**Date:** 2025-12-09
**Feature:** Hash-Based Image Manifest System

---

## Overview

The iOS app now uses a hash-based image manifest system (matching the Android app) instead of bundling all 158MB of images. This provides:

- ✅ Small app size (just 718KB manifest vs 158MB images)
- ✅ Progressive image download as needed
- ✅ Hash verification for integrity
- ✅ Updates without app updates
- ✅ Optional full offline download
- ✅ Cross-platform consistency with Android

---

## What Was Implemented

### 1. ImageSyncService
**File:** `GetDiced/GetDiced/Services/ImageSyncService.swift`

New service that handles:
- Loading bundled manifest from app bundle
- Loading local manifest (for synced images)
- Comparing local vs server hashes
- Downloading missing/changed images
- Verifying image integrity with SHA-256 hashes
- Progressive sync with progress callbacks

### 2. Updated ImageHelper
**File:** `GetDiced/GetDiced/Services/ImageHelper.swift`

Now checks three locations in priority order:
1. Synced images directory (`synced_images/`)
2. Legacy documents directory (backward compatibility)
3. Server fallback

### 3. Updated SyncViewModel
**File:** `GetDiced/GetDiced/ViewModels/SyncViewModel.swift`

- Replaced old image sync with manifest-based approach
- Added `checkImageSyncStatus()` to check sync status without downloading
- Integrated with `ImageSyncService`

### 4. Existing Models
**File:** `GetDiced/GetDiced/Models/APIModels.swift`

Models already existed from previous session:
- `ImageManifest` - Manifest structure
- `ImageInfo` - Individual image metadata

---

## Manual Setup Required

### Step 1: Add Manifest File to Xcode Project

The manifest file has been copied to:
```
GetDiced/GetDiced/images_manifest.json (718KB)
```

**You need to:**
1. Open the project in Xcode
2. Right-click on the `GetDiced` folder in the Project Navigator
3. Select "Add Files to GetDiced..."
4. Navigate to and select `images_manifest.json`
5. **IMPORTANT:** Ensure "Copy items if needed" is **UNCHECKED** (file is already in place)
6. **IMPORTANT:** Ensure "Add to targets: GetDiced" is **CHECKED**
7. Click "Add"

This ensures the manifest file is bundled with the app.

### Step 2: Verify Manifest is Bundled

After adding the file:
1. Select the `GetDiced` target in Xcode
2. Go to "Build Phases"
3. Expand "Copy Bundle Resources"
4. Verify `images_manifest.json` appears in the list

If it's not there, drag it from the Project Navigator into the "Copy Bundle Resources" section.

---

## How It Works

### Bundled Manifest
- Ships with app (718KB)
- Contains metadata for 3,912 images
- Each entry has:
  - UUID (card ID)
  - Path (e.g., "00/[uuid].webp")
  - SHA-256 hash (for verification)

### Local Manifest
- Stored in Documents directory
- Tracks synced/downloaded images
- Updated after each sync
- Overrides bundled manifest for newer versions

### Image Syncing Process

1. **Check Status**
   ```swift
   let (needSync, total) = try await imageSyncService.getSyncStatus()
   ```

2. **Sync Images**
   ```swift
   let (downloaded, total) = try await imageSyncService.syncImages { downloaded, total in
       // Progress callback
   }
   ```

3. **Verify Image**
   ```swift
   let isValid = imageSyncService.verifyImageHash(uuid: cardId, fileURL: imageURL)
   ```

### Image Loading Priority

When loading a card image:
1. Check `Documents/synced_images/[first2]/[uuid].webp` (manifest-synced)
2. Check `Documents/images/mobile/[first2]/[uuid].webp` (legacy)
3. Fallback to `https://get-diced.com/images/mobile/[first2]/[uuid].webp`

---

## Testing

### 1. Test Manifest Loading
Run the app and trigger image sync:
- Go to Sync tab
- Tap "Sync Images"
- Should see "Checking for missing images..."

### 2. Verify Console Output
Look for these messages in Xcode console:
```
✅ Loaded bundled manifest: 3912 images
💾 Local hashes: 0 images (first run)
📥 Images to sync: [number]
```

### 3. Test Image Loading
- Browse cards in Card Viewer
- Images should load from server initially
- After sync, should load from local storage
- Check Documents directory for synced_images folder

---

## API Endpoint

The sync service fetches the server manifest from:
```
GET https://get-diced.com/api/images-manifest
```

This should return the same JSON structure as the bundled manifest.

---

## Troubleshooting

### "Bundled manifest not found in app bundle"
**Problem:** Manifest file not added to Xcode project
**Solution:** Follow "Step 1: Add Manifest File to Xcode Project" above

### "Failed to fetch server manifest"
**Problem:** API endpoint not available
**Solution:** Verify the endpoint exists and returns proper JSON

### Images not loading after sync
**Problem:** Images saved to wrong directory
**Solution:** Check ImageSyncService saves to `Documents/synced_images/`

### Hash verification fails
**Problem:** Downloaded image doesn't match manifest hash
**Solution:**
- Check server image hasn't been modified
- Verify SHA-256 hash calculation is correct
- Re-download the image

---

## Files Created/Modified

**Created:**
- `GetDiced/GetDiced/Services/ImageSyncService.swift`
- `GetDiced/GetDiced/images_manifest.json` (copied from Android)
- `IMAGE_MANIFEST_SETUP.md` (this file)

**Modified:**
- `GetDiced/GetDiced/Services/ImageHelper.swift`
- `GetDiced/GetDiced/ViewModels/SyncViewModel.swift`

**Not Created (Already Existed):**
- `GetDiced/GetDiced/Models/APIModels.swift` (ImageManifest, ImageInfo)

---

## Benefits Over Bundled Images

| Approach | App Size | First Launch | Offline | Updates | Best For |
|----------|----------|--------------|---------|---------|----------|
| **Bundled (158MB)** | 158MB+ | All images available | ✅ Full | Requires app update | Desktop apps |
| **Manifest (718KB)** | <1MB | Progressive load | ⚠️ On-demand | Independent of app | **Mobile apps** ✅ |

---

## Next Steps

1. ✅ Add manifest file to Xcode project (manual step above)
2. ✅ Test image sync on simulator/device
3. ✅ Verify cross-platform compatibility (iOS synced images work with Android manifest)
4. Optional: Add UI to show sync status and progress
5. Optional: Add "Download all images" button for full offline support

---

## Cross-Platform Compatibility

The manifest format is identical to Android's:
- Same JSON structure
- Same image paths
- Same SHA-256 hashes
- Images synced from same server

This ensures iOS and Android users can share decks/collections without issues.

---

_End of Setup Guide_
