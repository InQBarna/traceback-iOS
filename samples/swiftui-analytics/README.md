# Traceback iOS + Firebase Analytics Sample

This sample demonstrates how to integrate **Traceback SDK** with **Firebase Analytics** to properly track campaign attribution in your iOS app.

## Overview

Traceback is essential for accurate attribution when users install your app through marketing campaigns. This sample shows the best practices for:

- Extracting UTM parameters from Traceback result URLs
- Sending campaign details to Firebase Analytics
- Properly tracking both post-install and campaign link flows

## What This Sample Does

1. **Integrates Traceback SDK** - Handles post-install link detection and campaign link resolution
2. **Extracts UTM Parameters** - Parses `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, and `utm_content` from Traceback URLs
3. **Logs to Firebase Analytics** - Sends `AnalyticsEventCampaignDetails` events with proper campaign attribution
4. **Displays Events** - Shows the analytics events in the UI for debugging

## Firebase Analytics Integration

The key integration happens in `AnalyticsHelper.swift`, which:

1. Extracts UTM parameters from the Traceback result URL
2. Maps them to Firebase Analytics parameters:
   - `utm_source` → `AnalyticsParameterSource`
   - `utm_medium` → `AnalyticsParameterMedium`
   - `utm_campaign` → `AnalyticsParameterCampaign`
   - `utm_term` → `AnalyticsParameterTerm`
   - `utm_content` → `AnalyticsParameterContent`
3. Logs the event using `Analytics.logEvent(AnalyticsEventCampaignDetails, parameters:)`

Reference: [Firebase Analytics Campaign Details](https://firebase.google.com/docs/reference/swift/firebaseanalytics/api/reference/Constants#analyticseventcampaigndetails)

## Setup Instructions

### 1. Firebase Configuration

**IMPORTANT**: This sample includes a **placeholder** `GoogleService-Info.plist` file. You must replace it with your own Firebase configuration:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add an iOS app to your Firebase project
4. Use bundle ID: `com.inqbarna.traceback.samples.analytics` (or update in Xcode)
5. Download your `GoogleService-Info.plist`
6. Replace the placeholder file at:
   ```
   TracebackAnalyticsExample/TracebackAnalyticsExample/GoogleService-Info.plist
   ```

**Security Note**: Never commit your actual `GoogleService-Info.plist` to version control. The `.gitignore` is already configured to exclude it.

### 2. Configure Associated Domains

Add your domain to the Associated Domains capability:

1. Open the project in Xcode
2. Select the target → Signing & Capabilities
3. Add or verify the Associated Domain:
   ```
   applinks:traceback-extension-samples-traceback.web.app
   ```

Or update `mainAssociatedHost` in `TracebackAnalyticsExampleApp.swift` to match your domain.

### 3. Build and Run

1. Open `TracebackAnalyticsExample.xcodeproj` in Xcode
2. Select your development team for code signing
3. Build and run on a physical device (recommended for testing)

## How It Works

### Post-Install Flow

1. User clicks a Traceback link with UTM parameters (e.g., from an ad campaign)
2. User installs the app
3. On first launch, `checkPostInstallLink()` is called
4. Traceback SDK detects the post-install link
5. `AnalyticsHelper.logCampaignFromURL()` extracts UTM parameters
6. Firebase Analytics receives the campaign attribution

### Campaign Link Flow

1. User clicks a Traceback link while app is installed
2. App opens via Universal Link
3. `handleOpenURL()` is called
4. Traceback SDK resolves the campaign link
5. `AnalyticsHelper.logCampaignFromURL()` extracts UTM parameters
6. Firebase Analytics receives the campaign attribution

## Testing

### Test Post-Install Attribution

1. Generate a Traceback link with UTM parameters:
   ```
   https://traceback-extension-samples-traceback.web.app/product?
   utm_source=facebook&utm_medium=cpc&utm_campaign=holiday_sale
   ```

2. Copy the link to clipboard
3. Delete the app from your device
4. Reinstall and launch the app
5. Check the UI for the detected campaign
6. Verify in Firebase Analytics DebugView (if enabled)

### Test Campaign Links

1. Send yourself a Traceback link via Messages or Email
2. Tap the link while the app is installed
3. Check the UI for the resolved campaign
4. Verify in Firebase Analytics DebugView

### Enable Firebase Analytics Debug Mode

To see events in real-time in Firebase Console:

1. In Xcode, edit the scheme
2. Add an argument: `-FIRAnalyticsDebugEnabled`
3. Run the app
4. Go to Firebase Console → Analytics → DebugView

## Key Files

- **`TracebackAnalyticsExampleApp.swift`** - App entry point with Firebase initialization
- **`AnalyticsHelper.swift`** - UTM parameter extraction and Firebase Analytics integration
- **`AppState+DeepLink.swift`** - Traceback SDK integration for post-install and campaign links
- **`ContentView.swift`** - UI displaying analytics events
- **`GoogleService-Info.plist`** - Firebase configuration (placeholder - replace with yours)

## Important Notes

### UTM Parameter Standards

Traceback works with standard UTM parameters:

- `utm_source` - Identifies the traffic source (e.g., "google", "facebook", "newsletter")
- `utm_medium` - Identifies the medium (e.g., "cpc", "email", "social")
- `utm_campaign` - Identifies the campaign name (e.g., "summer_sale", "product_launch")
- `utm_term` - Identifies paid search keywords (optional)
- `utm_content` - Differentiates similar content or links (optional)

### Firebase Analytics Best Practices

1. **Don't send PII** - Never include personally identifiable information in analytics
2. **Use consistent naming** - Keep campaign names consistent across platforms
3. **Test in DebugView** - Always verify events are being sent correctly
4. **Set user properties** - Consider setting user properties for better segmentation

## Viewing Campaign Data in Firebase Console

### Where to Find Your Campaign Attribution

Firebase Analytics for iOS apps handles attribution differently than web analytics:

#### 1. **User Properties** (Recommended)
The campaign UTM parameters are set as User Properties:

1. Go to Firebase Console → Analytics → Events
2. Click on any event (like `traceback_attribution`)
3. Click on a user to see their properties
4. Look for: `campaign`, `source`, `medium`, `term`, `content`

Or view directly:
- Firebase Console → Analytics → User Properties
- Filter by: `source`, `medium`, `campaign`

#### 2. **Custom Events**
View the `traceback_attribution` event:

1. Go to Firebase Console → Analytics → Events
2. Find the `traceback_attribution` event
3. Click to see all parameters including campaign details

#### 3. **DebugView** (Real-time)
For immediate verification:

1. Enable debug mode: `-FIRAnalyticsDebugEnabled` in Xcode scheme
2. Go to Firebase Console → Analytics → DebugView
3. Select your device
4. See events and user properties in real-time

**Important Note**: The "Source/Medium" in the main Firebase Analytics dashboard refers to automatic attribution (App Store, organic, etc.), NOT your custom UTM parameters. To see your Traceback campaign data, use User Properties or the custom `traceback_attribution` event.

## Troubleshooting

### Campaign Data Not Appearing

1. Verify `GoogleService-Info.plist` is your real Firebase configuration (not the placeholder)
2. Check that `IS_ANALYTICS_ENABLED` is `true` in GoogleService-Info.plist
3. Enable debug mode with `-FIRAnalyticsDebugEnabled`
4. Remember: Events may take 24 hours to appear in standard Firebase Analytics reports
5. Use DebugView for real-time verification
6. Check the Xcode console for `[Firebase Analytics] Campaign attribution set:` logs

### Traceback Link Not Detected

1. Ensure Associated Domains are properly configured
2. Verify the domain matches your Traceback configuration
3. Check Xcode console for Traceback SDK debug logs
4. For post-install: make sure clipboard access is enabled in TracebackConfiguration

## Learn More

- [Traceback Documentation](https://github.com/InQBarna/traceback-iOS)
- [Firebase Analytics for iOS](https://firebase.google.com/docs/analytics/get-started?platform=ios)
- [UTM Parameters Guide](https://en.wikipedia.org/wiki/UTM_parameters)

## License

See the LICENSE file in the root of the traceback-iOS repository.
