import Foundation

/// Rules for the reel-free Instagram experience.
///
/// Two layers:
///  1. `redirect(for:)` — used by the WKNavigationDelegate for full page loads.
///  2. `script` — injected JS for Instagram's single-page navigation (pushState),
///     hiding the Reels tab, suggested posts and ads.
///
/// Instagram changes its web markup often; if something slips through, this is the file to edit.
enum InstagramFilter {
    static let homeURL = URL(string: "https://www.instagram.com/")!
    static let searchURL = URL(string: "https://www.instagram.com/explore/search/")!

    /// Returns where to send the user instead, or nil if the URL is allowed.
    static func redirect(for url: URL) -> URL? {
        guard let host = url.host, host.hasSuffix("instagram.com") else { return nil }
        let path = url.path   // URL.path drops the trailing slash

        // Reels feed (single reels at /reel/<id> that friends send you stay allowed)
        if path == "/reels" || path.hasPrefix("/reels/") { return homeURL }

        // Explore grid -> plain search (keeps search, drops the endless grid)
        if path == "/explore" { return searchURL }
        if path.hasPrefix("/explore/") && !path.hasPrefix("/explore/search") { return searchURL }

        return nil
    }

    static let script = #"""
    (function () {
      if (window.__antisocial) return;
      window.__antisocial = true;

      // 1. Hide the Reels tab / links to the Reels feed
      const style = document.createElement('style');
      style.textContent = `
        a[href="/reels/"], a[href^="/reels/"] { display: none !important; }
      `;
      const addStyle = () => (document.head || document.documentElement).appendChild(style);
      addStyle();
      document.addEventListener('DOMContentLoaded', addStyle);

      // 2. Redirect blocked pages during in-app (pushState) navigation
      const norm = p => (p.length > 1 ? p.replace(/\/+$/, '') : p);
      let lastHref = '';
      function checkURL() {
        if (location.href === lastHref) return;
        lastHref = location.href;
        const p = norm(location.pathname);
        if (p === '/reels' || p.startsWith('/reels/')) { location.replace('/'); return; }
        if (p === '/explore' || (p.startsWith('/explore/') && !p.startsWith('/explore/search'))) {
          location.replace('/explore/search/');
        }
      }

      // 3. Hide suggested posts, suggested reels and ads in the home feed
      const BLOCK_TEXT = ['Suggested for you', 'Suggested posts', 'Suggested reels', 'Sponsored'];
      function hideSuggested() {
        document.querySelectorAll('article:not([data-as-checked])').forEach(a => {
          const text = a.innerText || '';
          if (BLOCK_TEXT.some(t => text.includes(t))) a.style.display = 'none';
          // only mark as checked once it has rendered some text
          if (text.length > 20) a.setAttribute('data-as-checked', '1');
        });
      }

      ['pushState', 'replaceState'].forEach(fn => {
        const orig = history[fn];
        history[fn] = function () { const r = orig.apply(this, arguments); checkURL(); return r; };
      });
      window.addEventListener('popstate', checkURL);

      let pending = false;
      function run() {
        if (pending) return;
        pending = true;
        setTimeout(() => { pending = false; checkURL(); hideSuggested(); }, 250);
      }
      new MutationObserver(run).observe(document.documentElement, { childList: true, subtree: true });
      checkURL();
    })();
    """#
}
