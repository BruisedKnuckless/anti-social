/*
 * Anti-Social blocker engine. Identical on iOS and Android.
 * Injected at document start after window.__AS_CONFIG, __AS_SELECTORS and
 * __AS_CSS are set by script_builder.dart.
 */
(function () {
  'use strict';
  // Main frame only (Android may also inject into iframes).
  if (window.top !== window) return;
  if (window.__AS_LOADED) return;
  window.__AS_LOADED = true;

  var cfg = window.__AS_CONFIG || {};
  var sel = window.__AS_SELECTORS || {};
  var css = window.__AS_CSS || '';
  var STYLE_ID = 'as-style';

  // ---------------------------------------------------------------- bridge
  var queue = [];
  function bridgeReady() {
    return !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler);
  }
  function send(msg) {
    try { window.flutter_inappwebview.callHandler('asEvent', msg); } catch (e) {}
  }
  function notify(type, data) {
    var msg = { type: type, data: data === undefined ? null : data };
    if (bridgeReady()) send(msg); else queue.push(msg);
  }
  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    queue.splice(0).forEach(send);
  });

  // ----------------------------------------------------------------- style
  function ensureStyle() {
    if (document.getElementById(STYLE_ID)) return;
    var s = document.createElement('style');
    s.id = STYLE_ID;
    s.textContent = css;
    (document.head || document.documentElement).appendChild(s);
  }

  function applyClasses() {
    var h = document.documentElement;
    if (!h) return;
    h.classList.toggle('as-block-reels', !!cfg.blockReels);
    h.classList.toggle('as-block-stories', !!cfg.blockStories);
    h.classList.toggle('as-block-explore', !!cfg.blockExplore);
    h.classList.toggle('as-block-suggested', !!cfg.blockSuggested);
  }

  // ---------------------------------------------------------------- routes
  function re(src) { try { return src ? new RegExp(src) : null; } catch (e) { return null; } }
  var paths = cfg.paths || {};
  var reReels = re(paths.reels);
  var reExplore = re(paths.explore);
  var reStories = re(paths.stories);
  var searchPath = sel.searchPath || '/explore/search/';

  function blockedFeature(p) {
    if (cfg.blockReels && reReels && reReels.test(p)) return 'reels';
    if (cfg.blockExplore && reExplore && reExplore.test(p)) return 'explore';
    if (cfg.blockStories && reStories && reStories.test(p)) return 'stories';
    return null;
  }

  var lastRedirect = 0;
  function onRoute() {
    var f = blockedFeature(location.pathname);
    if (!f) return;
    var now = Date.now();
    if (now - lastRedirect < 1000) return; // avoid loops
    lastRedirect = now;
    notify('blocked', { feature: f, path: location.pathname });
    location.replace(f === 'explore' ? searchPath : '/');
  }

  ['pushState', 'replaceState'].forEach(function (fn) {
    var orig = history[fn];
    history[fn] = function () {
      var r = orig.apply(this, arguments);
      try { onRoute(); } catch (e) {}
      return r;
    };
  });
  window.addEventListener('popstate', onRoute);

  // Link taps: first line of the URL guard (Dart's onLoadStart is the backup).
  var APP_SCHEMES = /^(instagram|intent|fb|market|itms-apps|itms-appss):/i;
  var IN_APP_HOSTS = /(^|\.)(instagram\.com|cdninstagram\.com|facebook\.com|fbcdn\.net|fbsbx\.com)$/i;
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest && e.target.closest('a[href]');
    if (!a) return;
    var href = a.getAttribute('href') || '';
    function stop() { e.preventDefault(); e.stopImmediatePropagation(); }

    // Never jump to the native Instagram app or an app store.
    if (APP_SCHEMES.test(href)) { stop(); return; }

    var url;
    try { url = new URL(href, location.href); } catch (err) { return; }
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return;

    // Other websites (incl. l.instagram.com link redirects) open outside.
    if (url.hostname === 'l.instagram.com' || !IN_APP_HOSTS.test(url.hostname)) {
      stop(); notify('open_external', url.href); return;
    }

    // The Search tab links to Explore. When Explore is blocked, keep search
    // but open the search-only page instead of the Explore grid.
    if (cfg.blockExplore && a.matches((sel.exploreNav || []).join(',') || 'x-none')) {
      stop(); location.assign(searchPath); return;
    }

    var f = /(^|\.)instagram\.com$/i.test(url.hostname) ? blockedFeature(url.pathname) : null;
    if (f) { stop(); notify('blocked', { feature: f, path: url.pathname }); }
  }, true);

  // ----------------------------------------------------------------- sweep
  function tag(el, token) {
    var cur = (el.getAttribute('data-as-tag') || '').split(' ').filter(Boolean);
    if (cur.indexOf(token) === -1) {
      cur.push(token);
      el.setAttribute('data-as-tag', cur.join(' '));
    }
  }

  function leafWithText(root, texts) {
    if (!texts || !texts.length) return [];
    var out = [];
    var nodes = root.querySelectorAll('span, div, h2, h3, button, a');
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      if (n.children.length) continue;
      var t = (n.textContent || '').trim();
      if (texts.indexOf(t) !== -1) out.push(n);
    }
    return out;
  }

  // Climb from a story item to the outermost wrapper that only holds the tray.
  function storyTray(item) {
    var el = item.parentElement; // the horizontal scroller
    if (!el) return null;
    while (el.parentElement && el.parentElement.children.length === 1 &&
           el.parentElement.tagName !== 'MAIN') {
      el = el.parentElement;
    }
    return el;
  }

  function sweepStories(main) {
    var items = main.querySelectorAll(sel.storyItem || '[aria-label^="Story by"]');
    var item = items[0] || leafWithText(main, sel.storyItemText)[0];
    if (!item) return false;
    // "Your story" text sits inside its item; climb to the role=button.
    if (!item.matches(sel.storyItem || '')) item = item.closest('[role="button"]') || item;
    var tray = storyTray(item);
    if (tray && !tray.contains(main.querySelector(sel.feedPost || 'article'))) {
      tag(tray, 'stories');
      return true;
    }
    return false;
  }

  function sweepPosts() {
    var posts = document.querySelectorAll(sel.feedPost || 'article');
    var reelSel = sel.reelLink || 'a[href*="/reel/"]';
    for (var i = 0; i < posts.length; i++) {
      var a = posts[i];
      if (a.querySelector(reelSel)) tag(a, 'reel');
      if (leafWithText(a, sel.suggestedText).length) tag(a, 'suggested');
    }
  }

  function sweepOpenApp() {
    var hits = leafWithText(document.body, sel.openAppText);
    for (var i = 0; i < hits.length; i++) {
      var el = hits[i];
      // Hide the whole fixed banner if there is one, else just the button.
      var target = el, p = el;
      for (var d = 0; p && d < 6; d++, p = p.parentElement) {
        if (getComputedStyle(p).position === 'fixed') { target = p; break; }
      }
      tag(target, 'openapp');
    }
  }

  var foundStories = false;
  function sweep() {
    if (!document.body) return;
    ensureStyle();
    var main = document.querySelector('main') || document.body;
    if (sweepStories(main)) foundStories = true;
    sweepPosts();
    sweepOpenApp();
  }

  // ------------------------------------------------------- observe + boot
  var pending = false;
  var observer = new MutationObserver(function () {
    if (pending) return;
    pending = true;
    requestAnimationFrame(function () { pending = false; sweep(); });
  });

  function healthCheck() {
    if (location.pathname !== '/') return;
    var missing = [];
    if (!document.querySelector((sel.reelsNav || []).join(',') || 'x-none')) missing.push('reelsNav');
    if (!document.querySelector((sel.exploreNav || []).join(',') || 'x-none')) missing.push('exploreNav');
    if (!document.querySelector(sel.feedPost || 'article')) missing.push('feedPost');
    if (!foundStories) missing.push('storyTray');
    if (missing.length) notify('selector_missing', missing);
  }

  function boot() {
    sweep();
    observer.observe(document.body, { childList: true, subtree: true });
    setTimeout(healthCheck, 6000);
  }

  window.__AS_ENSURE = function () { ensureStyle(); applyClasses(); sweep(); };
  window.__AS_UPDATE = function (next) {
    for (var k in next) cfg[k] = next[k];
    applyClasses(); sweep(); onRoute();
  };

  ensureStyle();
  applyClasses();
  onRoute();
  if (document.body) boot();
  else document.addEventListener('DOMContentLoaded', boot);
  notify('loaded', location.pathname);
})();
