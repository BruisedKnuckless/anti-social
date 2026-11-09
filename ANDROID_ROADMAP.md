# Anti-Social Media — Android Roadmap (Flutter + Dart)

> **Goal:** A Flutter app that opens Instagram Web inside a WebView and injects CSS + JavaScript to hide distracting features (Reels, Stories, Explore, Suggested posts). You keep the feed, DMs, your profile and posting.
>
> **Scope:** Android only. **But the UI must look and behave the same as the iOS app**, so this roadmap is built on the same codebase, file names, scripts and design system as `AntiSocial_iOS_Roadmap.md`. Only the `android/` folder and a few WebView flags are Android-specific.

---

## Table of Contents

0. [The One Rule: Same UI on Both Platforms](#0-the-one-rule-same-ui-on-both-platforms)
1. [How the App Works](#1-how-the-app-works)
2. [Tech Stack](#2-tech-stack)
3. [Folder Structure (shared with iOS)](#3-folder-structure-shared-with-ios)
4. [Phase 0 — Setup](#phase-0--setup)
5. [Phase 1 — Design System (before any screen)](#phase-1--design-system-before-any-screen)
6. [Phase 2 — Instagram in a WebView](#phase-2--instagram-in-a-webview)
7. [Phase 3 — Find Selectors with Chrome DevTools](#phase-3--find-selectors-with-chrome-devtools)
8. [Phase 4 — Blocker Engine (CSS + JS)](#phase-4--blocker-engine-css--js)
9. [Phase 5 — URL Guard](#phase-5--url-guard)
10. [Phase 6 — Settings Sheet](#phase-6--settings-sheet)
11. [Phase 7 — Android Polish](#phase-7--android-polish)
12. [Phase 8 — Surviving Instagram Updates](#phase-8--surviving-instagram-updates)
13. [Phase 9 — Testing (incl. "same UI" checks)](#phase-9--testing-incl-same-ui-checks)
14. [Phase 10 — Build & Release](#phase-10--build--release)
15. [Gotchas](#gotchas)
16. [Milestones](#milestones)

---

## 0. The One Rule: Same UI on Both Platforms

Flutter draws its own UI, so making both platforms identical is very doable. But **some Flutter defaults quietly change based on the platform**. If you don't override them, the Android build will look slightly different from the iPhone build.

### 0.1 Things Flutter changes per platform (and how we lock them)

| Default that differs | iOS default | Android default | What we do |
|---|---|---|---|
| **Font** | San Francisco | Roboto | Bundle **one font** (e.g. Inter) in `assets/fonts/` and set it in the theme. Don't use `google_fonts` runtime downloads. |
| **AppBar title position** | Centered | Left-aligned | Set `centerTitle` explicitly in the theme (or don't use `AppBar` at all — build our own top bar). |
| **Back arrow icon** | `‹` (arrow_back_ios) | `←` (arrow_back) | Use our own `AppIcons.back` everywhere. |
| **Page transitions** | Slide from right | Fade/zoom up | Set the **same** `PageTransitionsBuilder` for both in `pageTransitionsTheme`. |
| **Scroll physics** (Flutter lists) | Bouncing | Clamping + stretch | Set one `ScrollBehavior` app-wide (pick bouncing *or* clamping, same on both). |
| **`.adaptive` widgets** (`Switch.adaptive`, etc.) | Cupertino look | Material look | **Never use `.adaptive`**. Use our own `AppSwitch`. |
| **Ripple / splash** | — | Ink ripple | Set one `splashFactory` (e.g. `NoSplash.splashFactory` or the same ripple on both). |
| **Text selection handles, dialogs** | Cupertino | Material | Use our own `AppDialog`; avoid `showAdaptiveDialog`. |
| **Status / navigation bar** | Notch + home indicator | Status bar + gesture/3-button bar | Edge-to-edge on Android, transparent bars, same `SafeArea` padding logic. |
| **Splash screen** | Image centered | Android 12+ forces a **circular** icon | Design the splash icon so it looks right inside a circle → reuse the same image on iOS. |
| **App icon** | Square, rounded by iOS | Adaptive (foreground + background layers) | One source design; generate both with `flutter_launcher_icons`. |

### 0.2 Code rules (stick these on the wall)

1. **No `Platform.isAndroid` / `Platform.isIOS` inside `lib/ui/` or `lib/screens/`.** Platform checks live only in `lib/platform/`.
2. **No raw Material/Cupertino widgets in screens** for things the user sees (switches, buttons, sheets, dialogs, toasts). Screens use `lib/ui/` components only.
3. **Every colour, size, radius, font comes from design tokens** (`lib/ui/tokens.dart`). No `Color(0xFF...)` in screens.
4. **One icon set** for the whole app (e.g. Material Symbols *or* Lucide, bundled). Never mix `Icons` and `CupertinoIcons`.
5. **Same haptics on both:** `HapticFeedback.selectionClick()` on toggles, nothing fancier.

### 0.3 What *can't* be identical (and that's okay)

| Difference | Why | How we handle it |
|---|---|---|
| Scrolling *inside* Instagram (bounce vs stretch) | It's the native WebView (WKWebView vs Chromium), not Flutter | Accept it. The **content** is identical because the injected CSS/JS is identical. |
| Back gesture | iOS = swipe from edge, Android = system back | Both go "back" in Instagram history; no visual difference. |
| File picker / camera sheet | Opened by the OS | Native on each, as users expect. |
| Instagram's own layout quirks per browser engine | Chrome vs Safari rendering | Test both side-by-side (Phase 9). Fix with CSS in the shared `blocker.css`. |

---

## 1. How the App Works

```
┌──────────────────────────── Flutter App (shared) ───────────────────────────┐
│                                                                             │
│  lib/ui/ (design system) ─► Settings Sheet ─► BlockerConfig (Dart)          │
│                                                   │                         │
│                                                   ▼                         │
│  ┌──────────── InAppWebView (Android: Chromium WebView / iOS: WKWebView) ─┐ │
│  │  1. Load https://www.instagram.com                                     │ │
│  │  2. At DOCUMENT START inject (same files on both platforms):           │ │
│  │       • window.__AS_CONFIG = {...}                                     │ │
│  │       • blocker.css  (toggled by classes on <html>)                    │ │
│  │       • blocker.js   (MutationObserver + SPA route hook)               │ │
│  │  3. URL Guard (Dart): /reels/, /explore/ → bounce home                 │ │
│  │  4. JS → Dart bridge: 'asEvent' handler                                │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Three layers of blocking:**

| Layer | What it does | Why |
|---|---|---|
| **CSS** | Hides elements instantly | No flicker |
| **JS (MutationObserver)** | Hides things that appear dynamically | Instagram is a React SPA |
| **URL Guard (Dart)** | Refuses to open blocked pages | Backup if CSS/JS misses something |

---

## 2. Tech Stack

Identical to iOS so the code is shared 1:1.

| Thing | Choice | Notes |
|---|---|---|
| Framework | Flutter (stable) | Same Flutter version on Mac + any other dev machine (pin it with `fvm` if you like) |
| WebView | `flutter_inappwebview` ^6.x | Document-start user scripts, URL interception, JS↔Dart handlers |
| Storage | `shared_preferences` | Toggle settings |
| State | `provider` | Same as iOS doc |
| Links | `url_launcher` | External links → Chrome |
| Icons / splash | `flutter_launcher_icons`, `flutter_native_splash` | One config generates both platforms |
| Font | Bundled `.ttf` (e.g. Inter) | Same on both, works offline |
| **Android min SDK** | **24 (Android 7.0)** | Safe for the WebView plugin |
| Android debugging | Chrome → `chrome://inspect` | Android's equivalent of Safari Web Inspector |

> ✅ Check pub.dev for latest versions. Use **the same versions** in iOS and Android work — it's one `pubspec.yaml`.

---

## 3. Folder Structure (shared with iOS)

Same names as the iOS roadmap, plus `ui/` (design system) and `platform/` (the only place platform checks are allowed).

```
anti_social/
├── assets/
│   ├── fonts/
│   │   └── Inter-*.ttf
│   ├── icons/                         # app icon + splash source images
│   └── inject/
│       ├── blocker.css                # SAME file for iOS + Android
│       ├── blocker.js                 # SAME file for iOS + Android
│       └── selectors.json             # selector data (can be fetched remotely later)
├── lib/
│   ├── main.dart
│   ├── app.dart                       # MaterialApp + AppTheme (locked defaults)
│   ├── ui/                            # ◀ design system — the "same UI" guarantee
│   │   ├── tokens.dart                # colours, spacing, radii, durations
│   │   ├── app_theme.dart             # ThemeData with every platform default overridden
│   │   ├── app_icons.dart             # one icon set
│   │   └── components/
│   │       ├── app_switch.dart
│   │       ├── app_button.dart
│   │       ├── app_sheet.dart         # bottom sheet used for settings
│   │       ├── app_dialog.dart
│   │       ├── app_toast.dart         # "Reels are blocked 🙂"
│   │       ├── app_fab.dart           # floating ⚙️ button
│   │       └── app_progress_bar.dart
│   ├── models/
│   │   └── blocker_config.dart
│   ├── services/
│   │   ├── settings_service.dart
│   │   └── script_builder.dart
│   ├── screens/
│   │   ├── web_screen.dart            # InAppWebView + URL guard
│   │   ├── settings_sheet.dart
│   │   └── error_screen.dart          # offline / retry
│   ├── platform/                      # ◀ ONLY place with Platform.isAndroid/isIOS
│   │   ├── webview_settings.dart      # per-platform WebView flags
│   │   └── system_ui.dart             # status/nav bar setup
│   └── utils/
│       └── url_rules.dart
├── android/                           # Android-only config (manifest, gradle, signing)
├── ios/                               # iOS-only config (Info.plist, Podfile)
├── test/
│   ├── url_rules_test.dart
│   └── golden/                        # screenshot tests run as Android AND iOS
└── pubspec.yaml
```

---

## Phase 0 — Setup

**⏱ ~½ day**

- [ ] Install Android Studio → Android SDK, platform-tools, an emulator (Pixel, API 34+)
- [ ] `flutter doctor` → Android section ✅
- [ ] Use **the same project** as iOS (create once):
  ```bash
  flutter create --org com.viraj --platforms=ios,android anti_social
  ```
  Package ID ends up `com.viraj.anti_social` — change Android `applicationId` to `com.viraj.antisocial` to match the iOS Bundle ID.
- [ ] `android/app/build.gradle` → `minSdk = 24`
- [ ] `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- [ ] Phone: enable **Developer options → USB debugging**, run `flutter run`

**✅ Done when:** the default counter app runs on your Android phone.

---

## Phase 1 — Design System (before any screen)

**⏱ ~1–2 days — do this FIRST, it's what makes both apps match**

### 1.1 Tokens (`lib/ui/tokens.dart`)
- [ ] Colours for light + dark (background, surface, text, accent, danger)
- [ ] Spacing scale (4, 8, 12, 16, 24, 32)
- [ ] Radii (8, 12, 20), animation durations (150 ms, 250 ms)
- [ ] Text styles (title, body, caption) using the bundled font

### 1.2 Theme (`lib/ui/app_theme.dart`) — lock every platform default
- [ ] `fontFamily: 'Inter'`
- [ ] `appBarTheme: AppBarTheme(centerTitle: true, ...)`
- [ ] Same transition on both:
  ```dart
  pageTransitionsTheme: const PageTransitionsTheme(builders: {
    TargetPlatform.android: CupertinoPageTransitionsBuilder(), // or FadeUpwards for both
    TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
  }),
  ```
- [ ] `splashFactory` set explicitly
- [ ] App-wide `ScrollBehavior` with the same physics on both
- [ ] `useMaterial3: true` and define `colorScheme` fully from tokens (don't rely on generated defaults)

### 1.3 Components (`lib/ui/components/`)
- [ ] `AppSwitch`, `AppButton`, `AppSheet`, `AppDialog`, `AppToast`, `AppFab`, `AppProgressBar`
- [ ] Each one is built from basic widgets + tokens (no `.adaptive`, no Cupertino-vs-Material branching)

### 1.4 System UI (`lib/platform/system_ui.dart`)
- [ ] Android: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` + transparent status & navigation bars → looks like iOS's full-screen layout
- [ ] Both: status bar icon colour follows light/dark mode via `AnnotatedRegion<SystemUiOverlayStyle>`

### 1.5 Quick visual check
- [ ] Build a throwaway "gallery" screen that shows every component. Run it on Android + iOS simulator **side by side**. They should look the same before you move on.

---

## Phase 2 — Instagram in a WebView

**⏱ ~1 day**

### 2.1 Shared screen (`lib/screens/web_screen.dart`)
Same code as the iOS doc. The only difference is where settings come from:

```dart
InAppWebView(
  initialUrlRequest: URLRequest(url: WebUri('https://www.instagram.com/')),
  initialSettings: PlatformWebViewSettings.build(), // from lib/platform/
  initialUserScripts: UnmodifiableListView(scripts),
  onWebViewCreated: (c) => _controller = c,
)
```

### 2.2 Per-platform flags (`lib/platform/webview_settings.dart`)
One `InAppWebViewSettings` object; the plugin ignores flags that don't apply to a platform.

```dart
InAppWebViewSettings(
  // shared
  javaScriptEnabled: true,
  mediaPlaybackRequiresUserGesture: true,
  isInspectable: kDebugMode,
  useShouldOverrideUrlLoading: true,
  // Android
  domStorageEnabled: true,
  databaseEnabled: true,
  supportMultipleWindows: false,
  // iOS
  allowsInlineMediaPlayback: true,
  allowsBackForwardNavigationGestures: true,
  sharedCookiesEnabled: true,
  userAgent: Platform.isIOS ? iosSafariUA : null, // see note
)
```

> **User agent note:** The iOS doc uses a Safari UA. On Android, start with the **default WebView UA**. If Instagram shows a different layout or "open in app" walls on Android, try removing the `; wv` token from the default UA. Don't fake an iPhone UA on Android — it causes App Store links and can trigger "suspicious login" checks.

### 2.3 Android back button
- [ ] Wrap in `PopScope(canPop: false, onPopInvokedWithResult: ...)` → if `await controller.canGoBack()` then `goBack()`, else close the app
- [ ] This is the Android counterpart of iOS swipe-back — same result, no UI change

### 2.4 Layout
- [ ] `SafeArea` + background colour from tokens (no white flash in dark mode)
- [ ] Thin `AppProgressBar` at top using `onProgressChanged`

**✅ Done when:** you can log in, kill the app, reopen, and you're still logged in (Android's `CookieManager` persists cookies automatically).

---

## Phase 3 — Find Selectors with Chrome DevTools

**⏱ ~1 day**

Android's version of Safari Web Inspector:

1. Run the app in debug on your phone (USB connected)
2. Laptop Chrome → `chrome://inspect` → under your device click **inspect** next to instagram.com
3. You now have full DevTools for the page *inside your app*

For each feature, confirm the selectors from the iOS doc **also work on Android** (Instagram may serve slightly different markup to Chrome vs Safari):

| Feature | Selector ideas (verify!) | Works on Android? | Works on iOS? |
|---|---|---|---|
| Reels nav tab | `a[href="/reels/"]` | ☐ | ☐ |
| Reel links | `a[href*="/reel/"]` | ☐ | ☐ |
| Explore tab | `a[href="/explore/"]` | ☐ | ☐ |
| Stories tray | container around `a[href*="/stories/"]` | ☐ | ☐ |
| Suggested posts | text match in JS | ☐ | ☐ |
| "Open in app" banner | fixed-position banner | ☐ | ☐ |

> ⚠️ Never use Instagram's generated class names (`x1n2onr6…`). Use `href`, `aria-label`, `role`, structure.
>
> If a selector only works on one platform, **find one that works on both** rather than branching. Keep `blocker.css` and `blocker.js` identical for both platforms.

---

## Phase 4 — Blocker Engine (CSS + JS)

**⏱ ~3–4 days**

**Use the exact same `blocker.css`, `blocker.js` and `script_builder.dart` as the iOS roadmap (Phase 2 there).** In short:

- [ ] `blocker.css` → rules scoped by classes on `<html>` (`html.as-block-reels a[href="/reels/"] {display:none!important}`) so toggles are a class flip
- [ ] `blocker.js` →
  - guard `window.__AS_LOADED` (stops double-running)
  - read `window.__AS_CONFIG`
  - `applyClasses()` on `<html>`
  - `sweep()` for dynamic stuff (reels posts in feed, stories tray tagging)
  - hook `history.pushState` / `replaceState` + `popstate` → `onRoute()`
  - throttled `MutationObserver` (via `requestAnimationFrame`)
  - `window.__AS_UPDATE(newCfg)` for live toggles
  - `notify()` → `flutter_inappwebview.callHandler('asEvent', …)`
- [ ] `script_builder.dart` → three `UserScript`s at `AT_DOCUMENT_START`: config, CSS injector, JS. Set `forMainFrameOnly: true`.
- [ ] Register the `asEvent` JavaScript handler in `onWebViewCreated`

**Android-specific checks:**
- [ ] Confirm user scripts really run at document start on Android (check with a `console.log` in `chrome://inspect`)
- [ ] If CSS appears a moment late on Android, also inject the CSS again in `onLoadStart` as a fallback
- [ ] iOS has native **Content Blockers**; treat them as an *extra* layer only. The CSS/JS layer must work on its own so Android gets the same result.

**✅ Done when:** Reels tab, Explore tab and Stories tray are gone, with no flash on launch — and it looks the same as on the iPhone.

---

## Phase 5 — URL Guard

**⏱ ~1 day — same Dart code as iOS (`lib/utils/url_rules.dart`)**

| Hook | Catches |
|---|---|
| `shouldOverrideUrlLoading` | Link taps, full loads, app schemes |
| `onUpdateVisitedHistory` | SPA route changes (`pushState`) |

Rules (shared):

| URL | Action |
|---|---|
| Allowed `instagram.com` paths | ✅ Allow |
| `/reels/`, `/reel/`, `/explore/` (when blocked) | ❌ Cancel → `AppToast("Reels are blocked 🙂")` |
| `instagram://…` | ❌ Cancel |
| **`intent://…`** *(Android only)* | ❌ Cancel — this is how Android web pages try to open the native Instagram app |
| `facebook.com`, `cdninstagram.com`, login pages | ✅ Allow |
| Anything else | 🌐 `launchUrl(..., mode: externalApplication)` → Chrome |

- [ ] Add `intent` to the blocked schemes list in `url_rules.dart` (harmless on iOS)
- [ ] Unit test `isBlockedPath()` and `classifyUrl()`

**✅ Done when:** a reel shared in DMs won't open, `/reels/` bounces home, bio links open in Chrome.

---

## Phase 6 — Settings Sheet

**⏱ ~2 days — same UI as iOS**

- [ ] `BlockerConfig` model — identical to iOS (`blockReels`, `blockStories`, `blockExplore`, `blockSuggested` + `toJson/fromJson/copyWith`)
- [ ] Open via `AppFab` (floating ⚙️) → `AppSheet` with `AppSwitch` rows
- [ ] Flow:
  ```
  toggle → save (shared_preferences) → Provider notifies WebScreen
        → evaluateJavascript('window.__AS_UPDATE(...)')   // live
        → removeAllUserScripts() + addUserScripts(...)     // next load
  ```
- [ ] Optional **friction mode**: turning a block OFF needs a 10 s countdown / typing a sentence (same component on both platforms)
- [ ] Keep the WebView alive while the sheet is open (it's a sheet over the WebView, not a new route → no reload)

**✅ Done when:** toggles persist, update the page live, and the sheet looks identical on both phones.

---

## Phase 7 — Android Polish

**⏱ ~2 days**

| Item | Android detail | Shared UI piece |
|---|---|---|
| Pull to refresh | `PullToRefreshController` (colour from tokens) | ✅ same |
| Photo/video upload | Plugin handles `<input type=file>`; add `CAMERA` permission if you want camera capture | OS picker (native) |
| Login popups | `supportMultipleWindows: false` keeps FB login in the same view; if needed handle `onCreateWindow` like iOS | — |
| "Open in app" banners | Hide in shared `blocker.css` | ✅ same |
| Offline | `onReceivedError` → `error_screen.dart` | ✅ same |
| Dark mode | Follow system; token colours | ✅ same |
| Edge-to-edge | From Phase 1.4; test gesture nav **and** 3-button nav | ✅ same |
| App icon | `flutter_launcher_icons` → adaptive icon (`adaptive_icon_foreground` + background colour) | same artwork |
| Splash | `flutter_native_splash` with `android_12` section (circle-safe icon) | same artwork |
| Release safety | `isInspectable: kDebugMode` | — |

---

## Phase 8 — Surviving Instagram Updates

Same strategy as iOS:

1. All selectors in **one** place (`selectors.json` / one JS object)
2. Health check: JS reports `selector_missing` via `asEvent`
3. **Remote selectors (later):** fetch a JSON file of selector strings + URL patterns from GitHub at launch; fall back to the bundled one
   > Keep it **data only** (no remote JS) — required for iOS App Store, and it keeps both platforms on the same rules
4. URL Guard is the safety net when selectors break

---

## Phase 9 — Testing (incl. "same UI" checks)

### 9.1 Same-UI checks
- [ ] **Golden tests:** render each screen/component with `debugDefaultTargetPlatformOverride = TargetPlatform.android` and again with `TargetPlatform.iOS`. Both must match the **same** golden image. If they differ, a platform default leaked through.
- [ ] **Side-by-side review:** Android phone + iPhone on the desk, go through every screen together (settings sheet, toast, error screen, splash, icon).
- [ ] `grep -rn "Platform.is" lib/ui lib/screens` → should return **nothing**
- [ ] `grep -rn "adaptive\|Cupertino" lib/ui lib/screens` → should return **nothing** (except the deliberate transition builder in the theme)

### 9.2 Functional checklist (Android)
| # | Test | Expected |
|---|---|---|
| 1 | Fresh install → login (password, FB, 2FA) | Works, persists |
| 2 | Bottom nav | No Reels / Explore |
| 3 | Home feed | No stories, reels posts hidden |
| 4 | Profile → Reels tab | Hidden / blocked |
| 5 | Reel in DM | Blocked + toast |
| 6 | `intent://` / `instagram://` link | Nothing opens |
| 7 | Toggle Reels off | Shows without restart |
| 8 | Upload a post | Picker opens, upload works |
| 9 | Bio link | Opens in Chrome |
| 10 | Airplane mode | Error screen + retry |
| 11 | Back button | Goes back in IG history, exits at home |
| 12 | 5 min scroll | No lag, no heat |
| 13 | Gesture nav + 3-button nav | Layout correct on both |

### 9.3 Devices
- Real Android phone (most important)
- Emulators: one small screen, one large, API 24 and latest

---

## Phase 10 — Build & Release

- [ ] Signing key + `android/key.properties` (add to `.gitignore`!)
- [ ] Same version number as iOS in `pubspec.yaml` (`1.0.0+1`) — both platforms ship together
- [ ] Build:
  ```bash
  flutter build apk --release        # sideload / GitHub Releases
  flutter build appbundle --release  # Play Store
  ```
- [ ] Distribution: start with a sideloaded APK (like TestFlight on iOS). Play Store later.

---

## Gotchas

| Problem | Fix |
|---|---|
| Android UI looks "more Material" than iOS | A default leaked — check font, `centerTitle`, transitions, `.adaptive` widgets (Section 0.1) |
| Selector works on iPhone but not Android | Instagram served different markup to Chrome; find a selector that works on both |
| Tapping links opens the real Instagram app | Block `intent://` and `instagram://` schemes |
| Blocked content flashes | CSS at document start + `onLoadStart` fallback |
| Reels still open in-app | Need `onUpdateVisitedHistory` + JS `pushState` hook |
| Logged out on launch | Don't clear cookies/cache; no incognito mode |
| Play Store rejection | Don't use "Instagram" in name/icon; add real value (toggles, friction mode, stats) |
| Native Instagram still installed | Your blocker is pointless if it's one tap away — nudge users to uninstall |

---

## Milestones

| # | Deliverable | Est. |
|---|---|---|
| **A0** | Android toolchain + app runs on phone | Day 1 |
| **A1** | Design system + component gallery matches iOS side-by-side | Day 2–3 |
| **A2** | Instagram loads, login persists, `chrome://inspect` working | Day 4 |
| **A3** | Shared blocker CSS/JS working on Android | Week 2 |
| **A4** | URL guard incl. `intent://` | Week 2 |
| **A5** | Settings sheet with live toggles | Week 2–3 |
| **A6** | Polish + golden tests passing for both platforms | Week 3 |
| **A7** | Signed release APK 🎉 | Week 3–4 |

---

### Order to start (when you're ready)
1. Phase 0 → app on the phone
2. **Phase 1 → design system first** (this is what keeps iOS and Android identical)
3. Phase 2 → Instagram loads + `chrome://inspect`
4. Phase 3 → check the iOS selectors on Android
5. Phase 4 onwards
