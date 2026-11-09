# Anti-Social Media — iOS Implementation Roadmap (Flutter + Dart)

> **Goal:** An iOS app that opens Instagram Web inside a WebView and injects JavaScript + CSS to hide/block distracting features (Reels, Stories, Explore, etc.) while keeping the useful parts (feed from people you follow, DMs, profile, posting).
>
> **Scope of this doc:** iOS implementation. The Flutter/Dart code will be shared with Android later, but everything here is tested and tuned for iPhone.
>
> 🎯 **Hard rule: the UI must look and behave identically on iOS and Android.** Every UI decision in this roadmap follows the [UI Parity Plan](#3-ui-parity-plan-same-ui-on-ios--android). When the iOS build is done, the Android build should need only platform config, not UI changes.

---

## Table of Contents

1. [How the App Works (Big Picture)](#1-how-the-app-works-big-picture)
2. [Tech Stack & Key Decisions](#2-tech-stack--key-decisions)
3. [UI Parity Plan (Same UI on iOS & Android)](#3-ui-parity-plan-same-ui-on-ios--android)
4. [Phase 0 — Setup the Mac & Project](#phase-0--setup-the-mac--project)
5. [Phase 0.5 — Shared Design System](#phase-05--shared-design-system)
6. [Phase 1 — Basic Instagram WebView](#phase-1--basic-instagram-webview)
7. [Phase 2 — Inject CSS & JS (the Blocker Engine)](#phase-2--inject-css--js-the-blocker-engine)
8. [Phase 3 — Block Navigation to Reels (URL Guard)](#phase-3--block-navigation-to-reels-url-guard)
9. [Phase 4 — Settings Screen (Feature Toggles)](#phase-4--settings-screen-feature-toggles)
10. [Phase 5 — iOS Polish (Login, Uploads, Links, Gestures)](#phase-5--ios-polish-login-uploads-links-gestures)
11. [Phase 6 — Making Selectors Survive Instagram Updates](#phase-6--making-selectors-survive-instagram-updates)
12. [Phase 7 — Testing](#phase-7--testing)
13. [Phase 8 — TestFlight & App Store](#phase-8--testflight--app-store)
14. [Folder Structure](#folder-structure)
15. [Common Pitfalls & Fixes](#common-pitfalls--fixes)
16. [Milestone Checklist](#milestone-checklist)

---

## 1. How the App Works (Big Picture)

```
┌──────────────────────────── Flutter App ────────────────────────────┐
│                                                                     │
│  Settings (toggles)  ──►  BlockerConfig (Dart)                       │
│                               │                                     │
│                               ▼                                     │
│  ┌──────────────── InAppWebView (WKWebView on iOS) ───────────────┐ │
│  │                                                                │ │
│  │  1. Load https://www.instagram.com                             │ │
│  │  2. At DOCUMENT START inject:                                  │ │
│  │       • config  (window.__AS_CONFIG = {...})                   │ │
│  │       • CSS     (hide reels tab, stories tray, etc.)           │ │
│  │       • JS      (MutationObserver + SPA route watcher)         │ │
│  │  3. URL Guard: if URL → /reels/ or /explore/  → bounce home    │ │
│  │  4. JS ⇄ Dart bridge (JS can report "blocked X" to Dart)       │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Three layers of blocking (defence in depth):**

| Layer | What it does | Why it's needed |
|---|---|---|
| **CSS** | Instantly hides elements (`display:none`) | Fast, no flicker |
| **JS (MutationObserver)** | Finds & removes elements CSS can't target reliably | Instagram is a React app; content appears dynamically |
| **URL Guard (Dart)** | Stops navigation to `/reels/`, `/explore/` etc. | Even if a button slips through, the page can't open |

---

## 2. Tech Stack & Key Decisions

| Thing | Choice | Reason |
|---|---|---|
| Framework | **Flutter (stable channel)** | Cross-platform, one codebase |
| WebView | **`flutter_inappwebview` (v6.x)** | Supports **user scripts at document start**, iOS **content blockers**, JS↔Dart handlers, `onUpdateVisitedHistory`, custom user agent. The official `webview_flutter` is too limited for this. |
| Local storage | `shared_preferences` | Store toggle settings |
| State management | `provider` or `riverpod` (keep it simple — `provider` is fine) | Settings → WebView updates |
| UI widgets | **Our own design system** on top of Material 3, with a fixed `ThemeData.platform` | Same look on both OSes (see UI Parity Plan) |
| Font | **Bundled font** (e.g. Inter) | Stops iOS using San Francisco and Android using Roboto |
| Icons | **One bundled icon set** (e.g. `lucide_icons` or Material Symbols) | No `CupertinoIcons` on one platform and Material on the other |
| Splash & icon | `flutter_native_splash` + `flutter_launcher_icons` | One config makes both platforms' splash/icon |
| Min iOS version | **iOS 15.0** | Modern WKWebView; `isInspectable` works on 16.4+ |
| Dev machine | MacBook (Xcode required for iOS builds) | Apple requirement |

> ⚠️ **Rule of thumb:** Never rely on Instagram's CSS class names (like `x1lliihq`). They are auto-generated and change constantly. Target **`href`, `aria-label`, `role`, and page structure** instead.

---

## 3. UI Parity Plan (Same UI on iOS & Android)

Flutter draws its own pixels, so identical UI is very achievable. But by default Flutter **adapts** some things per platform (fonts, scroll bounce, page transitions, back gestures). Here's where differences come from and how to remove each one.

### 3.1 The app has two kinds of UI

| Part | Drawn by | Can we make it identical? |
|---|---|---|
| **Flutter UI** (settings sheet, toolbar, blocked-screen, error page, onboarding, snackbars) | Flutter | ✅ Yes, 100% |
| **Instagram page** (inside the WebView) | WKWebView (iOS) / Android WebView (Chromium) | ✅ Nearly. Same user agent + same injected CSS gives the same layout |
| **OS-owned UI** (permission popups, photo picker, keyboard, share sheet) | The OS | ❌ No, and that's expected. Users want their normal OS dialogs here |

### 3.2 Parity rules (follow these everywhere)

| # | Rule | Why |
|---|---|---|
| 1 | **Never use `Cupertino*` widgets or `.adaptive` constructors** (`Switch.adaptive`, `showAdaptiveDialog`, `CircularProgressIndicator.adaptive`…) | These deliberately look different per platform |
| 2 | **Set `ThemeData(platform: TargetPlatform.iOS)` (or Android) explicitly, then keep it** | Makes Flutter use the same scroll physics, text-selection handles and default behaviours on both |
| 3 | **Same page transitions on both**: set `pageTransitionsTheme` with the *same* builder for iOS and Android (e.g. `CupertinoPageTransitionsBuilder` for both, or a custom fade) | The default is a slide on iOS and a zoom/fade on Android |
| 4 | **Same scroll feel**: wrap the app in a `ScrollConfiguration` with one `physics` (e.g. `BouncingScrollPhysics`) | iOS bounces and Android glows/stretches by default |
| 5 | **Bundle one font** and set it in the theme | SF vs Roboto is the #1 visible difference |
| 6 | **Bundle one icon set**, and don't use `Icons.adaptive.*` | Same glyphs everywhere |
| 7 | **No ripple vs highlight mismatch**: set `splashFactory` (e.g. `InkSparkle`/`NoSplash`) in the theme | Consistent tap feedback |
| 8 | **Clamp text scaling** (`MediaQuery.textScaler` with a max, e.g. 1.3) | Large system fonts would otherwise break layouts differently |
| 9 | **No native toasts** (e.g. `fluttertoast` uses the Android native toast). Use our own Flutter `AsSnackbar`/overlay | Native toasts look different on each OS |
| 10 | **Same user agent string on both platforms** for the WebView | Instagram serves layouts based on UA. Same UA means the same Instagram layout |
| 11 | **All colours/spacing/radius come from tokens** (`AsColors`, `AsSpacing`, `AsRadius`) and never hard-coded | One change updates both platforms |
| 12 | **Edge-to-edge on both**: draw behind the status bar *and* the Android navigation bar, handle insets with `SafeArea` | iOS is always edge-to-edge; Android isn't by default |

### 3.3 Behaviours that must *feel* the same

| Behaviour | iOS default | Android default | Our unified plan |
|---|---|---|---|
| **Go back** | Edge swipe | System back button/gesture | Both trigger the **same** handler: `webView.canGoBack() ? goBack() : nothing`. iOS uses `allowsBackForwardNavigationGestures`; Android uses `PopScope`. Optional: an in-app ← button in our toolbar so both have a visible back too. |
| **Pull to refresh** | `UIRefreshControl` (native spinner) | `SwipeRefreshLayout` (native circle) | ⚠️ The plugin's `PullToRefreshController` uses **native** indicators, so they'd look different. **Plan:** inject a small **JS/CSS pull-to-refresh** into the page (same look on both, since it's HTML), or use a refresh button in our Flutter toolbar. Decide in Phase 5. |
| **Loading bar** | n/a | n/a | Our own Flutter `LinearProgressIndicator` styled with tokens, driven by `onProgressChanged` |
| **Status bar** | Light/dark text | Light/dark icons + colour | Set once via `SystemUiOverlayStyle` (transparent, icon brightness from theme) |
| **Haptics** | Taptic | Vibrator | `HapticFeedback.lightImpact()`. Same call; feel varies slightly by hardware, which is fine |
| **Dialogs / sheets** | n/a | n/a | Our own `AsBottomSheet`, `AsDialog` widgets only |
| **Text selection handles** | iOS style | Android style | Fixed by rule #2 (in Flutter UI). Inside the WebView, OS handles remain native, which is acceptable |

### 3.4 Instagram page parity (inside the WebView)

- **Same UA** on both (rule #10). Pick one modern mobile UA and keep it in one constant.
- **Same injected `blocker.css` / `blocker.js`** (already the plan).
- **Font (optional):** Instagram uses the system font stack, so the page shows SF on iOS and Roboto on Android. If you want the page itself identical too, inject `body, button, input { font-family: 'Inter', sans-serif !important; }` and ship the font file via a local asset URL. Decide later; this is a nice-to-have.
- **Scrollbars/overscroll inside the page:** inject `html { overscroll-behavior: none; }` so both behave the same (no Chromium stretch, no WebKit bounce), *unless* the JS pull-to-refresh needs overscroll.
- **Dark mode:** both WebViews follow the system theme. Make sure Android's WebView algorithmic darkening is **off** so Instagram's own dark theme is used, as on iOS.

### 3.5 How we'll verify parity

- **Golden tests** (`flutter test --update-goldens`) for every custom widget. Goldens render with Flutter's engine, so one set of images covers both platforms.
- **Side-by-side check** each milestone: iPhone + Android phone (or simulator + emulator) running the same build, same screen, compare screenshots.
- **Parity checklist** added to Phase 7.

---

## Phase 0 — Setup the Mac & Project

**⏱ ~1 day**

### Steps
1. **Install tools**
   - Xcode (from App Store) → open once, accept license, install iOS simulator.
   - `xcode-select --install` (command line tools)
   - Flutter SDK → `flutter doctor` until iOS section is ✅
   - CocoaPods: `brew install cocoapods`
2. **Create project**
   ```bash
   flutter create --org com.viraj --platforms=ios,android anti_social
   cd anti_social
   ```
3. **Add dependencies** (`pubspec.yaml`)
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_inappwebview: ^6.1.5
     shared_preferences: ^2.3.0
     provider: ^6.1.0
     url_launcher: ^6.3.0
   ```
   Then `flutter pub get`.
4. **Set iOS deployment target** → `ios/Podfile`:
   ```ruby
   platform :ios, '15.0'
   ```
   And in Xcode: *Runner → General → Minimum Deployments → 15.0*.
5. **Signing** → Open `ios/Runner.xcworkspace` in Xcode → *Signing & Capabilities* → select your Apple Developer team → set Bundle ID (e.g. `com.viraj.antisocial`).
6. Run on your real iPhone once: `flutter run` (enable Developer Mode on the iPhone when asked).

### ✅ Done when
- The default Flutter counter app runs on your iPhone.

---

## Phase 0.5 — Shared Design System

**⏱ ~1–2 days (do this BEFORE building any screen)**

Build the parity foundation first, so every screen after this is automatically identical on both platforms.

### Steps
1. **Add packages**
   ```yaml
   dependencies:
     lucide_icons: ^0.257.0        # or any single icon set
   dev_dependencies:
     flutter_native_splash: ^2.4.0
     flutter_launcher_icons: ^0.14.0
   flutter:
     fonts:
       - family: Inter
         fonts:
           - asset: assets/fonts/Inter-Regular.ttf
           - asset: assets/fonts/Inter-SemiBold.ttf
             weight: 600
   ```
2. **Create tokens** in `lib/ui/theme/tokens.dart`: `AsColors` (light + dark), `AsSpacing` (4, 8, 12, 16, 24…), `AsRadius`, `AsTextStyles`.
3. **Create one theme** in `lib/ui/theme/app_theme.dart`:
   ```dart
   ThemeData buildTheme(Brightness b) => ThemeData(
     useMaterial3: true,
     brightness: b,
     platform: TargetPlatform.iOS,          // fixed for BOTH platforms
     fontFamily: 'Inter',
     splashFactory: NoSplash.splashFactory, // same tap feedback everywhere
     pageTransitionsTheme: const PageTransitionsTheme(builders: {
       TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
       TargetPlatform.android: CupertinoPageTransitionsBuilder(), // same!
     }),
     colorScheme: /* from AsColors */,
   );
   ```
4. **Global wrappers** in `main.dart`:
   - `ScrollConfiguration` with one `ScrollBehavior` (same physics, no glow).
   - `MediaQuery` text-scale clamp.
   - `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` + transparent `SystemUiOverlayStyle`.
5. **Build core widgets** in `lib/ui/widgets/` (the only widgets screens may use):
   - `AsToggleTile` (custom switch, **not** `Switch.adaptive`)
   - `AsBottomSheet`, `AsDialog`, `AsSnackbar`
   - `AsButton` (primary / secondary)
   - `AsTopBar` (back, title, settings, optional refresh)
   - `AsProgressBar` (thin loading bar)
   - `AsErrorView` (offline / retry)
6. **One shared constant** in `lib/core/constants.dart`: `kUserAgent`, `kHomeUrl`.
7. **Golden tests** for each widget in `test/goldens/`.
8. Configure `flutter_native_splash` and `flutter_launcher_icons` with your own artwork (one config → both platforms).

### ✅ Done when
- [ ] A "widget gallery" debug screen shows every `As*` widget in light + dark mode.
- [ ] Golden tests pass.
- [ ] Nothing in `lib/` imports `package:flutter/cupertino.dart` except the page-transition builder.

---

## Phase 1 — Basic Instagram WebView

**⏱ ~1–2 days**

### Goal
Full-screen Instagram Web, you can log in, scroll, and the login **stays saved** after closing the app.

### Code (`lib/screens/web_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});
  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  InAppWebViewController? _controller;

  final _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    allowsInlineMediaPlayback: true,       // videos play inside, not fullscreen
    mediaPlaybackRequiresUserGesture: true, // no autoplay sound
    allowsBackForwardNavigationGestures: true, // iOS swipe back
    isInspectable: true,                   // Safari Web Inspector (debug only!)
    sharedCookiesEnabled: true,            // keep login
    // ONE shared UA constant (lib/core/constants.dart), used on BOTH
    // iOS and Android, so Instagram serves the same layout everywhere.
    userAgent: kUserAgent,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest:
              URLRequest(url: WebUri('https://www.instagram.com/')),
          initialSettings: _settings,
          onWebViewCreated: (c) => _controller = c,
        ),
      ),
    );
  }
}
```

### Things to verify
- [ ] Login works (cookies persist — WKWebView stores them in the default data store automatically).
- [ ] Kill the app → reopen → still logged in.
- [ ] Videos play inline.
- [ ] Notch / Dynamic Island area isn't covering content (`SafeArea`).

### 🔧 Set up debugging NOW (you'll use it constantly)
1. iPhone: *Settings → Safari → Advanced → Web Inspector* → ON.
2. Mac: *Safari → Settings → Advanced → Show features for web developers*.
3. Run the app → Mac Safari → *Develop → [Your iPhone] → instagram.com*.
4. You now have DevTools for the page inside your app. This is how you'll **find selectors** for Reels/Stories.

---

## Phase 2 — Inject CSS & JS (the Blocker Engine)

**⏱ ~3–5 days (most important phase)**

### 2.1 Put scripts in assets
```
assets/
  inject/
    blocker.css
    blocker.js
```
`pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/inject/
```

### 2.2 Find the selectors (use Web Inspector)
For each feature, inspect the element and pick a **stable** selector:

| Feature | Good selector ideas (verify in Inspector!) |
|---|---|
| Reels tab in bottom nav | `a[href="/reels/"]`, `a[href^="/reels"]` |
| Reels links anywhere | `a[href*="/reel/"]` |
| Explore tab | `a[href="/explore/"]` |
| Stories tray (top of feed) | Find the horizontal list of story avatars — often identifiable by `role="menu"`/`role="list"` or links containing `/stories/`; target its container |
| Suggested posts / "Suggested for you" | Find by text content in JS (e.g. heading text) |
| Reels inside feed | Feed `<article>` that contains a link to `/reel/` |

> 💡 Instagram changes structure often. Write down every selector in **one file** so fixes are a one-line change.

### 2.3 `blocker.css` (instant hide — no flicker)
```css
/* Each rule is wrapped by a class on <html> so toggles can switch it on/off */
html.as-block-reels a[href="/reels/"],
html.as-block-reels a[href^="/reels/"] { display: none !important; }

html.as-block-explore a[href="/explore/"] { display: none !important; }

/* Stories tray — replace with the selector you found */
html.as-block-stories [data-as-stories-tray] { display: none !important; }
```

**Trick:** Toggles add/remove classes on `<html>` (e.g. `as-block-reels`). CSS stays static; switching features on/off is just a class change → instant, no reload.

### 2.4 `blocker.js` (dynamic stuff)
```js
(function () {
  if (window.__AS_LOADED) return;
  window.__AS_LOADED = true;

  const cfg = window.__AS_CONFIG || {};

  // 1. Apply toggle classes on <html>
  function applyClasses() {
    const h = document.documentElement;
    h.classList.toggle('as-block-reels',   !!cfg.blockReels);
    h.classList.toggle('as-block-stories', !!cfg.blockStories);
    h.classList.toggle('as-block-explore', !!cfg.blockExplore);
  }

  // 2. Tag/remove elements CSS can't easily target
  function sweep() {
    if (cfg.blockReels) {
      // Remove feed posts that are reels
      document.querySelectorAll('article').forEach(a => {
        if (a.querySelector('a[href*="/reel/"]')) a.style.display = 'none';
      });
    }
    if (cfg.blockStories) {
      // Mark the stories tray so CSS hides it (adjust logic to what you find)
      const storyLink = document.querySelector('a[href*="/stories/"]');
      const tray = storyLink && storyLink.closest('[role="menu"], [role="list"], ul');
      if (tray) tray.setAttribute('data-as-stories-tray', '1');
    }
  }

  // 3. Instagram is a single-page app → watch route changes
  function onRoute() {
    const p = location.pathname;
    const blocked =
      (cfg.blockReels && /^\/reels?\//.test(p)) ||
      (cfg.blockExplore && p.startsWith('/explore'));
    if (blocked) {
      location.replace('/');
      notify('blocked', p);
    }
  }
  ['pushState', 'replaceState'].forEach(fn => {
    const orig = history[fn];
    history[fn] = function () {
      const r = orig.apply(this, arguments);
      onRoute();
      return r;
    };
  });
  window.addEventListener('popstate', onRoute);

  // 4. Watch DOM changes (throttled so it doesn't kill battery)
  let pending = false;
  const obs = new MutationObserver(() => {
    if (pending) return;
    pending = true;
    requestAnimationFrame(() => { pending = false; sweep(); });
  });

  // 5. Talk back to Dart
  function notify(type, data) {
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('asEvent', { type, data });
    }
  }

  // 6. Live config update from Dart
  window.__AS_UPDATE = function (newCfg) {
    Object.assign(cfg, newCfg);
    applyClasses(); sweep(); onRoute();
  };

  // Boot (script runs at document start, so wait for DOM where needed)
  applyClasses();
  onRoute();
  document.addEventListener('DOMContentLoaded', () => {
    obs.observe(document.body, { childList: true, subtree: true });
    sweep();
  });
})();
```

### 2.5 Inject from Dart at document start
```dart
Future<List<UserScript>> buildUserScripts(BlockerConfig cfg) async {
  final css = await rootBundle.loadString('assets/inject/blocker.css');
  final js  = await rootBundle.loadString('assets/inject/blocker.js');

  final cssInjector = '''
    (function(){
      var s = document.createElement('style');
      s.id = 'as-style';
      s.textContent = ${jsonEncode(css)};
      (document.head || document.documentElement).appendChild(s);
    })();
  ''';

  return [
    UserScript(
      source: 'window.__AS_CONFIG = ${jsonEncode(cfg.toJson())};',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    UserScript(source: cssInjector,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
    UserScript(source: js,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START),
  ];
}
```
Pass them via `initialUserScripts: UnmodifiableListView(scripts)` on `InAppWebView`.

### 2.6 Listen to JS events in Dart
```dart
onWebViewCreated: (c) {
  _controller = c;
  c.addJavaScriptHandler(
    handlerName: 'asEvent',
    callback: (args) {
      debugPrint('Blocker event: $args');
      // later: show a toast "Reels are blocked 🙂", count blocks, etc.
    },
  );
},
```

### 2.7 Bonus layer: iOS Content Blockers (native, very fast)
WKWebView supports Safari-style content rules. `flutter_inappwebview` exposes them:
```dart
contentBlockers: [
  ContentBlocker(
    trigger: ContentBlockerTrigger(urlFilter: '.*instagram\\.com.*'),
    action: ContentBlockerAction(
      type: ContentBlockerActionType.CSS_DISPLAY_NONE,
      selector: 'a[href="/reels/"], a[href="/explore/"]',
    ),
  ),
],
```
Use this for the simplest, most stable hides. Keep complex logic in JS.

### ✅ Done when
- [ ] Reels tab is gone from bottom nav.
- [ ] Stories tray is gone.
- [ ] No visible "flash" of blocked content on app launch.
- [ ] Reels posts in feed are hidden (if toggle on).

---

## Phase 3 — Block Navigation to Reels (URL Guard)

**⏱ ~1 day**

Even if something slips through (a shared reel in DMs, a profile's reel tab), the **Dart side** refuses to open it.

### Two hooks are needed
| Hook | Catches |
|---|---|
| `shouldOverrideUrlLoading` | Full page loads, link taps, `instagram://` app-scheme links |
| `onUpdateVisitedHistory` | **SPA route changes** (Instagram uses `history.pushState`, which does NOT trigger the first hook) |

```dart
bool _isBlockedPath(Uri u, BlockerConfig cfg) {
  final p = u.path;
  if (cfg.blockReels && (p.startsWith('/reels') || p.startsWith('/reel/'))) return true;
  if (cfg.blockExplore && p.startsWith('/explore')) return true;
  return false;
}

// In InAppWebView:
shouldOverrideUrlLoading: (controller, action) async {
  final uri = action.request.url;
  if (uri == null) return NavigationActionPolicy.ALLOW;

  // Never let it jump to the real Instagram app
  if (uri.scheme == 'instagram') return NavigationActionPolicy.CANCEL;

  if (_isBlockedPath(uri, cfg)) {
    _showBlockedSnack();
    return NavigationActionPolicy.CANCEL;
  }

  // Non-Instagram links → open in Safari
  if (!uri.host.endsWith('instagram.com') &&
      !uri.host.endsWith('facebook.com') &&     // for "Log in with Facebook"
      !uri.host.endsWith('cdninstagram.com')) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationActionPolicy.CANCEL;
  }
  return NavigationActionPolicy.ALLOW;
},

onUpdateVisitedHistory: (controller, url, isReload) {
  if (url != null && _isBlockedPath(url, cfg)) {
    controller.loadUrl(
      urlRequest: URLRequest(url: WebUri('https://www.instagram.com/')));
  }
},
```

> ℹ️ "Reel shared in DMs" decision: do you block it fully, or allow single reels from DMs but block the endless reels feed? Start with **block all**, add an option later.

### ✅ Done when
- [ ] Typing/tapping any reels URL bounces back to home.
- [ ] Shared reel in DMs doesn't open (or follows your chosen rule).
- [ ] External links open in Safari, not inside the app.

---

## Phase 4 — Settings Screen (Feature Toggles)

**⏱ ~2 days**

### Data model (`lib/models/blocker_config.dart`)
```dart
class BlockerConfig {
  final bool blockReels;
  final bool blockStories;
  final bool blockExplore;
  final bool blockSuggested;

  const BlockerConfig({
    this.blockReels = true,
    this.blockStories = true,
    this.blockExplore = true,
    this.blockSuggested = false,
  });

  Map<String, dynamic> toJson() => {
    'blockReels': blockReels,
    'blockStories': blockStories,
    'blockExplore': blockExplore,
    'blockSuggested': blockSuggested,
  };
  // + fromJson, copyWith
}
```

### Flow
```
User flips toggle
   → save to shared_preferences
   → Provider notifies WebScreen
   → controller.evaluateJavascript(source: 'window.__AS_UPDATE(${jsonEncode(cfg)})')
   → page updates instantly (no reload)
```
Also update the stored user scripts so the **next** page load uses the new config:
```dart
await controller.removeAllUserScripts();
await controller.addUserScripts(userScripts: await buildUserScripts(cfg));
```

### UI ideas
- ⚙️ button in `AsTopBar` → `AsBottomSheet` with `AsToggleTile`s (our own widgets only, so it's identical on Android).
- Optional **"friction mode"**: turning a block OFF needs a 10-second wait / typing a sentence. (Great anti-addiction feature — this is what makes it more than a web wrapper.)

### ✅ Done when
- [ ] Toggles persist after app restart.
- [ ] Toggling updates the page live.

---

## Phase 5 — iOS Polish (Login, Uploads, Links, Gestures)

**⏱ ~2–3 days**

| Item | What to do |
|---|---|
| **Photo/video upload** | Add to `ios/Runner/Info.plist`: `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` (with friendly text). WKWebView then shows the native picker for `<input type="file">`. |
| **Popups (Log in with Facebook)** | Handle `onCreateWindow` → load the popup URL in the same webview or a modal webview, return `true`. |
| **Back navigation** | iOS: `allowsBackForwardNavigationGestures: true`. Write one shared `handleBack()` that Android's `PopScope` will call later, so behaviour matches. |
| **Pull to refresh** | ⚠️ **Don't** use the plugin's native `PullToRefreshController` (different spinner per OS). Use an injected JS/CSS pull-to-refresh or the refresh button in `AsTopBar`. See 3.3. |
| **"Open in app" banners** | Instagram may nag to install the app — hide that banner with CSS. |
| **Loading state** | `onProgressChanged` → `AsProgressBar`. |
| **Offline / error page** | `onReceivedError` → `AsErrorView`. |
| **Dark mode** | Instagram web follows system theme; set Scaffold background from `AsColors` to avoid white flashes. |
| **Status bar** | Transparent, edge-to-edge, icon brightness from theme (same code serves Android's nav bar later). |
| **App icon & launch screen** | Your own design via `flutter_launcher_icons` / `flutter_native_splash` — **do not** use Instagram's logo. |
| **Background → foreground** | Optionally reload if the app was in background > X minutes. |
| **Disable `isInspectable` in release** | `isInspectable: kDebugMode` |

### ✅ Done when
- [ ] You can post a photo, send a DM with an image, and log out/in from inside the app.

---

## Phase 6 — Making Selectors Survive Instagram Updates

**⏱ ongoing**

Instagram will break your selectors at some point. Plan for it:

1. **One selector file** — every selector lives in a single `selectors` object in JS (or a JSON asset).
2. **Prefer stable hooks**: `href` → `aria-label` → `role` → structure. Never class names.
3. **Health check**: on each page load, JS checks "did I find the reels nav link?" — if not, send `asEvent {type: 'selector_missing', name: 'reelsNav'}` to Dart so you know during testing.
4. **Remote selector config (optional, later):** host a small JSON file (e.g. GitHub raw) with **CSS selectors only** and fetch it at launch, so you can fix breakages without an App Store update.
   > ⚠️ App Store Guideline 2.5.2 forbids downloading **executable code**. Keep remote updates to **data** (selector strings, URL patterns). Ship all JS logic inside the app bundle.
5. **Fallback = URL Guard.** Even if CSS/JS breaks, Phase 3 still stops reels from opening.

---

## Phase 7 — Testing

**⏱ ~2 days, then every release**

### Manual test checklist
| # | Test | Expected |
|---|---|---|
| 1 | Fresh install → login | Works, stays logged in |
| 2 | Bottom nav | No Reels / Explore tab |
| 3 | Home feed | No stories tray, reels posts hidden |
| 4 | Open profile → Reels tab | Hidden or blocked |
| 5 | Tap a reel shared in DM | Blocked (snackbar shown) |
| 6 | Paste `instagram.com/reels/` via link | Bounced home |
| 7 | Toggle Reels OFF | Reels appear without app restart |
| 8 | Upload a post | Native picker opens, upload succeeds |
| 9 | External link in bio | Opens in Safari |
| 10 | Airplane mode | Error screen with retry |
| 11 | Kill & relaunch | Settings + login preserved |
| 12 | Scroll feed for 5 min | No lag, no battery spike (MutationObserver throttled) |

### UI parity checklist (run once Android build exists; until then, check against the rules in section 3)
| # | Check | Expected |
|---|---|---|
| P1 | Font in settings sheet / top bar | Inter on both |
| P2 | Toggle, button, sheet, snackbar look | Pixel-identical (golden tests pass) |
| P3 | Screen transition animation | Same animation on both |
| P4 | Scroll overscroll in Flutter lists | Same bounce, no Android glow |
| P5 | Back behaviour | Swipe (iOS) / back gesture (Android) → same result |
| P6 | Pull to refresh / refresh button | Same visual |
| P7 | Instagram layout (same account, same screen) | Same layout (same UA) |
| P8 | Dark mode | Same colours, Instagram's own dark theme on both |
| P9 | Largest system text size | Layout doesn't break (clamped) |
| P10 | Status/nav bar | Edge-to-edge, correct icon colour on both |

### Devices
- iPhone simulator (various sizes)
- Your real iPhone (most important — WebView behaviour differs slightly)
- At least one older iOS version if possible (iOS 15/16)

### Automated (lightweight)
- Unit tests for `BlockerConfig` and `_isBlockedPath()` — easy and worth it.
- `flutter analyze` clean before each build.

---

## Phase 8 — TestFlight & App Store

**⏱ ~1 week (includes review time)**

### Steps
1. **App Store Connect** → create app record with your Bundle ID.
2. Bump version in `pubspec.yaml` (`version: 1.0.0+1`).
3. Build: `flutter build ipa --release`
4. Upload with **Transporter** app or Xcode Organizer.
5. **TestFlight** → install on your phone, test for a week, share with a few friends.
6. Submit for review only when happy.

### ⚠️ App Review risks (read before submitting)
| Guideline | Risk | How to reduce it |
|---|---|---|
| **4.2 Minimum Functionality** | "It's just a website wrapper" | Add real native value: toggles, friction mode, usage stats/screen-time summary, daily limit timer |
| **5.2 Intellectual Property** | Using Instagram's name/logo | Don't use "Instagram" in the app name or icon. Say "for social media" / describe neutrally. |
| **5.2.2 Third-party services** | Accessing another company's service | Be transparent that it loads the official website; you don't scrape or store data. |
| **5.1 Privacy** | Handling user data | You don't collect anything → say so in the privacy label. Have a simple privacy policy URL. |
| **Instagram's Terms** | Modifying their site | Personal-use/TestFlight is low-risk; public release is a grey area — keep that in mind. |

> 💡 Ship to **TestFlight first** and use it yourself. Public App Store release is a separate decision you can make later.

---

## Folder Structure

```
anti_social/
├── assets/
│   ├── fonts/                        # Inter (bundled → same font everywhere)
│   └── inject/
│       ├── blocker.css
│       └── blocker.js
├── lib/
│   ├── main.dart                     # theme, ScrollConfiguration, text clamp, edge-to-edge
│   ├── core/
│   │   └── constants.dart            # kUserAgent, kHomeUrl (shared by both OSes)
│   ├── ui/
│   │   ├── theme/
│   │   │   ├── tokens.dart           # AsColors, AsSpacing, AsRadius, AsTextStyles
│   │   │   └── app_theme.dart        # single ThemeData for iOS + Android
│   │   └── widgets/                  # AsTopBar, AsToggleTile, AsBottomSheet, AsDialog,
│   │                                 # AsSnackbar, AsButton, AsProgressBar, AsErrorView
│   ├── models/
│   │   └── blocker_config.dart
│   ├── services/
│   │   ├── settings_service.dart     # shared_preferences load/save
│   │   └── script_builder.dart       # builds UserScripts from assets + config
│   ├── screens/
│   │   ├── web_screen.dart           # InAppWebView + URL guard
│   │   └── settings_sheet.dart       # toggles UI
│   └── utils/
│       └── url_rules.dart            # _isBlockedPath and friends
├── ios/
│   └── Runner/Info.plist             # camera/photo/mic permissions
├── test/
│   ├── goldens/                      # widget screenshots = parity proof
│   └── url_rules_test.dart
└── pubspec.yaml
```

> The `lib/` and `assets/` folders are **100% shared** with Android. Only `ios/` vs `android/` platform config differs (permissions, signing, edge-to-edge, WebView dark-mode setting). **No `if (Platform.isIOS)` in UI code** — platform checks are allowed only in `web_screen.dart` for back-handling wiring.

---

## Common Pitfalls & Fixes

| Problem | Cause | Fix |
|---|---|---|
| Blocked content flashes for a split second | CSS injected too late | Inject CSS at `AT_DOCUMENT_START`; use content blockers for key items |
| Reels still open when tapping inside app | Instagram uses `pushState` (SPA) | Use `onUpdateVisitedHistory` + JS `history` hook (Phase 3) |
| Selectors stopped working | Instagram changed their DOM | Use Web Inspector, update the single selectors file |
| Logged out every launch | Cookies not persisted / non-default data store | Don't use incognito mode; keep default `WKWebsiteDataStore` |
| Instagram shows desktop site or "use the app" page | Wrong user agent | Use a real mobile Safari UA string |
| Tapping a link opens the real Instagram app | Universal links / `instagram://` | Cancel `instagram` scheme in `shouldOverrideUrlLoading` |
| File upload does nothing | Missing Info.plist keys | Add the 3 usage descriptions |
| Phone gets warm while scrolling | MutationObserver running too often | Throttle with `requestAnimationFrame` (already in sample) |
| JS runs twice | Script injected in iframes too | Guard with `window.__AS_LOADED`; set `forMainFrameOnly: true` on `UserScript` |
| `pod install` errors | Old CocoaPods / deployment target | `cd ios && pod repo update && pod install`, check `platform :ios, '15.0'` |

---

## Milestone Checklist

| Milestone | Deliverable | Est. time |
|---|---|---|
| **M0** | Mac + Flutter + Xcode working, app runs on iPhone | Day 1 |
| **M0.5** | Design system: tokens, theme, `As*` widgets, golden tests | Day 2–3 |
| **M1** | Instagram loads, login persists, Web Inspector connected | Day 4–5 |
| **M2** | CSS + JS injected; Reels tab & Stories tray hidden | Week 1 |
| **M3** | URL Guard blocks reels/explore everywhere | Week 1–2 |
| **M4** | Settings screen with live toggles | Week 2 |
| **M5** | Uploads, popups, links, refresh, error page | Week 2–3 |
| **M6** | Selector health-check + testing checklist passed | Week 3 |
| **M7** | TestFlight build on your phone 🎉 | Week 3–4 |
| **M8** (later) | Native extras: friction mode, usage timer, stats → App Store submission | Week 4+ |

---

### Suggested order to start coding today
1. Phase 0 → get the empty app on your phone.
2. Phase 0.5 → tokens, theme and `As*` widgets (the parity foundation).
3. Phase 1 → Instagram loads + **Web Inspector working**.
4. In Web Inspector, find the Reels nav link and Stories tray → write those 2 selectors.
5. Phase 2 → hide just those two. That's your first "it works!" moment.
6. Then build outward (URL guard → settings → polish).
