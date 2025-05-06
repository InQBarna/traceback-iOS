# Dark Launching w/ Firebase Dynamic Links

In order to double check Traceback results, it can be darklaunched and compared to 
firebase dynamic links performance. In the following example we will launch both
firebase dynamic links and Traceback, final decision will be based on firebase dynamic
links.

### Setup

1.- Disable firebase automatic launch by setting `FirebaseDeepLinkAutomaticRetrievalEnabled` to `false` in your plist.

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
            // 1.- Trigger a search for installation links
            //  in case a no-traceback link is found, it is returned as tracebackURL
            guard let tracebackURL = traceback.postInstallSearchLink(darkLaunchFirebaseDL) else {
                return
            }
            
            // 2.- Optional:  Send the right analytics in linkResult.analyticsEvents (optional).
            //  Both success and failure analytics are returned for reporting
            ANALYTICS
    
            // 3.- Grab any valid url and proceed to decode + opening the content
            // In dark launch mode, we recommend using firebase result 
            //  and traceback's result for comparison and debug only
            guard let linkURL = darkLaunchFirebaseDL ?? tracebackURL else {
                return
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
            viewModel.launchFirebaseDynamicLinksResolution()
        }
        .onOpenURL { url in
            // Receive here the resolution (or normal universal link of course)
            viewModel.proceed(onOpenURL: url)
        }
    }
}
```
