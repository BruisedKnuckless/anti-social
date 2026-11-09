# AntiSocial (Flutter)

Instagram's website in a WebView, with Reels, Explore, Stories and suggested posts blocked.
Your feed, DMs, profile and posting keep working. iOS first; the same `lib/` and `assets/` will run on Android.

## Run
```bash
flutter pub get
flutter run            # pick an iOS simulator or your iPhone
```
For a real iPhone, open `ios/Runner.xcworkspace` in Xcode → Runner → Signing & Capabilities → pick your team.

## Where things live
| Path | What |
|---|---|
| `assets/inject/blocker.css` / `blocker.js` | The blocker engine. **All selectors are in `SELECTORS` / `TEXT` at the top of `blocker.js`.** Edit these when Instagram changes. |
| `assets/inject/skin.css` | The "native" look: + / logo / heart header, floating glass tab bar in native order, in-page settings button. Styles only `data-as-*` tags that `tagChrome()` in `blocker.js` adds. |
| `lib/utils/url_rules.dart` | URL guard (Dart). Keep its path rules in sync with `decide()` in `blocker.js`. |
| `lib/models/blocker_config.dart` | The 5 toggles and their defaults (all on). |
| `lib/screens/web_screen.dart` | InAppWebView, script injection, URL guard hooks, JS→Dart events. |
| `lib/ui/` | Design tokens, theme and `As*` widgets. Same UI on iOS and Android, so no Cupertino/adaptive widgets. |

## Debugging selectors
Debug builds are inspectable: iPhone/Simulator → Mac Safari → Develop → [device] → instagram.com.
The app logs `Blocker event: selector_missing {name: ...}` when a selector stops matching on the logged-in feed.
Open the settings sheet (round button next to the tab bar) and long-press the "Debug" line to open the widget gallery (debug builds).

## Tests
```bash
flutter analyze
flutter test                                  # URL rules, config, goldens
flutter test --update-goldens test/goldens    # after an intentional UI change
```
