/*
 * AntiSocial blocker engine. Injected at document start, main frame only.
 *
 * Layers:
 *  1. Classes on <html> switch the static rules in blocker.css on/off.
 *  2. sweep() tags things CSS can't find on its own (reel posts, the stories
 *     tray, suggested posts) with data-as-* attributes that the CSS hides.
 *  3. A route watcher catches Instagram's SPA navigation (pushState) and
 *     bounces blocked pages. Dart's URL guard is the backstop.
 *
 * When Instagram changes its markup, edit SELECTORS / TEXT below. Keep the
 * path rules in sync with lib/utils/url_rules.dart.
 */
(function () {
  if (window.__AS_LOADED) return;
  window.__AS_LOADED = true;

  var cfg = Object.assign({}, window.__AS_CONFIG || {});

  // ---- 1. Every selector in one place ---------------------------------
  var SELECTORS = {
    reelsNav: 'a[href="/reels/"]',
    reelLink: 'a[href*="/reel/"]',
    storyLink: 'a[href*="/stories/"]',
    trayContainer: 'ul, [role="list"], [role="menu"], [role="listbox"]',
    feedArticle: 'article',
    postLink: 'a[href*="/p/"], a[href*="/reel/"], time',
    appNagCandidates: 'a, button, [role="button"]',
    loggedInMarker: 'a[href^="/direct/"]'
  };

  var TEXT = {
    suggested: ['Suggested for you', 'Suggested posts', 'Suggested reels', 'Sponsored'],
    appNag: ['Open app', 'Open App', 'Use the app', 'Use the App', 'Get the app', 'Open Instagram']
  };

  // ---- 2. Talk to Dart ------------------------------------------------
  var queue = [];
  function notify(type, data) {
    var bridge = window.flutter_inappwebview;
    if (bridge && bridge.callHandler) {
      bridge.callHandler('asEvent', { type: type, data: data });
    } else {
      queue.push({ type: type, data: data });
    }
  }
  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    var pending = queue;
    queue = [];
    pending.forEach(function (e) { notify(e.type, e.data); });
  });

  // ---- 3. Styles + classes --------------------------------------------
  function ensureStyle() {
    if (window.__AS_CSS && !document.getElementById('as-style')) {
      var s = document.createElement('style');
      s.id = 'as-style';
      s.textContent = window.__AS_CSS;
      (document.head || document.documentElement).appendChild(s);
    }
  }

  function applyClasses() {
    var h = document.documentElement;
    if (!h) return;
    h.classList.toggle('as-block-reels', !!cfg.blockReels);
    h.classList.toggle('as-block-stories', !!cfg.blockStories);
    h.classList.toggle('as-block-explore', !!cfg.blockExplore);
    h.classList.toggle('as-block-suggested', !!cfg.blockSuggested);
  }

  // ---- 4. Path rules (mirror of url_rules.dart) ------------------------
  function norm(p) {
    var s = (p || '/').replace(/\/+$/, '');
    return s === '' ? '/' : s;
  }

  // Returns null (allowed), {redirect: path, reason} or {block: true, reason}.
  function decide(path) {
    var p = norm(path);
    if (cfg.blockReels) {
      if (p === '/reels' || p.indexOf('/reels/') === 0) return { redirect: '/', reason: 'Reels are blocked' };
      var m = /^\/([^/]+)\/reels$/.exec(p);
      if (m) return { redirect: '/' + m[1] + '/', reason: 'Reels are blocked' };
    }
    if (cfg.blockDmReels && (p === '/reel' || p.indexOf('/reel/') === 0)) {
      return { block: true, reason: 'Reels are blocked' };
    }
    if (cfg.blockExplore && (p === '/explore' ||
        (p.indexOf('/explore/') === 0 && p.indexOf('/explore/search') !== 0))) {
      return { redirect: '/explore/search/', reason: "Explore is blocked. Here's Search" };
    }
    if (cfg.blockStories && (p === '/stories' || p.indexOf('/stories/') === 0)) {
      return { redirect: '/', reason: 'Stories are blocked' };
    }
    return null;
  }

  var lastHref = '';
  function onRoute(force) {
    if (!force && location.href === lastHref) return;
    lastHref = location.href;
    var d = decide(location.pathname);
    if (!d) return;
    notify('blocked', { path: location.pathname, reason: d.reason });
    if (d.redirect) {
      location.replace(d.redirect);
    } else if (history.length > 1) {
      history.back();
    } else {
      location.replace('/');
    }
  }

  ['pushState', 'replaceState'].forEach(function (fn) {
    var orig = history[fn];
    history[fn] = function () {
      var r = orig.apply(this, arguments);
      onRoute(false);
      return r;
    };
  });
  window.addEventListener('popstate', function () { onRoute(false); });

  // ---- 5. Sweep: tag what CSS can't target ------------------------------
  function textOf(el) {
    return (el && (el.innerText || el.textContent)) || '';
  }

  function tagArticles() {
    var articles = document.querySelectorAll(SELECTORS.feedArticle + ':not([data-as-done])');
    for (var i = 0; i < articles.length; i++) {
      var a = articles[i];
      if (a.querySelector(SELECTORS.reelLink)) a.setAttribute('data-as-reel', '1');
      var t = textOf(a);
      for (var j = 0; j < TEXT.suggested.length; j++) {
        if (t.indexOf(TEXT.suggested[j]) !== -1) { a.setAttribute('data-as-suggested', '1'); break; }
      }
      // Stop re-checking once the post has fully rendered.
      if (t.length > 40 && a.querySelector(SELECTORS.postLink)) a.setAttribute('data-as-done', '1');
    }
  }

  function findStoriesTray() {
    if (document.querySelector('[data-as-stories-tray]')) return true;
    // A: list that contains links to /stories/ (outside any feed post)
    var links = document.querySelectorAll(SELECTORS.storyLink);
    for (var i = 0; i < links.length; i++) {
      if (links[i].closest('article')) continue;
      var tray = links[i].closest(SELECTORS.trayContainer);
      if (tray) { tray.setAttribute('data-as-stories-tray', '1'); return true; }
    }
    // B: a container labelled "Stories"
    var labelled = document.querySelector('main [aria-label="Stories"], main [aria-label="stories"]');
    if (labelled) { labelled.setAttribute('data-as-stories-tray', '1'); return true; }
    // C: a horizontal list of avatar rings (canvas) at the top of the feed
    var lists = document.querySelectorAll('main ul');
    for (var k = 0; k < lists.length; k++) {
      var ul = lists[k];
      if (ul.closest('article')) continue;
      if (ul.querySelectorAll(':scope > li canvas').length >= 3) {
        ul.setAttribute('data-as-stories-tray', '1');
        return true;
      }
    }
    return false;
  }

  function tagAppNags() {
    var els = document.querySelectorAll(SELECTORS.appNagCandidates);
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.hasAttribute('data-as-app-nag')) continue;
      var t = textOf(el).trim();
      if (t.length && t.length < 20 && TEXT.appNag.indexOf(t) !== -1) {
        el.setAttribute('data-as-app-nag', '1');
      }
    }
  }

  function sweep() {
    if (!document.body) return;
    ensureStyle();
    applyClasses();
    tagArticles();
    findStoriesTray();
    tagAppNags();
    onRoute(false);
  }

  // ---- 6. Throttled observer (battery friendly) -------------------------
  var scheduled = false;
  function schedule() {
    if (scheduled) return;
    scheduled = true;
    setTimeout(function () {
      requestAnimationFrame(function () { scheduled = false; sweep(); });
    }, 150);
  }
  var observer = new MutationObserver(schedule);

  // ---- 7. Health check: tell Dart when a selector stops matching --------
  var reported = {};
  function healthCheck() {
    if (norm(location.pathname) !== '/') return;
    // Only meaningful on the logged-in feed (DM link = logged in).
    if (!document.querySelector(SELECTORS.loggedInMarker)) return;
    if (!document.querySelector('main ' + SELECTORS.feedArticle)) return;
    var checks = {
      reelsNav: !!document.querySelector(SELECTORS.reelsNav),
      storiesTray: findStoriesTray()
    };
    Object.keys(checks).forEach(function (name) {
      if (!checks[name] && !reported[name]) {
        reported[name] = true;
        notify('selector_missing', { name: name });
      }
    });
  }

  // ---- 8. Live config updates from Dart ---------------------------------
  window.__AS_UPDATE = function (next) {
    Object.assign(cfg, next || {});
    applyClasses();
    sweep();
    onRoute(true);
  };

  // ---- Boot ---------------------------------------------------------------
  applyClasses();
  onRoute(true);
  function start() {
    ensureStyle();
    observer.observe(document.documentElement, { childList: true, subtree: true });
    sweep();
    setTimeout(healthCheck, 5000);
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
