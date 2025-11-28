# Traceback iOS SDK

A lightweight iOS companion library for the Traceback Firebase extension - a modern replacement for Firebase Dynamic Links.

## Installation

Install the firebase extension into your firebase project. https://github.com/InQBarna/firebase-traceback-extension

In your iOS app:

1. Install this companion sdk using SPM
```swift
https://github.com/InQBarna/traceback-iOS
```
2. In the Info tab of your app's Xcode project, create a new URL type to be used for Traceback. Set the Identifier field to a unique value and the URL scheme field to be your bundle identifier.
3. In the Capabilities tab of your app's Xcode project, enable Associated Domains and add the following to the Associated Domains list:
```
applinks:your_dynamic_links_domain
```

## Usage

Create your configuration and grab the sdk tool instance

```swift
import Traceback

/* ... */
lazy var traceback: TracebackSDK = {
    let config = TracebackConfiguration(
        mainAssociatedHost: URL(string: "https://your-project-traceback.firebaseapp.com")!,
        useClipboard: true,
        logLevel: .error
    )
    return TracebackSDK.live(config: config)
}()
```

### Configuration Options

The `TracebackConfiguration` supports these parameters:

- **`mainAssociatedHost`**: *(required)* The main domain created by the Traceback Firebase extension
- **`associatedHosts`**: *(optional)* Additional domains associated with your app
- **`useClipboard`**: *(default: true)* Enable clipboard reading for better post-install detection
- **`logLevel`**: *(default: .info)* Logging verbosity (`.error`, `.debug`, `.info`)

```swift
let config = TracebackConfiguration(
    mainAssociatedHost: URL(string: "https://your-project-traceback.firebaseapp.com")!,
    associatedHosts: [
        URL(string: "https://your-custom-domain.com")!
    ],
    useClipboard: true,
    logLevel: .debug
)
```

### SwiftUI

We recommend grabbing and handling links within your root SwiftUI view. Choose the right
 root view, where you can handle deep navigations. See the example implementation below

```swift

struct PreLandingView: View {
    @ObservedObject var viewModel: PreLandingViewModel
    var body: some View {
        /* ... */
        .onAppear {
            Task {
                do {
                    // 1.- Search for post-install link and proceed if available
                    let result = try await traceback.postInstallSearchLink()
                    if let tracebackURL = result.url {
                        proceed(onOpenURL: tracebackURL)
                    }
                } catch {
                    // Handle error - network issues, configuration problems, etc.
                    logger.error("Failed to search for post-install link: \(error)")
                }
            }
        }
        .onOpenURL { url in
            proceed(onOpenURL: url)
        }
    }

    // This method is to be called from onOpenURL or after post install link search
    func proceed(onOpenURL url: URL) {
        // 2.- Check if this is a Traceback URL
        guard traceback.isTracebackURL(url) else {
            // Not a Traceback URL, handle it elsewhere
            handleDeepLink(linkURL)
            return
        }

        Task {
            do {
                // 3.- Check if dynamic campaign link exists (resolves the deep link from the URL)
                let linkResult = try await traceback.campaignSearchLink(url)

                guard let linkURL = linkResult.url else {
                    // No deep link found in this URL, so we normally continue opening the app Landing screen
                    return
                }

                // 4.- Handle the url, opening the right content indicated by linkURL
                // Use linkURL to navigate to the appropriate content in your app
                // You can also access linkResult.analytics for tracking purposes
                handleDeepLink(linkURL)
                sendAnalytics(linkResult.analytics)
            } catch {
                // Handle error - network issues, invalid URL, etc.
                logger.error("Failed to resolve campaign link: \(error)")
            }
        }
    }
}
```

### UIKit

```swift

@MainActor
class YourAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        Task {
            do {
                // 1.- Trigger a search for installation links
                //  if a link is found successfully, it will be sent to proceed(openURL:) below
                let result = try await traceback.postInstallSearchLink()
                if let tracebackURL = result.url {
                    proceed(onOpenURL: tracebackURL)
                }
            } catch {
                // Handle error - network issues, configuration problems, etc.
                logger.error("Failed to search for post-install link: \(error)")
            }
        }
        return true
    }

    /* ... */

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        proceed(onOpenURL: url)
        return true
    }

    // This method is to be called from application(open:options:) or after post install link search
    func proceed(onOpenURL url: URL) {
        // 2.- Check if this is a Traceback URL
        guard traceback.isTracebackURL(url) else {
            // Not a Traceback URL, handle it elsewhere
            handleDeepLink(linkURL)
            return
        }

        Task {
            do {
                // 3.- Check if dynamic campaign link exists (resolves the deep link from the URL)
                let linkResult = try await traceback.campaignSearchLink(url)

                guard let linkURL = linkResult.url else {
                    // No deep link found in this URL, so we normally continue opening the app Landing screen
                    return
                }

                // 4.- Handle the url, opening the right content indicated by linkURL
                // Use linkURL to navigate to the appropriate content in your app
                // You can also access linkResult.analytics for tracking purposes
                handleDeepLink(linkURL)
                sendAnalytics(linkResult.analytics)
            } catch {
                // Handle error - network issues, invalid URL, etc.
                logger.error("Failed to resolve campaign link: \(error)")
            }
        }
    }
}
```

## Diagnostics

The SDK includes a comprehensive diagnostics tool to validate your dynamic links configuration:

```swift
// Call this during app development to verify your setup
traceback.performDiagnostics()
```

This will output detailed diagnostic information using os_log (viewable in Console.app or Xcode debug console), including:

### Configuration Validation
- **SDK version and app information**
- **Configuration host validation** (HTTPS, valid hostname)
- **Additional hosts validation** (if configured)
- **Clipboard settings** with recommendations

### App Setup Verification
- **URL scheme configuration** in Info.plist
- **UIApplication delegate** method implementation
- **Associated Domains entitlements** validation
- **Universal Links setup** verification

### Environment Checks
- **iOS Simulator warnings** (Universal Links don't work in simulator)
- **Network connectivity** guidance
- **Production readiness** recommendations

The diagnostics will categorize issues as:
- ❌ **Errors**: Must be fixed before production use
- ⚠️ **Warnings**: Should be addressed for optimal functionality
- ✅ **Success**: Configuration is correct

## API Reference

### TracebackSDK Methods

#### `postInstallSearchLink() async throws -> TracebackSDK.Result`
Searches for the deep link that triggered the app installation. Call this once during app launch.

#### `campaignSearchLink(_ url: URL) async throws -> TracebackSDK.Result`
Resolves a Traceback URL opened via Universal Link or custom URL scheme into a deep link.

#### `isTracebackURL(_ url: URL) -> Bool`
Validates if the given URL matches any of the configured Traceback domains.

#### `performDiagnostics()`
Runs comprehensive validation of your Traceback configuration and outputs diagnostic information.

### TracebackSDK.Result

The result object returned by `postInstallSearchLink()` and `campaignSearchLink()` contains:

- `url: URL?` - The extracted deep link URL to navigate to
- `matchType: MatchType` - How the link was detected (`.unique`, `.heuristics`, `.ambiguous`, `.intent`, `.none`, `.unknown`)
- `analytics: [TracebackAnalyticsEvent]` - Analytics events you can send to your preferred platform

### TracebackConfiguration

Configuration object for initializing the SDK:

```swift
public struct TracebackConfiguration {
    public let mainAssociatedHost: URL
    public let associatedHosts: [URL]?
    public let useClipboard: Bool
    public let logLevel: LogLevel
    
    public enum LogLevel: Int {
        case error   // Only errors
        case debug   // Debug info, warnings, and errors  
        case info    // Verbose logging (all messages)
    }
}
```

## Error Handling

The SDK uses Swift's error handling mechanisms. Both `postInstallSearchLink()` and `campaignSearchLink()` can throw errors:

### Post-Install Link Search

```swift
do {
    let result = try await traceback.postInstallSearchLink()
    if let url = result.url {
        // Handle successful link detection
        handleDeepLink(url)
        // Send analytics events
        sendAnalytics(result.analytics)
    } else {
        // No link found - normal app startup
        handleNormalStartup()
    }
} catch {
    // Handle network or configuration errors
    logger.error("Failed to search for post-install link: \(error)")
    handleNormalStartup()
}
```

### Campaign Link Resolution

```swift
do {
    let result = try await traceback.campaignSearchLink(url)
    if let deepLink = result.url {
        // Handle successful link resolution
        handleDeepLink(deepLink)
        // Send analytics events
        sendAnalytics(result.analytics)
    } else {
        // URL is valid Traceback URL but no deep link found
        handleNormalStartup()
    }
} catch {
    // Handle network or configuration errors
    logger.error("Failed to resolve campaign link: \(error)")
}
```

## Troubleshooting

### Common Issues

#### "No post-install links detected"
- ✅ Verify `useClipboard: true` in configuration
- ✅ Test on physical device (simulator limitations)  
- ✅ Check Universal Links setup with diagnostics
- ✅ Ensure associated domains are properly configured

#### "Universal Links not working"
- ✅ Run `traceback.performDiagnostics()` to validate setup
- ✅ Verify Associated Domains in app entitlements
- ✅ Check URL scheme configuration in Info.plist
- ✅ Test with physical device (not simulator)

#### "Network connectivity issues"
- ✅ Verify `mainAssociatedHost` URL is accessible
- ✅ Check firewall/network restrictions
- ✅ Test with different network connection

### Debugging Tips

1. **Use Diagnostics**: Always run diagnostics during development
2. **Check Console**: Monitor os_log output for detailed information
3. **Test Scenarios**: Test both post-install and direct link scenarios
4. **Analytics**: Use the analytics events for debugging link detection

## Best Practices

### Security
- Always use HTTPS URLs for associated hosts
- Validate deep link URLs before navigation
- Don't log sensitive information

### Performance  
- Call `postInstallSearchLink()` only once per app launch
- Handle errors gracefully to avoid blocking app startup
- Use analytics events for monitoring and debugging

### Testing
- Test on physical devices for Universal Links validation
- Use different network conditions
- Test both fresh installs and existing app scenarios
- Verify clipboard functionality works as expected
