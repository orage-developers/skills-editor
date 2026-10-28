# Hyperframes core

Composition structure, timing, clips, tracks and deterministic rendering. Checked against Hyperframes CLI v0.8.x. The CLI is the authority: `hyperframes docs <topic>` (topics: `data-attributes`, `compositions`, `gsap`, `rendering`, `examples`, `troubleshooting`) and `hyperframes check` win over this file. Note any difference in `memory/misc.md`.

## Composition

A composition is an HTML document with a root element carrying `data-composition-id`, `data-width` and `data-height`. Timed elements carry `data-start` / `data-duration` and `class="clip"`. Animation lives in one paused GSAP timeline registered under the composition id.

```html
<div id="root" data-composition-id="root" data-width="1080" data-height="1920">

  <video id="aroll" class="clip" data-start="0" data-duration="12" data-media-start="3.5"
         data-has-audio="true" src="assets/aroll.mp4" playsinline></video>

  <div id="title" class="clip" data-start="0" data-duration="2.5" style="z-index: 10">
    <h1>Ship faster</h1>
  </div>

  <audio id="music" class="clip" data-start="0" data-duration="12"
         data-volume="0.25" data-fade-out="1" src="assets/music.mp3"></audio>
</div>

<script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/gsap.min.js"></script>
<script>
  const tl = gsap.timeline({ paused: true });
  tl.from("#title h1", { y: 80, opacity: 0, duration: 0.5, ease: "power3.out" }, 0);
  window.__timelines = window.__timelines || {};
  window.__timelines["root"] = tl;
</script>
```

Scaffold with `hyperframes init <name> --resolution portrait --non-interactive` rather than writing this by hand; the scaffold has the current boilerplate.

## Attributes

| Attribute | Meaning |
| --- | --- |
| `data-composition-id` | Required on the root; key for `window.__timelines`. |
| `data-width`, `data-height` | Canvas size in pixels. |
| `data-start`, `data-duration` | Clip window in seconds on the composition clock. |
| `data-media-start` | Trim point inside the media file (seconds). |
| `data-volume` | Gain: 1 = 0 dB, 0 = silent, up to 3.98 (+12 dB). |
| `data-fade-in`, `data-fade-out` | Linear audio fades at the clip edges (seconds). |
| `data-has-audio="true"` | Keep a video's sound. Use `muted` on silent footage. |
| `data-composition-src` | Embed a nested composition (`compositions/intro.html`). |
| `data-track-index` | Studio timeline lane, **display only**. |

**Layer order is CSS `z-index`**, not `data-track-index`. Footage low, graphics above, captions on top.

## Timing model

- Place tweens with absolute positions (`tl.to(el, vars, 3.2)`), not long chains, so retiming one beat doesn't shift everything after it.
- Keep one beat map at the top of the script — `const BEATS = { hook: 0, problem: 1.2, … }` — and reference it everywhere.
- Split long videos into nested compositions (one per scene) with `data-composition-src`; per-instance values go in `data-variable-values` (see `hyperframes docs compositions`).

## GSAP subset

Hyperframes drives a paused timeline. Use `set`, `to`, `from`, `fromTo` on `opacity`, `x`, `y`, `scale`, `scaleX`, `scaleY`, `rotation`, `width`, `height`, `visibility`. For anything else (SVG stroke drawing, `onUpdate` counters, text changes) run `hyperframes check` and look at `hyperframes snapshot` frames before relying on it.

## Determinism rules

The renderer captures frames by seeking the timeline. Anything that depends on wall-clock time breaks the render.

- No `Date.now()`, `setTimeout`, `setInterval` or `requestAnimationFrame` animation loops.
- No `Math.random()` without a fixed seed; precompute random values.
- No CSS `transition` / `@keyframes` for motion — drive it from the timeline.
- Keep assets in the project. GSAP from the CDN is the documented default; vendor it to `assets/` if renders must work offline.
- Load brand fonts with `@font-face` from `assets/fonts/` (`hyperframes-localize-fonts` can pull web fonts local).
- For production finals where exact reproducibility matters, `hyperframes render --docker`.

## Sizes

| Format | Width × height | `init --resolution` |
| --- | --- | --- |
| 9:16 reel | 1080 × 1920 | `portrait` |
| 16:9 | 1920 × 1080 | `landscape` |
| 1:1 | 1080 × 1080 | `square` |
| 4:5 | 1080 × 1350 | set `data-width` / `data-height` by hand |
