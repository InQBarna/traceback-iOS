# SwiftUI Basic Sample

A basic SwiftUI application demonstrating core Traceback SDK integration with comprehensive debugging.

## Features

- ✅ Traceback SDK configuration
- ✅ Post-install link detection
- ✅ Universal Link handling
- ✅ Campaign link resolution
- ✅ Analytics event tracking
- ✅ Diagnostics validation
- ✅ **SDK Debug UI** - View raw SDK method results in real-time

## Prerequisites

1. **Firebase Project** with Traceback extension installed
   - Follow: https://github.com/InQBarna/firebase-traceback-extension

2. **Apple Developer Account** with Associated Domains enabled

3. **Physical iOS Device** (Universal Links don't work in Simulator)

## Quick Start with Script

The easiest way to build and install the sample is using the provided build script:

```bash
cd samples
./build-and-run.sh "iPhone 15 Pro"
```

This will:
1. ✅ Boot the specified simulator
2. ✅ Build the project
3. ✅ Install the app

Then you can launch it manually from the simulator home screen.

### Script Usage

**Build and Install:**
```bash
cd samples

# Use default device (iPhone 15 Pro) and default project (swiftui-basic)
./build-and-run.sh

# Specify a device
./build-and-run.sh "iPhone 14"

# Specify device and custom project path
./build-and-run.sh "iPhone 15 Pro" swiftui-basic/TracebackSwiftUIExample/TracebackSwiftUIExample.xcodeproj
```

**Uninstall:**
```bash
cd samples

# Use default device and bundle ID
./uninstall.sh

# Specify a device
./uninstall.sh "iPhone 14"

# Specify device and custom bundle ID
./uninstall.sh "iPhone 15 Pro" com.custom.bundle.id
```

**List available simulators:**
```bash
xcrun simctl list devices available | grep iPhone
```

**Note:** Universal Links don't work in the Simulator. For full testing, you need a physical device.

---

## Manual Setup Instructions

### 1. Firebase Configuration

1. Create an iOS app in your Firebase Console
2. Download `GoogleService-Info.plist` (optional - only if you use Firebase in your app)
3. Note your Traceback domain from the extension setup (e.g., `your-project-traceback.firebaseapp.com`)

### 2. Update App Configuration

Open `TracebackSwiftUIExample.xcodeproj` in Xcode and:

1. **Update Bundle Identifier**
   - Select the project in Navigator
   - Go to "Signing & Capabilities" tab
   - Change bundle identifier to match your Firebase app

2. **Configure Associated Domains**
   - In "Signing & Capabilities", ensure "Associated Domains" is enabled
   - Add your Traceback domain:
     ```
     applinks:your-project-traceback.firebaseapp.com
     ```

3. **Configure URL Schemes**
   - Go to "Info" tab
   - Expand "URL Types"
   - Verify the URL scheme matches your bundle identifier
   - Or create a custom scheme for deep linking (e.g., `myapp`)

4. **Update Traceback Configuration**
   - Open `TracebackSwiftUIExampleApp.swift`
   - Update the `mainAssociatedHost` with your Traceback domain:
     ```swift
     let config = TracebackConfiguration(
         mainAssociatedHost: URL(string: "https://your-project-traceback.firebaseapp.com")!,
         useClipboard: true,
         logLevel: .debug
     )
     ```

### 3. Run Diagnostics

1. Build and run on a physical device
2. Check Xcode console for diagnostics output
3. Resolve any errors or warnings reported

## Testing

### Test Post-Install Detection

1. Create a test link in your Traceback extension:
   ```
   https://your-project-traceback.firebaseapp.com/welcome?link=myapp://products/123
   ```

2. Copy the link to clipboard

3. Delete the app from your device

4. Install and launch the app

5. The app should:
   - Detect the clipboard link
   - Show "Post-install link detected!"
   - Display the deep link: `myapp://products/123`

### Test Campaign Links (Already Installed)

1. Create a campaign link:
   ```
   https://your-project-traceback.firebaseapp.com/promo?link=myapp://settings
   ```

2. Send the link to yourself via Messages or Email

3. Tap the link with the app already installed

4. The app should:
   - Resolve the campaign link
   - Show "Campaign link resolved!"
   - Display the deep link: `myapp://settings`

### Test Universal Links

1. Create a Universal Link and host it on your website or use the Traceback domain

2. Tap the link from Safari, Messages, or Email

3. The app should open and handle the link

## Project Structure

```
TracebackSwiftUIExample/
├── TracebackSwiftUIExampleApp.swift    # App entry point, SDK setup, and AppState
├── AppState+DeepLink.swift              # Deep link handling methods (extension)
├── ContentView.swift                    # Main UI
└── Info.plist                           # URL schemes configuration
```

## Debug UI

The app displays real-time SDK debugging information:

### SDK Results Panel
- **`isTracebackURL`** - Shows `true`/`false` result for opened URLs
- **`postInstallSearchLink()`** - Displays the URL returned from post-install detection (or `nil`)
- **`campaignSearchLink()`** - Displays the URL returned from campaign resolution (or `nil`)

### Debug Status
- Shows current SDK operation with emoji indicators:
  - ✅ Success
  - ❌ Error
  - ℹ️ Info
  - ⏳ Loading

### Analytics Events
- All SDK analytics events are logged in real-time
- Shows events from both post-install and campaign methods

This makes it easy to:
- Verify which SDK method returned a link
- Debug URL validation logic
- Understand the SDK's behavior step-by-step

## Key Implementation Details

### SDK Initialization

The SDK is initialized in `TracebackSwiftUIExampleApp.swift`:

```swift
lazy var traceback: TracebackSDK = {
    let config = TracebackConfiguration(
        mainAssociatedHost: URL(string: "https://your-project-traceback.firebaseapp.com")!,
        useClipboard: true,
        logLevel: .debug
    )
    return TracebackSDK.live(config: config)
}()
```

### Post-Install Detection

Called once on app launch in `ContentView.onAppear`:

```swift
.onAppear {
    Task {
        do {
            let result = try await traceback.postInstallSearchLink()
            if let url = result.url {
                handleDeepLink(url)
                sendAnalytics(result.analytics)
            }
        } catch {
            logger.error("Post-install search failed: \(error)")
        }
    }
}
```

### Universal Link Handling

Handled via `onOpenURL` modifier:

```swift
.onOpenURL { url in
    guard traceback.isTracebackURL(url) else { return }

    Task {
        do {
            let result = try await traceback.campaignSearchLink(url)
            if let deepLink = result.url {
                handleDeepLink(deepLink)
                sendAnalytics(result.analytics)
            }
        } catch {
            logger.error("Campaign link resolution failed: \(error)")
        }
    }
}
```

## Troubleshooting

### Universal Links not working

- ✅ Ensure you're testing on a physical device (not Simulator)
- ✅ Verify Associated Domains are configured correctly
- ✅ Run `traceback.performDiagnostics()` to check setup
- ✅ Check that your app is signed with the correct team

### Post-install detection not working

- ✅ Verify `useClipboard: true` in configuration
- ✅ Ensure the link is copied to clipboard before install
- ✅ Check console logs for diagnostic information

### Build errors

- ✅ Ensure you're using Xcode 15+ and iOS 15+ deployment target
- ✅ Verify Traceback SDK package dependency is resolved
- ✅ Clean build folder (Cmd+Shift+K) and rebuild

## Next Steps

- Review the [main SDK documentation](../../README.md)
- Explore other samples (UIKit, advanced analytics, etc.)
- Customize the deep link navigation for your app's needs
- Integrate with your analytics platform

## Support

- Report issues: https://github.com/InQBarna/traceback-iOS/issues
- Main documentation: https://github.com/InQBarna/traceback-iOS
