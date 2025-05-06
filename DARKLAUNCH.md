# Dark Launching w/ Firebase Dynamic Links

In order to double check Traceback results, it can be darklaunched and compared to 
firebase dynamic links performance. In the following example we will launch both
firebase dynamic links and Traceback, final decision will be based on firebase dynamic
links.

## SwiftUI

### Setup

1.- In order to launch firebase dynamic link resolution exactly when desired, disable firebase automatic launch by setting `FirebaseDeepLinkAutomaticRetrievalEnabled` to `false` in your plist.

2.- Then, the firebase dynamic link resolution is disabled, see how to launch it manually

```swift
import FirebaseDynamicLinks

final class PreLandingViewModel: ObservableObject {
    /* ... */
    private var grabbedClipboardURL: URL?
    func launchFirebaseDynamicLinksResolution() {
        guard let dynamicLinks = DynamicLinks
           .perform(#selector(DynamicLinks.dynamicLinks))?
           .takeUnretainedValue() as? DynamicLinks,
           dynamicLinks.responds(to: Selector(("checkForPendingDynamicLink"))) else {
           throw "Dynamic links library not found or changed"
        }
        grabbedClipboardURL = UIPasteboard.general.url
        dynamicLinks.perform(Selector(("checkForPendingDynamicLink")))
    }
}
```

3.- Receive firebase dynamic links resolution in SwiftUI

```swift
import FirebaseDynamicLinks

final class PreLandingViewModel: ObservableObject {
    /* ... */
    
    // This method is to be called from onOpenURL
    func proceed(
        onOpenURL: URL
    ) {
        let darkLaunchFirebaseDL = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)?.url
        Task {
            // 2.- Search for post-install link and proceed if available
            let darkLaunchInfo = DarkLaunchInfo {
                darkLaunchDetectedLink: darkLaunchFirebaseDL,
                previouslyGrabbedClipboard: viewModel.grabbedClipboardURL
            }
            guard let tracebackURL = traceback.postInstallSearchLink(darkLaunchFirebaseDL)?.url else {
                return
            }
            
            // 3.- Grab the correct url
            //  URL is either a post-install link (detected after app download on onAppear),
            //  or an opened url (direct open in installed app)
            guard let linkResult = try? traceback.extractLinkFromURL(url) else {
                return assertionFailure("Could not find a valid traceback/universal url in \(url)")
            }
            
            // 4.- Handle the url, opening the right content indicated by linkURL
            YOUR CODE HERE
        }
    }
}

struct PreLandingView: View {
    @ObservedObject var viewModel: PreLandingViewModel
    var body: some View {
        /* ... */
        .onAppear {
            // 1.- Launch firebase resolution
            viewModel.launchFirebaseDynamicLinksResolution()
        }
        .onOpenURL { url in
            // Receive here the resolution of firebase dyn links
            //  or normal universal link of course
            viewModel.proceed(onOpenURL: url)
        }
    }
}
```
