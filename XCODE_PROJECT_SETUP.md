# Xcode Project Setup Instructions

## Step 1: Configure Xcode Command Line Tools

Run this in your terminal (requires password):
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

## Step 2: Create New Xcode Project

1. Open Xcode: `open -a Xcode`
2. Click "Create New Project" or File → New → Project
3. Choose **iOS → App**
4. Click **Next**
5. Fill in project details:
   - **Product Name**: `GetDiced`
   - **Team**: Select your Apple Developer team (if enrolled) or "None"
   - **Organization Identifier**: `com.srg`
   - **Bundle Identifier**: `com.srg.GetDiced` (auto-filled)
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: None
   - **Uncheck** "Include Tests" (for now)
6. Click **Next**
7. **IMPORTANT**: Navigate to `/Users/brandon/data/srg_collection_manager_app_ios`
8. **Replace existing GetDiced folder**: When prompted, choose to create project
9. Click **Create**

## Step 3: Set Deployment Target

1. Click on the project in the left sidebar (blue "GetDiced" icon)
2. Under "Targets" → "GetDiced", find "Minimum Deployments"
3. Set **iOS** to **16.0**

## Step 4: Verify Initial Build

1. Press **Cmd+B** to build
2. Should build successfully
3. Press **Cmd+R** to run in simulator
4. Should see "Hello, World!" or default SwiftUI view

## Next Steps

Once the project is created, I'll help you:
1. Import existing Swift model files
2. Add dependencies (SQLite.swift)
3. Copy database file
4. Set up app structure
5. Build the UI

---

## Alternative: Command Line Setup

If you prefer command line, run:
```bash
cd /Users/brandon/data/srg_collection_manager_app_ios
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

Then let me know when ready and I'll help create the project structure.
