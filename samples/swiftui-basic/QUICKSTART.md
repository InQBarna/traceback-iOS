# Quick Start Guide

Get the SwiftUI Basic sample running in 5 minutes.

## Step 1: Open the Project

```bash
open TracebackSwiftUIExample/TracebackSwiftUIExample.xcodeproj
```

## Step 2: Update Configuration

In Xcode, you need to update 3 places with your Firebase Traceback domain:

### 2.1 Update Bundle Identifier & Associated Domains

1. Select `TracebackSwiftUIExample` project in Navigator
2. Select the `TracebackSwiftUIExample` target
3. Go to "Signing & Capabilities" tab
4. **Update your Team** for code signing
5. **Update Bundle Identifier** (e.g., `com.yourcompany.traceback.demo`)
6. In "Associated Domains", replace `your-project-traceback.firebaseapp.com` with your actual domain

### 2.2 Update Entitlements File

Open `TracebackSwiftUIExample/TracebackSwiftUIExample.entitlements` and update:

```xml
<string>applinks:YOUR-ACTUAL-DOMAIN.firebaseapp.com</string>
```

### 2.3 Update SDK Configuration

Open `TracebackSwiftUIExampleApp.swift` and update line ~29:

```swift
mainAssociatedHost: URL(string: "https://YOUR-ACTUAL-DOMAIN.firebaseapp.com")!,
```

### 2.4 Optional: Update URL Scheme

If you want a custom deep link scheme (instead of `myapp://`):

1. Open `Info.plist`
2. Find `CFBundleURLSchemes`
3. Change `myapp` to your desired scheme

## Step 3: Build and Run

1. Connect a **physical iOS device** (Universal Links don't work in Simulator)
2. Select your device in Xcode
3. Build and Run (Cmd+R)
4. Check the console for diagnostics output

## Step 4: Test Deep Links

### Test Post-Install Detection

1. Create a test link in your browser:
   ```
   https://YOUR-DOMAIN.firebaseapp.com/welcome?link=myapp://home
   ```

2. **Copy the link** to clipboard (Cmd+C)

3. **Delete the app** from your device

4. **Reinstall and launch** the app

5. The app should detect the clipboard link and navigate to Home

### Test Campaign Links

1. Send yourself this link via Messages:
   ```
   https://YOUR-DOMAIN.firebaseapp.com/promo?link=myapp://products/123
   ```

2. Tap the link with the app already installed

3. The app should open and navigate to Product 123

## Troubleshooting

### "Could not resolve package dependencies"

The project references the Traceback SDK from GitHub. If you're testing locally:

1. In Xcode, go to File → Swift Packages → Resolve Package Versions
2. Or, update the package reference to point to your local SDK:
   - File → Swift Packages → Remove Package "Traceback"
   - File → Add Packages → Add Local → Select your local traceback-iOS folder

### "Universal Links not working"

- Ensure you're testing on a **physical device**
- Check the Xcode console for diagnostics warnings
- Verify your Associated Domains are correct
- Try deleting and reinstalling the app

### "No post-install link detected"

- Make sure `useClipboard: true` in configuration
- Verify the link was copied before installing
- Check console logs for detailed information

## Next Steps

- Review the source code to understand the implementation
- Customize the deep link routes in `DeepLinkRoute.from()`
- Add your own analytics integration
- Explore other samples for advanced use cases
