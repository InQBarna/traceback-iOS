# Quick Start: Traceback + Firebase Analytics

Get up and running with Traceback and Firebase Analytics in 5 minutes.

## Prerequisites

- Xcode 15.0+
- iOS 15.0+ device (physical device recommended for testing)
- Firebase account

## Step 1: Firebase Setup (2 minutes)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select existing project
3. Click "Add app" → iOS
4. Enter bundle ID: `com.inqbarna.traceback.samples.analytics`
5. Download `GoogleService-Info.plist`
6. Replace the placeholder file:
   ```
   TracebackAnalyticsExample/TracebackAnalyticsExample/GoogleService-Info.plist
   ```

## Step 2: Xcode Setup (1 minute)

1. Open `TracebackAnalyticsExample.xcodeproj`
2. Select the target
3. Go to "Signing & Capabilities"
4. Select your development team
5. Verify Associated Domain is set:
   ```
   applinks:traceback-extension-samples-traceback.web.app
   ```

## Step 3: Build and Run (1 minute)

1. Connect your iOS device
2. Select your device in Xcode
3. Click Run (⌘R)

## Step 4: Test It (1 minute)

### Quick Test - Campaign Link

1. In Safari on your iOS device, open this link:
   ```
   https://traceback-extension-samples-traceback.web.app/product?utm_source=test&utm_medium=quickstart&utm_campaign=demo
   ```

2. The app should open and display:
   - ✅ "Campaign link resolved!"
   - The campaign parameters in the Analytics Events section

### Full Test - Post-Install

1. Generate a Traceback link (with UTM parameters)
2. Copy it to clipboard
3. Delete the app
4. Reinstall from Xcode
5. Launch the app
6. Check for "Post-install link detected!"

## Step 5: Verify in Firebase (Optional)

### Enable Debug Mode

1. In Xcode, edit the scheme (Product → Scheme → Edit Scheme)
2. Go to Run → Arguments
3. Add: `-FIRAnalyticsDebugEnabled`
4. Run the app again

### View Events

1. Go to Firebase Console
2. Click Analytics → DebugView
3. Select your device
4. Trigger a campaign link
5. See the `campaign_details` event appear in real-time

## What Just Happened?

1. **Traceback SDK** detected the campaign link
2. **AnalyticsHelper** extracted the UTM parameters:
   - `utm_source=test`
   - `utm_medium=quickstart`
   - `utm_campaign=demo`
3. **Firebase Analytics** logged the event with campaign attribution

## Next Steps

- Review the code in `AnalyticsHelper.swift` to understand UTM extraction
- Try different UTM parameters
- Check Firebase Analytics reports (available after 24 hours)
- Integrate this pattern into your own app

## Common Issues

### "Not a Traceback URL" message

- Make sure the link domain matches your configured `mainAssociatedHost`
- Verify Associated Domains in capabilities

### Events not in Firebase Console

- Wait 24 hours for reports (or use DebugView for real-time)
- Verify you replaced the placeholder `GoogleService-Info.plist`
- Check that `IS_ANALYTICS_ENABLED` is `true` in your plist

### Post-install not working

- Use a physical device (not simulator)
- Make sure you actually deleted and reinstalled the app
- Check that clipboard contains a valid Traceback URL before reinstalling

## Learn More

See the full [README.md](./README.md) for detailed documentation.
