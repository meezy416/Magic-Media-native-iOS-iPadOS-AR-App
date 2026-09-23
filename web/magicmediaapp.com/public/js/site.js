/* ==========================================================================
   MAGIC MEDIA — scroll choreography
   Lenis (smooth scroll) + GSAP ScrollTrigger (pinned, scrubbed timelines).
   ========================================================================== */

(function () {
  'use strict';

  var REDUCED = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var FINE = window.matchMedia('(hover: hover) and (pointer: fine)').matches;

  /* The animation layer is a progressive enhancement. If the CDN is blocked,
     offline, or slow past the point of usefulness, lift the curtain and serve
     the page as plain scrolling content rather than a black screen. */
  function degrade() {
    var pre = document.getElementById('preloader');
    if (pre) pre.parentNode.removeChild(pre);
    document.body.classList.remove('has-cursor');
    var cur = document.getElementById('cursor');
    if (cur) cur.style.display = 'none';
  }

  if (typeof gsap === 'undefined' || typeof ScrollTrigger === 'undefined') {
    window.addEventListener('DOMContentLoaded', degrade);
    degrade();
    return;
  }

  gsap.registerPlugin(ScrollTrigger, ScrollToPlugin);

  /* ----------------------------------------------------------------------
     Utilities
     ---------------------------------------------------------------------- */

  function $(s, c) { return (c || document).querySelector(s); }

  /* Viewport height. Falls back through the layout viewport and finally a
     sane constant — some embedded/pre-paint contexts report 0, which would
     otherwise collapse every pinned section to zero scroll length. */
  function vh() {
    return window.innerHeight
      || document.documentElement.clientHeight
      || (window.screen && window.screen.height)
      || 800;
  }
  function $$(s, c) { return Array.prototype.slice.call((c || document).querySelectorAll(s)); }

  /* Split a display heading into masked lines.
     Source markup uses newlines as intentional line breaks, so we split on
     those rather than measuring — keeps the break points art-directed. */
  function splitLines(el) {
    if (el.dataset.splitDone) return $$('.line-i', el);
    var html = el.innerHTML;
    var parts = html.split(/\n/).map(function (s) { return s.trim(); }).filter(Boolean);
    el.innerHTML = parts.map(function (p) {
      return '<span class="line"><span class="line-i">' + p + '</span></span>';
    }).join('');
    el.dataset.splitDone = '1';
    return $$('.line-i', el);
  }

  /* ----------------------------------------------------------------------
     Preloader — counter is driven by real asset progress
     ---------------------------------------------------------------------- */

  var TT_FRAMES = 48;
  var ttImages = [];
  var ttLoaded = 0;

  function preload(done) {
    var bar = $('#preloader .bar');
    var countEl = $('[data-count]');
    var heroVid = $('[data-hero-video]');

    var jobs = TT_FRAMES + 1;       // turntable frames + hero video
    var finished = 0;
    var shown = 0;                  // displayed number, eased toward real
    var real = 0;

    function bump() {
      finished++;
      real = Math.min(100, Math.round((finished / jobs) * 100));
    }

    // turntable frames
    for (var i = 0; i < TT_FRAMES; i++) {
      (function (n) {
        var img = new Image();
        img.onload = img.onerror = function () { ttLoaded++; bump(); };
        img.src = '/media/tt/f' + String(n).padStart(2, '0') + '.webp';
        ttImages[n] = img;
      })(i);
    }

    // hero video — enough data to play through
    if (heroVid) {
      var vdone = false;
      var finish = function () { if (!vdone) { vdone = true; bump(); } };
      heroVid.addEventListener('canplaythrough', finish, { once: true });
      heroVid.addEventListener('error', finish, { once: true });
      setTimeout(finish, 6000);   // never let a stalled network hold the gate
      heroVid.load();
    } else { bump(); }

    // Ease the displayed counter toward the real figure. Time-based rather
    // than per-tick, so a throttled or background tab lands at the same place
    // a 120Hz one does. MAX_WAIT guarantees the curtain always lifts.
    var MIN_SHOW = 600;     // let the counter be seen even on a warm cache
    var MAX_WAIT = 9000;    // hard ceiling regardless of asset state
    var t0 = performance.now();
    var last = t0;
    var fired = false;

    function finishOnce() {
      if (fired) return;
      fired = true;
      countEl.textContent = 100;
      bar.style.width = '100%';
      setTimeout(done, 260);
    }

    function frame(now) {
      var dt = Math.min((now - last) / 1000, 0.1);   // clamp long gaps
      last = now;
      var elapsed = now - t0;

      // exponential approach, framerate independent
      var target = elapsed > MAX_WAIT ? 100 : real;
      shown += (target - shown) * (1 - Math.pow(0.0001, dt));
      if (target - shown < 0.4) shown = target;

      countEl.textContent = Math.floor(shown);
      bar.style.width = shown.toFixed(2) + '%';

      if (shown >= 100 && elapsed >= MIN_SHOW) { finishOnce(); return; }
      requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);

    // rAF is paused entirely while the tab is hidden; if the visitor opens the
    // site in a background tab, settle it up on return rather than stalling.
    document.addEventListener('visibilitychange', function () {
      if (!document.hidden) { last = performance.now(); }
    });
    setTimeout(finishOnce, MAX_WAIT + 500);

    // rotating crosshair ticks
    if (!REDUCED) {
      $$('#preloader .ticks span').forEach(function (s, n) {
        gsap.to(s, {
          rotation: '+=360', duration: 3.2 + n * 0.9,
          repeat: -1, ease: 'none', transformOrigin: '50% 0'
        });
      });
    }
  }

  function revealSite() {
    var tl = gsap.timeline();
    tl.to('#preloader .count', {
      scale: REDUCED ? 1 : 1.35, opacity: 0,
      duration: 0.9, ease: 'power3.inOut'
    })
      .to('#preloader .meta, #preloader .meta-r, #preloader .bar',
        { opacity: 0, duration: 0.4 }, 0)
      .to('#preloader', {
        yPercent: -100, duration: 1.05, ease: 'expo.inOut',
        onComplete: function () { $('#preloader').remove(); ScrollTrigger.refresh(); }
      }, 0.45)
      .add(introduce, '-=0.55');
  }

  /* ----------------------------------------------------------------------
     Intro — hero type lifts in behind the curtain
     ---------------------------------------------------------------------- */

  function introduce() {
    var h1lines = splitLines($('#hero h1'));
    var tl = gsap.timeline();

    tl.fromTo(h1lines,
      { yPercent: 115 },
      { yPercent: 0, duration: 1.25, ease: 'expo.out', stagger: 0.09 })
      .fromTo('#hero .sub', { opacity: 0, y: 24 },
        { opacity: 1, y: 0, duration: 0.9, ease: 'power3.out' }, '-=0.75')
      .fromTo('.brand, .menu-btn, .tracker, .scroll-cue, .corner-r',
        { opacity: 0 }, { opacity: 1, duration: 0.8, stagger: 0.06 }, '-=0.9');

    var v = $('[data-hero-video]');
    if (v) { var p = v.play(); if (p && p.catch) p.catch(function () {}); }
  }

  /* ----------------------------------------------------------------------
     Smooth scroll
     ---------------------------------------------------------------------- */

  var lenis = null;

  function initSmooth() {
    if (REDUCED || typeof Lenis === 'undefined') return;

    lenis = new Lenis({
      duration: 1.25,
      // long, cinematic tail — the drift both reference sites have
      easing: function (t) { return Math.min(1, 1.001 - Math.pow(2, -10 * t)); },
      smoothWheel: true,
      touchMultiplier: 1.6
    });

    lenis.on('scroll', ScrollTrigger.update);
    gsap.ticker.add(function (time) { lenis.raf(time * 1000); });
    gsap.ticker.lagSmoothing(0);
  }

  function scrollTo(target) {
    if (lenis) lenis.scrollTo(target, { offset: 0, duration: 1.4 });
    else gsap.to(window, { scrollTo: target, duration: 0.8, ease: 'power2.inOut' });
  }

  /* ----------------------------------------------------------------------
     Custom cursor
     ---------------------------------------------------------------------- */

  function initCursor() {
    if (!FINE || REDUCED) return;
    var cur = $('#cursor');
    document.body.classList.add('has-cursor');

    var x = gsap.quickTo(cur, 'x', { duration: 0.35, ease: 'power3' });
    var y = gsap.quickTo(cur, 'y', { duration: 0.35, ease: 'power3' });

    window.addEventListener('pointermove', function (e) {
      x(e.clientX); y(e.clientY);
      document.documentElement.style.setProperty('--mx', e.clientX + 'px');
      document.documentElement.style.setProperty('--my', e.clientY + 'px');
    });

    var textEl = $('[data-cursor-text]');

    document.addEventListener('pointerover', function (e) {
      var t = e.target.closest('[data-cursor]');
      if (t) {
        var word = t.dataset.cursor.toUpperCase();
        var unit = ' • ' + word;
        textEl.textContent = unit.repeat(4);
        cur.classList.add('is-label');
        return;
      }
      if (e.target.closest('a, button')) cur.classList.add('is-wide');
    });

    document.addEventListener('pointerout', function (e) {
      if (e.target.closest('[data-cursor]')) cur.classList.remove('is-label');
      if (e.target.closest('a, button')) cur.classList.remove('is-wide');
    });
  }

  /* ----------------------------------------------------------------------
     Menu — circular clip wipe out of the button
     ---------------------------------------------------------------------- */

  function initMenu() {
    var btn = $('#menuBtn');
    var menu = $('#menu');

    function setOrigin() {
      var r = btn.getBoundingClientRect();
      document.documentElement.style.setProperty('--mx', (r.left + r.width / 2) + 'px');
      document.documentElement.style.setProperty('--my', (r.top + r.height / 2) + 'px');
    }

    function toggle(open) {
      setOrigin();
      document.body.classList.toggle('menu-open', open);
      btn.setAttribute('aria-expanded', String(open));
      menu.setAttribute('aria-hidden', String(!open));
      if (lenis) { open ? lenis.stop() : lenis.start(); }
    }

    btn.addEventListener('click', function () {
      toggle(!document.body.classList.contains('menu-open'));
    });

    $$('[data-menu-link]').forEach(function (a) {
      a.addEventListener('click', function (e) {
        e.preventDefault();
        toggle(false);
        setTimeout(function () { scrollTo(a.getAttribute('href')); }, 620);
      });
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && document.body.classList.contains('menu-open')) toggle(false);
    });
  }

  /* ----------------------------------------------------------------------
     Hero — slow push-in while the section scrolls away
     ---------------------------------------------------------------------- */

  function initHero() {
    var plate = $('#hero .plate video') || $('#hero .plate img');
    if (plate) {
      gsap.fromTo(plate, { scale: 1.18 }, {
        scale: 1, ease: 'none',
        scrollTrigger: { trigger: '#hero', start: 'top top', end: 'bottom top', scrub: 1 }
      });
    }

    // headline drifts up faster than the plate — parallax depth
    gsap.to('#hero .headline', {
      yPercent: -28, opacity: 0.25, ease: 'none',
      scrollTrigger: { trigger: '#hero', start: 'top top', end: 'bottom top', scrub: 1 }
    });

    gsap.to('#scrollCue', {
      opacity: 0, duration: 0.4,
      scrollTrigger: { trigger: '#hero', start: 'top+=120 top', toggleActions: 'play none none reverse' }
    });

    // the fixed clock would otherwise sit on top of the footer line
    gsap.to('#cornerR', {
      opacity: 0, duration: 0.4,
      scrollTrigger: { trigger: 'footer.foot', start: 'top 92%', toggleActions: 'play none none reverse' }
    });
  }

  /* ----------------------------------------------------------------------
     Ticker — continuous marquee, nudged by scroll velocity
     ---------------------------------------------------------------------- */

  function initTicker() {
    var track = $('[data-ticker]');
    if (!track) return;

    // duplicate until the track comfortably overflows, so the loop is seamless
    var original = track.innerHTML;
    while (track.scrollWidth < (window.innerWidth || 1280) * 2) track.innerHTML += original;

    if (REDUCED) return;

    var half = track.scrollWidth / 2;
    var tl = gsap.to(track, {
      x: -half, duration: 26, ease: 'none', repeat: -1,
      modifiers: { x: function (v) { return (parseFloat(v) % half) + 'px'; } }
    });

    // scrolling speeds the marquee up and flips it with direction
    ScrollTrigger.create({
      trigger: '.ticker', start: 'top bottom', end: 'bottom top',
      onUpdate: function (self) {
        var v = Math.min(Math.abs(self.getVelocity()) / 900, 4);
        tl.timeScale((self.direction === -1 ? -1 : 1) * (1 + v));
      }
    });
  }

  /* ----------------------------------------------------------------------
     Generic reveals
     ---------------------------------------------------------------------- */

  function initReveals() {
    // With reduced motion the content is simply present — no masked lines,
    // no fades. Split still runs so the art-directed line breaks survive.
    if (REDUCED) {
      $$('[data-split]').forEach(splitLines);
      gsap.set('.line-i', { yPercent: 0, opacity: 1 });
      $$('[data-stagger]').forEach(function (el) {
        gsap.set(el.children, { opacity: 1, y: 0 });
      });
      return;
    }

    $$('[data-split]').forEach(function (el) {
      if (el.closest('#hero')) return;           // hero is handled by the intro
      var lines = splitLines(el);
      gsap.fromTo(lines, { yPercent: 112 }, {
        yPercent: 0, duration: 1.15, ease: 'expo.out', stagger: 0.085,
        scrollTrigger: { trigger: el, start: 'top 82%' }
      });
    });

    $$('[data-stagger]').forEach(function (el) {
      gsap.fromTo(el.children, { opacity: 0, y: 30 }, {
        opacity: 1, y: 0, duration: 0.9, ease: 'power3.out', stagger: 0.1,
        scrollTrigger: { trigger: el, start: 'top 85%' }
      });
    });

    // hairline rules draw themselves in
    $$('.rail-head, .rows, #contact .grid div, footer.foot').forEach(function (el) {
      gsap.fromTo(el, { '--rule-scale': 0 }, {
        scrollTrigger: { trigger: el, start: 'top 90%' }
      });
    });
  }

  /* ----------------------------------------------------------------------
     Ritual — pinned three-beat sequence, cross-dissolved on scrub
     ---------------------------------------------------------------------- */

  function initRitual() {
    var section = $('#ritual');
    if (!section) return;

    var beats = $$('.beat', section);
    var vids = $$('[data-beat-video]', section);
    var rail = $('[data-ritual-rail]');

    // No pinning under reduced motion — let the three beats stack and scroll.
    if (REDUCED) {
      section.style.height = 'auto';
      $('.stage', section).style.position = 'static';
      beats.forEach(function (b) {
        b.style.position = 'relative';
        b.style.minHeight = '100svh';
      });
      vids.forEach(function (v) { v.preload = 'metadata'; });
      return;
    }

    // resting state: first beat up, rest below
    gsap.set(beats, { opacity: 0 });
    gsap.set(beats[0], { opacity: 1 });
    beats.forEach(function (b, i) {
      gsap.set($('.copy', b), { yPercent: i === 0 ? 0 : 18 });
      gsap.set($('.frame', b), { opacity: i === 0 ? 1 : 0, scale: i === 0 ? 1 : 1.08 });
    });

    var tl = gsap.timeline({
      scrollTrigger: {
        trigger: section,
        start: 'top top',
        // functional end so the pin distance is recomputed on every refresh
        // (resize, orientation change, late font/media layout shifts)
        end: function () { return '+=' + (vh() * 2.6); },
        pin: true,
        scrub: 1,
        anticipatePin: 1,
        invalidateOnRefresh: true,
        onUpdate: function (self) {
          if (rail) rail.style.width = (self.progress * 100).toFixed(2) + '%';
          // only the beat on screen plays
          var active = Math.min(beats.length - 1, Math.floor(self.progress * beats.length));
          vids.forEach(function (v, i) {
            if (i === active) { if (v.paused) { var p = v.play(); if (p && p.catch) p.catch(function () {}); } }
            else if (!v.paused) v.pause();
          });
        }
      }
    });

    for (var i = 1; i < beats.length; i++) {
      var prev = beats[i - 1], next = beats[i];
      tl.to($('.copy', prev), { yPercent: -18, opacity: 0, duration: 0.5, ease: 'power2.in' })
        .to($('.frame', prev), { opacity: 0, scale: 0.94, duration: 0.5, ease: 'power2.in' }, '<')
        .set(prev, { opacity: 0 })
        .set(next, { opacity: 1 })
        .fromTo($('.copy', next), { yPercent: 18, opacity: 0 },
          { yPercent: 0, opacity: 1, duration: 0.6, ease: 'power2.out' })
        .fromTo($('.frame', next), { opacity: 0, scale: 1.08 },
          { opacity: 1, scale: 1, duration: 0.6, ease: 'power2.out' }, '<')
        .to({}, { duration: 0.45 });   // hold so each beat can be read
    }

    // load the beat clips only once the section is near
    ScrollTrigger.create({
      trigger: section, start: 'top bottom+=50%', once: true,
      onEnter: function () { vids.forEach(function (v) { v.preload = 'auto'; v.load(); }); }
    });
  }

  /* ----------------------------------------------------------------------
     Dimension — scroll-scrubbed turntable on canvas
     ---------------------------------------------------------------------- */

  function initTurntable() {
    var canvas = $('#ttCanvas');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');
    var state = { frame: 0 };

    function draw() {
      var img = ttImages[Math.round(state.frame) % TT_FRAMES];
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      if (img && img.complete && img.naturalWidth) {
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      }
    }

    // size the backing store to the device pixel ratio so lines stay crisp
    function resize() {
      var dpr = Math.min(window.devicePixelRatio || 1, 2);
      var css = canvas.getBoundingClientRect();
      canvas.width = Math.round(css.width * dpr);
      canvas.height = Math.round(css.height * dpr);
      draw();
    }
    window.addEventListener('resize', resize);
    setTimeout(resize, 0);

    // Under reduced motion the preloader never runs, so nothing has fetched the
    // turntable frames. Pull the single resting frame we actually draw.
    if (REDUCED) {
      state.frame = 6;                 // a resting three-quarter view
      var only = new Image();
      only.onload = draw;
      only.src = '/media/tt/f06.webp';
      ttImages[6] = only;
      return;
    }

    gsap.to(state, {
      frame: TT_FRAMES - 1,
      ease: 'none',
      scrollTrigger: {
        trigger: '#dimension',
        start: 'top top',
        end: function () { return '+=' + (vh() * 2); },
        pin: true,
        scrub: 0.8,
        anticipatePin: 1,
        invalidateOnRefresh: true
      },
      onUpdate: draw
    });

    // a slow counter-rotation on the glow keeps the pinned frame alive
    if (!REDUCED) {
      gsap.to('#dimension .stage', {
        rotation: 4, duration: 12, yoyo: true, repeat: -1, ease: 'sine.inOut'
      });
    }

    draw();
  }

  /* ----------------------------------------------------------------------
     Catalogue rows — play the peek clip only while hovered
     ---------------------------------------------------------------------- */

  function initRows() {
    if (!FINE) return;
    $$('.row').forEach(function (row) {
      var v = $('[data-peek]', row);
      if (!v) return;
      row.addEventListener('pointerenter', function () {
        if (v.preload === 'none') { v.preload = 'auto'; v.load(); }
        var p = v.play(); if (p && p.catch) p.catch(function () {});
      });
      row.addEventListener('pointerleave', function () { v.pause(); });
    });
  }

  /* ----------------------------------------------------------------------
     Section tracker + in-page anchors
     ---------------------------------------------------------------------- */

  function initTracker() {
    var links = $$('#tracker a');

    links.forEach(function (a) {
      a.addEventListener('click', function (e) {
        e.preventDefault();
        scrollTo(a.getAttribute('href'));
      });
    });

    $$('[data-section]').forEach(function (sec, i) {
      ScrollTrigger.create({
        trigger: sec, start: 'top 55%', end: 'bottom 55%',
        onToggle: function (self) {
          if (!self.isActive) return;
          links.forEach(function (l) { l.classList.remove('on'); });
          if (links[i]) links[i].classList.add('on');
        }
      });
    });

    // any remaining in-page link routes through the smooth scroller
    $$('a[href^="#"]').forEach(function (a) {
      if (a.closest('#tracker') || a.hasAttribute('data-menu-link')) return;
      a.addEventListener('click', function (e) {
        var id = a.getAttribute('href');
        if (id.length < 2 || !$(id)) return;
        e.preventDefault();
        scrollTo(id);
      });
    });
  }

  /* ----------------------------------------------------------------------
     Small chrome details
     ---------------------------------------------------------------------- */

  function initChrome() {
    var yr = $('[data-year]');
    if (yr) yr.textContent = new Date().getFullYear();

    var clock = $('[data-clock]');
    if (clock) {
      var tickClock = function () {
        clock.textContent = new Date().toLocaleTimeString('en-GB', {
          hour: '2-digit', minute: '2-digit', second: '2-digit'
        });
      };
      tickClock();
      setInterval(tickClock, 1000);
    }
  }

  /* ----------------------------------------------------------------------
     Boot
     ---------------------------------------------------------------------- */

  function boot() {
    initSmooth();
    initCursor();
    initMenu();
    initChrome();
    initHero();
    initTicker();
    initReveals();
    initRitual();
    initTurntable();
    initRows();
    initTracker();
    ScrollTrigger.refresh();
  }

  window.addEventListener('DOMContentLoaded', function () {
    // everything is wired before the curtain lifts, so the first frame is correct
    boot();
    if (REDUCED) {
      var pre = $('#preloader');
      if (pre) pre.remove();
      splitLines($('#hero h1'));
      return;
    }
    preload(revealSite);
  });

})();
