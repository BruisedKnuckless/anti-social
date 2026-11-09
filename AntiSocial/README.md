# AntiSocial: Instagram without Reels (prototype)

A SwiftUI prototype that:

1. **Shows Instagram without the addictive parts.** It loads instagram.com in a `WKWebView` and injects a filter that:
   - removes the Reels tab and redirects the Reels feed (`/reels/`) to Home
   - replaces the Explore grid with plain Search (`/explore/search/`)
   - hides "Suggested for you", suggested reels and Sponsored posts in the feed
   - keeps DMs, stories, profiles, posting and single reels friends send you (`/reel/<id>`)
2. **Blocks the native Instagram app** (optional) with Apple's Screen Time shield
   (FamilyControls + ManagedSettings), so you're nudged back to the reel-free version.

## Files
| File | What it does |
|---|---|
| `App/AntiSocialApp.swift` | App entry, main screen with the web view and toolbar, block settings sheet |
| `App/InstagramWebView.swift` | WKWebView setup, navigation guard (redirects, stops `instagram://` app jumps) |
| `App/InstagramFilter.swift` | All filter rules: Swift URL rules and the injected JS. **Edit this when Instagram changes** |
| `App/AppBlocker.swift` | Screen Time authorization, app picker selection, shield on/off |
| `project.yml` | XcodeGen spec that generates the Xcode project |

## Run it

### Option A: XcodeGen (fastest)
```bash
brew install xcodegen
cd AntiSocial
# put your Team ID in project.yml (Xcode → Settings → Accounts → your team, or developer.apple.com → Membership)
xcodegen
open AntiSocial.xcodeproj
```

### Option B: manual
1. In Xcode: File → New → Project → iOS App, named `AntiSocial`, Interface SwiftUI. Set the deployment target to iOS 16.6.
2. Delete the generated `ContentView.swift` and `AntiSocialApp.swift`, then drag the four `.swift` files from `App/` in.
3. Go to Signing & Capabilities → **+ Capability → Family Controls**.

### Then
- Select your **iPhone** as the run destination. The Instagram browser works in the Simulator, but the Screen Time picker and shield only work on a real device.
- Press **Run**, log into Instagram, and the Reels tab is gone.
- Tap the shield icon (top right) → Allow Screen Time access → choose Instagram → toggle **Block**.
  Opening the real Instagram app now shows the Screen Time block screen.

## Notes and limits
- **Family Controls entitlement:** works for development builds on your own device. To ship on the App Store, request the
  *Family Controls (Distribution)* entitlement from Apple first.
- **Fragile by nature:** Instagram changes its web markup. If Reels or suggested posts reappear, update `InstagramFilter.swift`.
  Debug by enabling Safari → Develop → [your iPhone] → AntiSocial to inspect the page.
- **Easy to bypass in this prototype:** you can just turn the toggle off. Ideas for v2:
  Hard Mode (locked for N hours), Post Mode (10-minute unlock via a DeviceActivity monitor extension),
  a custom shield screen (ShieldConfiguration extension), and a "Messages only" mode.
- Uses its own name and branding. Don't reuse another app's name or icon if you publish this.
