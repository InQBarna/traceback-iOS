# Usage

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
        associatedDomains: ["my-firebase-project-traceback.firebaseapp.com"],
        firebaseProjectId: "my-firebase-project",
        region: "us-central1"
        useClipboard: true,
        logLevel: .error
    )
    return Traceback.live(configuration: config)
}()
```

### SwiftUI

We recommend grabbing and handling links within your root SwiftUI view. Choose the right
 root view, where you can handle deep navigations. See the example implementation below

```swift

final class PreLandingViewModel: ObservableObject {
    /* ... */
    
    func searchPostInstall() {
        Task {
        }
    }
    
}

struct PreLandingView: View {
    @ObservedObject var viewModel: PreLandingViewModel
    var body: some View {
        /* ... */
        .onAppear {
            Task {
                // 1.- Trigger a search for installation links
                //  if a link is found successfully, it will be sent to proceed(openURL:) below
                guard let tracebackURL = traceback.postInstallSearchLink() else {
                    return
                }
                
                // 2.- Optional:  Send the right analytics in linkResult.analyticsEvents (optional).
                //  Both success and failure analytics are returned for reporting
                ANALYTICS
        
                // 3.- Grab any valid url and proceed to decode + opening the content
                guard let linkURL = linkResult.url else {
                    return
                }
                proceed(onOpenURL: tracebackURL)
            }
        }
        .onOpenURL { url in
            proceed(onOpenURL: url)
        }
    }
    
    // This method is to be called from onOpenURL or after post install link search
    func proceed(
        onOpenURL: URL
    ) {
        // 4.- Decode a valid url
        // URL is either a post-install link (detected after app download on onAppear above),
        //  or an opened url (direct open in installed app)
        guard let linkResult = try? traceback.extractLinkFromURL(url) else {
            return assertionFailure("Could not find a valid traceback/universal url in \(url)")
        }
        
        // 5.- Handle the url, opening the right content indicated by linkURL
        YOUR CODE HERE
    }
}
```

### UIKit

```swift

@MainActor
class YourAppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Task {
            // 1.- Trigger a search for installation links
            //  if a link is found successfully, it will be sent to proceed(openURL:) below
            guard let tracebackURL = traceback.postInstallSearchLink() else {
                return
            }
            
            // 2.- Optional:  Send the right analytics in linkResult.analyticsEvents (optional).
            //  Both success and failure analytics are returned for reporting
            ANALYTICS
    
            // 3.- Grab any valid url and proceed to decode + opening the content
            guard let linkURL = linkResult.url else {
                return
            }
            proceed(onOpenURL: tracebackURL)
        }
        return true
    }

    /* ... */

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        // 4.- Decode a valid url
        // URL is either a post-install link (detected after app download on onAppear above),
        //  or an opened url (direct open in installed app)
        guard let linkResult = try? traceback.extractLinkFromURL(url) else {
            assertionFailure("Could not find a valid traceback/universal url in \(url)")
            return false
        }
        
        // 5.- Handle the url, opening the right content indicated by linkURL
        YOUR CODE HERE
        return true
    }
}
```

## Dark Launching w/ Firebase Dynamic Links

In order to double check Traceback results, it can be darklaunched and compared to 
firebase dynamic links performance. In the following example we will launch both
firebase dynamic links and Traceback, final decision will be based on firebase dynamic
links.

Check [Dark Launch Guide](DARKLAUNCH.md).

