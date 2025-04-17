# Usage

## Installation

Install the firebase extension into your firebase project. TODO: link

In your iOS app:

1. Install this companion sdk using SPM
```swift
https://github.com/InQBarna/firebase-backtrace-extension
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

let config = TracebackConfiguration(
    associatedDomains: ["my-firebase-project-traceback.firebaseapp.com"],
    firebaseProjectId: "my-firebase-project",
    region: "us-central1"
    useClipboard: true,
    logLevel: .error
)
let traceback = Traceback.live(configuration: config)
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
            // Trigger a search for installation links
            //  if a link is found successfully, it will be triggered to openURL below
            viewModel.traceback.postInstallSearchLink()
        }
        .onOpenURL { url in
            // URL is either a post-install link (detected after app download on onAppear above),
            //  or an opened url (direct open in installed app)
            guard let linkResult = try? viewModel.traceback.extractLinkFromURL(url) else {
                return assertionFailure("Could not find a valid traceback/universal url in \(url)")
            }
            // Send the right analytics in linkResult.analyticsEvents (optional).
            //  Both success and failure analytics are reported
            guard let linkURL = linkResult.url else {
                return assertionFailure("Could not find a valid traceback/universal url in \(url)")
            }
            // Handle the url, opening the right content indicated by linkURL
            YOUR CODE HERE
        }
    }
}
```

### UIKit

```swift

@MainActor
class YourAppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Trigger a search for installation links
        //  if a link is found successfully, it will be triggered to openURL (see next section)
        traceback.postInstallSearchLink()
        return true
    }

    /* ... */

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        // URL is either a post-install link (detected after app download on onAppear above),
        //  or an opened url (direct open in installed app)
        guard let linkResult = try? traceback.extractLinkFromURL(url) else {
            assertionFailure("Could not find a valid traceback/universal url in \(url)")
            return false
        }
        // Send the right analytics in linkResult.analyticsEvents (optional).
        //  Both success and failure analytics are reported
        guard let linkURL = linkResult.url else {
            assertionFailure("Could not find a valid traceback/universal url in \(url)")
            return false
        }
        // Handle the url, opening the right content indicated by linkURL
        YOUR CODE HERE
        return true
    }
}
```
