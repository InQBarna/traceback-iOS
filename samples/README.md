# Traceback iOS SDK - Sample Applications

This directory contains sample applications demonstrating how to integrate and use the Traceback iOS SDK in different scenarios.

## Available Samples

### [swiftui-basic](./swiftui-basic/)
A basic SwiftUI application demonstrating:
- Standard Traceback SDK configuration
- Post-install link detection
- Universal Link handling with campaign resolution
- Deep link navigation
- Analytics event tracking
- Diagnostics setup

**Best for:** Getting started with Traceback in a SwiftUI project

### Coming Soon

- **uikit-basic** - Basic UIKit implementation
- **advanced-analytics** - Advanced analytics integration
- **custom-domains** - Multiple domain configuration
- **clipboard-disabled** - Privacy-focused setup without clipboard

## Prerequisites

Before running any sample:

1. **Install the Traceback Firebase Extension** in your Firebase project
   - Follow instructions at: https://github.com/InQBarna/firebase-traceback-extension

2. **Configure Firebase** for your sample app
   - Create an iOS app in your Firebase Console
   - Download `GoogleService-Info.plist`

3. **Set up Associated Domains**
   - Configure your Apple Developer account
   - Enable Associated Domains capability
   - Add the Traceback domain from your Firebase extension

## Running a Sample

Each sample includes its own README with specific setup instructions. Generally:

1. Navigate to the sample directory
2. Follow the README to configure Firebase settings
3. Open the `.xcodeproj` or `.xcworkspace` in Xcode
4. Update the bundle identifier and signing team
5. Run the app on a physical device (Universal Links don't work in Simulator)

## Testing Deep Links

### Create a Test Link

Use the Traceback Firebase extension to create a test deep link:

```bash
# Example: Create a link to open /products/123 in your app
https://your-project-traceback.firebaseapp.com/campaign-name?link=myapp://products/123
```

### Test Post-Install Flow

1. Copy the Traceback link to clipboard
2. Delete the app from your device
3. Install and launch the app
4. The app should detect and open the deep link

### Test Campaign Links

1. Send yourself the Traceback link via Messages/Email
2. Open the link with the app already installed
3. The app should resolve and open the deep link

## Need Help?

- Check the main [README](../README.md) for SDK documentation
- Review the [Troubleshooting](../README.md#troubleshooting) section
- Run `traceback.performDiagnostics()` to validate your setup
- Report issues at: https://github.com/InQBarna/traceback-iOS/issues
