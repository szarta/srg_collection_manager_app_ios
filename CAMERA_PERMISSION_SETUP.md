# Camera Permission Setup

The QR code scanning feature requires camera access. You need to add the camera usage description to your Xcode project.

## Steps to Add Camera Permission

### Option 1: Via Xcode Project Settings (Recommended)

1. Open the project in Xcode
2. Select the **GetDiced** target
3. Go to the **Info** tab
4. Click the **+** button under "Custom iOS Target Properties"
5. Add the following key-value pair:
   - **Key**: `Privacy - Camera Usage Description` (or `NSCameraUsageDescription`)
   - **Value**: `Camera access is required to scan QR codes for importing decks and collections.`

### Option 2: Via Info.plist File

If your project has a separate `Info.plist` file, add this entry:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan QR codes for importing decks and collections.</string>
```

## Testing the Feature

After adding the permission:

1. Build and run the app
2. Navigate to the **Scan** tab
3. Tap **Scan QR Code**
4. The app will prompt for camera permission (first time only)
5. Grant permission to use the camera
6. Point camera at a QR code from get-diced.com

## Troubleshooting

### "Camera permission required" alert shows immediately

This means the permission hasn't been added to the project. Follow the steps above to add `NSCameraUsageDescription`.

### Camera doesn't start after granting permission

1. Close and restart the app
2. Check that camera permission is granted in iOS Settings > GetDiced > Camera

### Simulator Issues

The iOS Simulator doesn't support camera access. You must test on a physical iOS device.

## Files Involved

- `GetDiced/GetDiced/Views/QRCodeScannerView.swift` - QR scanner implementation
- `GetDiced/GetDiced/Views/ScanAndImportView.swift` - Main scan interface
- Target Info settings - Camera permission configuration

## Security Note

The camera is only used for QR code scanning and is not used for any other purpose. The camera preview is destroyed immediately after scanning completes.
