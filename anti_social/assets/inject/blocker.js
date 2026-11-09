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
    // Each story bubble in the tray: a button labelled "Story by <name>, ...".
    storyItem: 'main [role="button"][aria-label^="Story by"], main a[href*="/stories/"]',
    storyButton: 'main [role="button"]',
    feedArticle: 'article',
    postLink: 'a[href*="/p/"], a[href*="/reel/"], time',
    appNagCandidates: 'a, button, [role="button"]',
    loggedInMarker: 'a[href^="/direct/"]',
    // App chrome (restyled by skin.css)
    homeTab: 'a[href="/"]',
    inboxTab: 'a[href="/direct/inbox/"]',
    logo: 'svg[aria-label="Instagram"]',
    activityLink: 'a[href="/notifications/"]',
    createLink: 'a[href="#"], input[type="file"]',
    // Instagram's spinner; replaced with skeleton placeholders (skin.css).
    loader: '[role="progressbar"][data-visualcompletion="loading-state"]'
  };

  var TEXT = {
    suggested: ['Suggested for you', 'Suggested posts', 'Suggested reels'],
    // Exact text of the small label under the author name on ads.
    adLabels: ['Ad', 'Sponsored'],
    yourStory: 'Your story',
    // Headings of "people you may know" carousels between feed posts.
    suggestionHeadings: ['Suggestions for you', 'Suggested for you'],
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
    h.classList.toggle('as-block-feed-videos', !!cfg.blockFeedVideos);
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
  var currentPath = location.pathname, prevPath = null;
  function onRoute(force) {
    if (!force && location.href === lastHref) return;
    lastHref = location.href;
    if (location.pathname !== currentPath) {
      prevPath = currentPath;
      currentPath = location.pathname;
    }
    if (document.body) { markActiveTab(); ensureFallbackTabbar(); }
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
      var before = location.pathname;
      var r = orig.apply(this, arguments);
      if (fn === 'pushState' && location.pathname !== before) {
        animateNav(Date.now() - tabTapAt < 800 ? 'tab' : 'push');
      }
      onRoute(false);
      return r;
    };
  });
  window.addEventListener('popstate', function () {
    animateNav(Date.now() - tabTapAt < 800 ? 'tab' : 'pop');
    onRoute(false);
  });

  // ---- Page transitions (iOS-like) ------------------------------------------
  // Push slides the new page in from the right, back/tab switches cross-fade.
  // Alternating -a/-b class names restart the CSS animation without forcing
  // a layout. Only transform/opacity animate, so it stays on the GPU.
  var tabTapAt = 0, navFlip = false, navTimer = null;
  var reduceMotion = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  function animateNav(kind) {
    var h = document.documentElement;
    if (!h || reduceMotion) return;
    navFlip = !navFlip;
    var cls = 'as-nav-' + kind + (navFlip ? '-a' : '-b');
    h.className = h.className.replace(/\bas-nav-\S+/g, '').trim();
    h.classList.add(cls);
    clearTimeout(navTimer);
    navTimer = setTimeout(function () { h.classList.remove(cls); }, 450);
  }
  // Tab taps: remember (for the transition type) and send a haptic tick.
  document.addEventListener('click', function (e) {
    var t = e.target;
    if (t && t.closest && t.closest('[data-as-tab], #as-tabbar [data-href]')) {
      tabTapAt = Date.now();
      notify('haptic', null);
    }
  }, true);

  // ---- 5. Sweep: tag what CSS can't target ------------------------------
  // While the user scrolls, only the cheap "must hide before it's visible"
  // work runs; the rest waits until scrolling pauses.
  var lastScrollAt = 0;
  window.addEventListener('scroll', function () { lastScrollAt = Date.now(); }, { passive: true, capture: true });
  function isScrolling() { return Date.now() - lastScrollAt < 200; }

  // textContent, NOT innerText: innerText forces a layout pass on every
  // read, which made scrolling stutter.
  function textOf(el) {
    return (el && el.textContent) || '';
  }

  // True if a leaf <span> inside root reads exactly one of labels.
  function hasExactLabel(root, labels) {
    var spans = root.querySelectorAll('span');
    for (var i = 0; i < spans.length; i++) {
      if (spans[i].childElementCount) continue;
      if (labels.indexOf((spans[i].textContent || '').trim()) !== -1) return true;
    }
    return false;
  }

  function tagArticles() {
    var articles = document.querySelectorAll(SELECTORS.feedArticle + ':not([data-as-done])');
    for (var i = 0; i < articles.length; i++) {
      var a = articles[i];
      if (a.querySelector(SELECTORS.reelLink)) a.setAttribute('data-as-reel', '1');
      var t = textOf(a);
      var suggested = hasExactLabel(a, TEXT.adLabels);
      for (var j = 0; !suggested && j < TEXT.suggested.length; j++) {
        if (t.indexOf(TEXT.suggested[j]) !== -1) suggested = true;
      }
      if (suggested) a.setAttribute('data-as-suggested', '1');
      // Stop re-checking once the post has fully rendered.
      if (t.length > 40 && a.querySelector(SELECTORS.postLink)) a.setAttribute('data-as-done', '1');
    }
  }

  // The first story bubble that isn't inside a feed post (posts can have
  // story rings on their avatars too).
  function firstStoryItem() {
    var items = document.querySelectorAll(SELECTORS.storyItem);
    for (var i = 0; i < items.length; i++) {
      if (!items[i].closest('article')) return items[i];
    }
    // Only your own bubble in the tray: find it by its label.
    var buttons = document.querySelectorAll(SELECTORS.storyButton);
    for (var k = 0; k < buttons.length; k++) {
      var b = buttons[k];
      if (!b.closest('article') && textOf(b).indexOf(TEXT.yourStory) !== -1) return b;
    }
    return null;
  }

  function findStoriesTray() {
    if (document.querySelector('[data-as-stories-tray]')) return true;
    var item = firstStoryItem();
    if (!item) return false;
    var main = item.closest('main');
    // Wait for the feed: the tray is the outermost box around the stories
    // that does NOT also contain feed posts.
    if (!main || !main.querySelector('article')) return false;
    outermostNonPost(item, main).setAttribute('data-as-stories-tray', '1');
    return true;
  }

  // Climb from el to the outermost box that does not contain feed posts
  // (or another tagged block): that box is one feed item / the tray.
  function outermostNonPost(el, main) {
    while (el.parentElement && el.parentElement !== main &&
           !el.parentElement.querySelector('article, [data-as-stories-tray], [data-as-suggested]')) {
      el = el.parentElement;
    }
    return el;
  }

  // "Suggestions for you" people carousels (outside any post). XPath does
  // the text match natively, which is much cheaper than walking spans.
  var suggestionXPath = '//main//span[not(ancestor::article)][not(ancestor::*[@data-as-suggested])][' +
    TEXT.suggestionHeadings.map(function (t) { return 'normalize-space(.)="' + t + '"'; }).join(' or ') + ']';
  function tagSuggestionBlocks() {
    var main = document.querySelector('main');
    if (!main || !main.querySelector('article')) return;
    var hits = document.evaluate(suggestionXPath, document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    for (var i = 0; i < hits.snapshotLength; i++) {
      var span = hits.snapshotItem(i);
      if (span.closest('[data-as-suggested]')) continue;
      outermostNonPost(span, main).setAttribute('data-as-suggested', '1');
    }
  }

  var nagChecked = typeof WeakSet === 'function' ? new WeakSet() : null;
  function tagAppNags() {
    var els = document.querySelectorAll(SELECTORS.appNagCandidates);
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.hasAttribute('data-as-app-nag') || (nagChecked && nagChecked.has(el))) continue;
      var t = textOf(el).trim();
      if (t.length && nagChecked) nagChecked.add(el);
      if (t.length && t.length < 20 && TEXT.appNag.indexOf(t) !== -1) {
        el.setAttribute('data-as-app-nag', '1');
        hideNagBanner(el);
      }
    }
    // A floating banner left with nothing but its "Close" button.
    var closes = document.querySelectorAll('svg[aria-label="Close"]');
    for (var k = 0; k < closes.length; k++) {
      var box = fixedAncestor(closes[k]);
      if (box && isFloatingBanner(box) && textOf(box).trim() === 'Close') {
        box.setAttribute('data-as-app-nag', '1');
      }
    }
  }

  function fixedAncestor(el) {
    el = el.parentElement;
    while (el && el !== document.body && getComputedStyle(el).position !== 'fixed') el = el.parentElement;
    return el && el !== document.body ? el : null;
  }

  // A fixed box that is not the page itself, the header or the tab bar.
  function isFloatingBanner(box) {
    return !box.hasAttribute('data-as-tabbar-wrap') &&
      !box.querySelector('main, [data-as-header], [data-as-tabbar], [data-as-tabbar-wrap]');
  }

  // Hide the whole "Open app" banner (including its close button), not just
  // the button inside it.
  function hideNagBanner(el) {
    var box = fixedAncestor(el);
    if (box && isFloatingBanner(box)) box.setAttribute('data-as-app-nag', '1');
  }

  // ---- Native skin: tag Instagram's header and tab bar -------------------
  // The direct child of parent that contains el.
  function childContaining(parent, el) {
    while (el && el.parentElement !== parent) el = el.parentElement;
    return el;
  }

  function tabName(href) {
    if (href === '/') return 'home';
    if (href.indexOf('/explore') === 0) return 'explore';
    if (href.indexOf('/reels') === 0) return 'reels';
    if (href.indexOf('/direct') === 0) return 'direct';
    return 'profile';
  }

  function tagTabBar() {
    var inbox = document.querySelector(SELECTORS.inboxTab);
    if (!inbox || inbox.closest('[data-as-tabbar]')) return;
    var row = inbox.parentElement;
    while (row && row !== document.body && !row.querySelector(SELECTORS.homeTab)) row = row.parentElement;
    if (!row || row === document.body) return;
    row.setAttribute('data-as-tabbar', '1');
    for (var i = 0; i < row.children.length; i++) {
      var a = row.children[i].querySelector('a[href]');
      if (a) row.children[i].setAttribute('data-as-tab', tabName(a.getAttribute('href')));
    }
    // Strip the full-width bar styling from the fixed wrapper down to the row.
    var el = row.parentElement;
    while (el && el !== document.body) {
      if (getComputedStyle(el).position === 'fixed') { el.setAttribute('data-as-tabbar-wrap', '1'); break; }
      el.setAttribute('data-as-tabbar-chain', '1');
      el = el.parentElement;
    }
  }

  function markActiveTab() {
    var row = document.querySelector('[data-as-tabbar]');
    document.documentElement.classList.toggle('as-has-tabbar',
      !!row || document.documentElement.classList.contains('as-fallback-tabbar'));
    if (!row) return;
    cacheTabIcons(row);
    var p = location.pathname;
    var active = p === '/' ? 'home'
      : p.indexOf('/direct') === 0 ? 'direct'
      : p.indexOf('/explore') === 0 ? 'explore'
      : (p.indexOf('/reels') === 0 || p.indexOf('/reel/') === 0) ? 'reels' : null;
    var tabs = row.querySelectorAll('[data-as-tab]');
    for (var i = 0; i < tabs.length; i++) {
      var t = tabs[i], name = t.getAttribute('data-as-tab');
      var on = name === active;
      if (!active && name === 'profile') {
        var a = t.querySelector('a[href]');
        on = !!a && norm(a.getAttribute('href')) === norm(p);
      }
      if (on) t.setAttribute('data-as-tab-active', '1'); else t.removeAttribute('data-as-tab-active');
    }
  }

  function tagHeader() {
    var logo = document.querySelector(SELECTORS.logo);
    if (!logo || logo.closest('[data-as-header]')) return;
    var activity = document.querySelector(SELECTORS.activityLink);
    if (!activity) return;
    var hdr = logo.parentElement;
    while (hdr && hdr !== document.body && !hdr.contains(activity)) hdr = hdr.parentElement;
    if (!hdr || hdr === document.body) return;
    var logoBlock = childContaining(hdr, logo);
    var right = childContaining(hdr, activity);
    if (!logoBlock || !right || logoBlock === right) return;
    hdr.setAttribute('data-as-header', '1');
    logoBlock.setAttribute('data-as-hdr-logo', '1');
    right.setAttribute('data-as-hdr-right', '1');
    for (var i = 0; i < right.children.length; i++) {
      var c = right.children[i];
      if (c.contains(activity)) c.setAttribute('data-as-hdr-activity', '1');
      else if (c.querySelector(SELECTORS.createLink)) c.setAttribute('data-as-hdr-create', '1');
    }
  }

  // Our settings button lives on <body>, outside React's tree, so Instagram
  // re-rendering can't remove it.
  var SETTINGS_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
    'stroke-linecap="round" aria-hidden="true"><line x1="4" y1="7" x2="20" y2="7"/>' +
    '<line x1="4" y1="17" x2="20" y2="17"/><circle cx="9" cy="7" r="2.4" fill="currentColor" stroke="none"/>' +
    '<circle cx="15" cy="17" r="2.4" fill="currentColor" stroke="none"/></svg>';
  function ensureSettingsButton() {
    if (!document.body || document.getElementById('as-settings')) return;
    var b = document.createElement('button');
    b.id = 'as-settings';
    b.type = 'button';
    b.setAttribute('aria-label', 'Blocking settings');
    b.innerHTML = SETTINGS_ICON;
    b.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      notify('open_settings', null);
    });
    document.body.appendChild(b);
  }

  // Nudge popovers inside the tab bar's fixed wrapper: hide the absolutely
  // positioned box around any "Close" button that isn't part of the tabs.
  function tagTabBarPopovers() {
    var wrap = document.querySelector('[data-as-tabbar-wrap]');
    if (!wrap) return;
    var closes = wrap.querySelectorAll('svg[aria-label="Close"]');
    for (var i = 0; i < closes.length; i++) {
      if (closes[i].closest('[data-as-tabbar], [data-as-tabbar-popover]')) continue;
      var el = closes[i].parentElement;
      while (el && el !== wrap && getComputedStyle(el).position !== 'absolute') el = el.parentElement;
      if (el && el !== wrap) el.setAttribute('data-as-tabbar-popover', '1');
    }
  }

  // ---- Empty feed: everything left was blocked ----------------------------
  // Decided from our own tags + config (no layout reads, so no scroll jank).
  function isHiddenPost(a) {
    return (cfg.blockFeedVideos && a.hasAttribute('data-as-reel')) ||
           (cfg.blockSuggested && a.hasAttribute('data-as-suggested'));
  }

  function updateFeedState() {
    var onFeed = norm(location.pathname) === '/' && !!document.querySelector(SELECTORS.inboxTab);
    var posts = onFeed ? document.querySelectorAll('main ' + SELECTORS.feedArticle) : [];
    var hidden = 0;
    for (var i = 0; i < posts.length; i++) if (isHiddenPost(posts[i])) hidden++;
    var empty = posts.length > 0 && hidden === posts.length;
    document.documentElement.classList.toggle('as-feed-empty', empty);
    if (!empty) return;
    var note = document.getElementById('as-feed-note');
    if (!note) {
      note = document.createElement('div');
      note.id = 'as-feed-note';
      note.innerHTML = '<div class="as-note-title">You\u2019re all caught up</div><div class="as-note-body"></div>';
      document.body.appendChild(note);
    }
    var body = note.querySelector('.as-note-body');
    var text = 'AntiSocial hid ' + hidden + (hidden === 1 ? ' post' : ' posts') +
      ' (reels, ads and suggestions). Check back later for new posts from people you follow.';
    if (body.textContent !== text) body.textContent = text;
  }

  // ---- Fallback tab bar ------------------------------------------------------
  // Instagram's web app removes its tab bar on the DM inbox. We draw our own
  // there (outside React), with Instagram's own icons cached from the real
  // tab bar when we last saw it, or simple outline icons as a fallback.
  var ICON_KEY = 'as_tab_icons_v1';
  var GENERIC_ICONS = {
    home: '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
    reels: '<rect x="3" y="3" width="18" height="18" rx="5"/><path d="M10 8.5v7l6-3.5z"/>',
    direct: '<path d="M21.5 2.5 2.5 9.5l7.5 3 3 7.5z"/><path d="M10 12.5l11.5-10"/>',
    explore: '<circle cx="11" cy="11" r="7"/><path d="m20.5 20.5-4.5-4.5"/>',
    profile: '<circle cx="12" cy="8.5" r="4"/><path d="M4 21c.5-4 4-6 8-6s7.5 2 8 6"/>'
  };
  var TAB_ORDER = ['home', 'reels', 'direct', 'explore', 'profile'];
  var iconCacheSaved = '';

  function readIconCache() {
    try { return JSON.parse(localStorage.getItem(ICON_KEY) || '{}') || {}; } catch (e) { return {}; }
  }

  // Store each tab's icon while that tab is NOT active (inactive = outline).
  function cacheTabIcons(row) {
    var cache = readIconCache(), changed = false;
    var tabs = row.querySelectorAll('[data-as-tab]');
    for (var i = 0; i < tabs.length; i++) {
      var t = tabs[i], name = t.getAttribute('data-as-tab');
      var a = t.querySelector('a[href]');
      if (!a) continue;
      var href = a.getAttribute('href');
      var icon = a.querySelector('svg, img');
      var entry = cache[name] || {};
      if (entry.href !== href) { entry.href = href; changed = true; }
      if (icon && !t.hasAttribute('data-as-tab-active') && entry.html !== icon.outerHTML) {
        entry.html = icon.outerHTML; changed = true;
      }
      cache[name] = entry;
    }
    if (!changed) return;
    var json = JSON.stringify(cache);
    if (json === iconCacheSaved) return;
    iconCacheSaved = json;
    try { localStorage.setItem(ICON_KEY, json); } catch (e) { /* storage blocked */ }
  }

  function isFallbackPage() {
    var p = location.pathname;
    return p.indexOf('/direct/inbox') === 0 || p.indexOf('/direct/requests') === 0;
  }

  function buildFallbackTabbar() {
    var cache = readIconCache();
    var nav = document.createElement('nav');
    nav.id = 'as-tabbar';
    var html = '';
    TAB_ORDER.forEach(function (name) {
      if (name === 'reels' && cfg.blockReels) return;
      var href = (cache[name] && cache[name].href) ||
        { home: '/', reels: '/reels/', direct: '/direct/inbox/', explore: '/explore/' }[name];
      if (!href) return; // profile link unknown until we've seen the real tab bar
      var icon = (cache[name] && cache[name].html) ||
        '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">' +
        GENERIC_ICONS[name] + '</svg>';
      html += '<div class="as-tab" data-tab="' + name + '" data-href="' + href + '">' + icon + '</div>';
    });
    nav.innerHTML = html;
    nav.addEventListener('click', function (e) {
      var tab = e.target.closest('[data-href]');
      if (!tab) return;
      e.preventDefault();
      goToTab(tab.getAttribute('data-href'));
    });
    return nav;
  }

  // Instagram's router ignores programmatic pushState, so: real "back" when
  // returning to the page we came from (instant, SPA), otherwise a normal load
  // (the Flutter skeleton covers it).
  function goToTab(href) {
    if (norm(href) === norm(location.pathname)) return;
    if (prevPath && norm(prevPath) === norm(href) && history.length > 1) {
      history.back();
    } else {
      location.assign(href);
    }
  }

  function ensureFallbackTabbar() {
    var h = document.documentElement;
    var want = !document.querySelector('[data-as-tabbar]') && isFallbackPage();
    h.classList.toggle('as-fallback-tabbar', want);
    var bar = document.getElementById('as-tabbar');
    if (!want) return;
    if (!bar) { bar = buildFallbackTabbar(); document.body.appendChild(bar); }
    var p = location.pathname;
    var active = p.indexOf('/direct') === 0 ? 'direct' : null;
    var tabs = bar.querySelectorAll('.as-tab');
    for (var i = 0; i < tabs.length; i++) {
      tabs[i].classList.toggle('as-tab-active', tabs[i].getAttribute('data-tab') === active);
    }
    h.classList.add('as-has-tabbar');
  }

  // ---- Skeleton loaders -------------------------------------------------------
  // Tag Instagram's spinners so skin.css draws shimmering placeholders that
  // fit the page: a post on the feed, list rows elsewhere. Spinners inside
  // buttons/links/dialogs keep their normal look.
  function tagLoaders() {
    var loaders = document.querySelectorAll(SELECTORS.loader + ':not([data-as-skel])');
    if (!loaders.length) return;
    var kind = norm(location.pathname) === '/' ? 'post' : 'rows';
    for (var i = 0; i < loaders.length; i++) {
      var el = loaders[i];
      var inline = el.closest('button, a, [role="button"], [role="dialog"]');
      el.setAttribute('data-as-skel', inline ? 'none' : kind);
    }
  }

  // ---- Reels page: full-screen reels like the native app ---------------------
  // Instagram sizes the reels scroller for its old full-width tab bar (79px
  // short) while each reel is drawn full height, so reels overlap and drift.
  // We make the scroller full-screen (skin.css) and lift each reel's caption
  // overlay above the floating tab bar.
  function tagReelsPage() {
    var h = document.documentElement;
    var on = location.pathname.indexOf('/reels') === 0;
    h.classList.toggle('as-reels-page', on);
    if (!on) return;
    var sc = document.querySelector('[data-as-reels-scroller]');
    if (!sc) {
      var v = document.querySelector('main video');
      var el = v && v.parentElement;
      while (el && el.tagName !== 'MAIN' && getComputedStyle(el).position !== 'fixed') el = el.parentElement;
      if (!el || el.tagName === 'MAIN') return;
      el.setAttribute('data-as-reels-scroller', '1');
      sc = el;
    }
    for (var i = 0; i < sc.children.length; i++) {
      var item = sc.children[i];
      if (item.hasAttribute('data-as-reel-done')) continue;
      var overlay = findReelOverlay(item);
      if (overlay) {
        overlay.setAttribute('data-as-reel-overlay', '1');
        item.setAttribute('data-as-reel-done', '1');
      }
    }
  }

  // The deepest full-height, bottom-anchored box with text = the caption,
  // author and action buttons. Checked once per reel.
  function findReelOverlay(item) {
    var itemH = item.clientHeight || 1, best = null, bestDepth = -1;
    var divs = item.querySelectorAll('div');
    for (var i = 0; i < divs.length; i++) {
      var d = divs[i];
      var cs = getComputedStyle(d);
      if (cs.position !== 'absolute' || cs.bottom !== '0px') continue;
      if (d.clientHeight < itemH * 0.5 || !(d.textContent || '').trim()) continue;
      var depth = 0, e = d;
      while (e && e !== item) { depth++; e = e.parentElement; }
      if (depth > bestDepth) { best = d; bestDepth = depth; }
    }
    return best;
  }

  // Tell Dart once per page when Instagram's shell is on screen, so the
  // launch skeleton can fade out.
  var shellNotified = false;
  function notifyShellReady() {
    if (shellNotified) return;
    if (document.querySelector('[data-as-tabbar], [data-as-header], main')) {
      shellNotified = true;
      notify('shell_ready', null);
    }
  }

  function tagChrome() {
    tagTabBar();
    tagTabBarPopovers();
    markActiveTab();
    ensureFallbackTabbar();
    tagHeader();
    ensureSettingsButton();
  }

  // Light work: runs on every sweep (posts must be hidden before they scroll
  // into view; chrome and loaders are cheap once tagged).
  function sweep() {
    if (!document.body) return;
    ensureStyle();
    applyClasses();
    tagArticles();
    tagChrome();
    tagLoaders();
    tagReelsPage();
    updateFeedState();
    notifyShellReady();
    onRoute(false);
    if (isScrolling()) scheduleHeavy(); else heavySweep();
  }

  // Heavier whole-page searches: skipped while scrolling.
  var lastHeavyAt = 0, heavyTimer = null;
  function heavySweep() {
    if (Date.now() - lastHeavyAt < 250) { scheduleHeavy(); return; }
    lastHeavyAt = Date.now();
    findStoriesTray();
    tagSuggestionBlocks();
    tagAppNags();
  }
  function scheduleHeavy() {
    if (heavyTimer) return;
    heavyTimer = setTimeout(function () {
      heavyTimer = null;
      if (isScrolling()) scheduleHeavy(); else heavySweep();
    }, 300);
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
    var bar = document.getElementById('as-tabbar');
    if (bar) bar.remove();
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
