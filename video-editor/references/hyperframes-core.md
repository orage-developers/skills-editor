# Hyperframes core

Composition structure, timing, clips, tracks and deterministic rendering. The CLI's `lint` command is the authority on the current schema; if anything below disagrees with it or with the scaffold that `init` generates, follow the CLI and note the difference in `memory/misc.md`.

## Composition

A composition is an HTML root element that declares its size and an id. Clips are child elements with timing attributes. Animation lives in one paused GSAP timeline registered under the composition id.

```html
<div id="stage" data-composition-id="main" data-start="0" data-width="1080" data-height="1920">

  <video id="aroll" data-start="0" data-duration="12" data-track-index="0"
         src="assets/aroll.mp4" muted playsinline></video>

  <div id="title" class="clip" data-start="0" data-duration="2.5" data-track-index="1">
    <h1>Ship faster</h1>
  </div>

  <audio id="music" data-start="0" data-duration="12" data-track-index="2"
         data-volume="0.25" src="assets/music.mp3"></audio>
</div>

<script>
  const tl = gsap.timeline({ paused: true });
  tl.from("#title h1", { y: 80, opacity: 0, duration: 0.5, ease: "power3.out" }, 0);
  window.__timelines = window.__timelines || {};
  window.__timelines["main"] = tl;
</script>
```

## Timing model

- `data-start` and `data-duration` are in seconds on the composition clock. A clip is visible only inside its window.
- `data-track-index` orders layers: higher tracks draw above lower ones. Keep footage on track 0, graphics above, audio on its own tracks.
- Timeline positions are absolute composition seconds. Place tweens with the position parameter (`tl.to(el, {...}, 3.2)`) rather than chaining long sequences, so retiming one beat doesn't shift everything after it.
- Keep a single beat map in a `const BEATS = { hook: 0, problem: 1.2, … }` object at the top of the script and reference it everywhere.

## Media

- `<video>` elements are `muted`; route sound through `<audio>` elements so the renderer can mix it.
- Trim source video with FFmpeg first rather than seeking deep into long files.
- Use constant-frame-rate sources (`ffmpeg -i in.mp4 -r 30 -vsync cfr …`) to avoid drift.

## Determinism rules

The renderer captures frames by seeking the timeline. Anything that depends on wall-clock time breaks the render.

- No `Date.now()`, `performance.now()`, `setTimeout`, `setInterval` or `requestAnimationFrame` loops for animation.
- No `Math.random()` without a fixed seed; precompute random values.
- No CSS `transition` or `@keyframes` unless the CLI documents an adapter for them — drive motion from the GSAP timeline.
- No network requests at render time: fonts, images, data and scripts are local files.
- Wait for fonts: load them with `@font-face` from `assets/fonts/` and avoid layout that depends on fallback metrics.
- Same input, same output: re-render a draft and compare a few frames if you suspect nondeterminism.

## Sizes

| Format | Width × height |
| --- | --- |
| 9:16 reel | 1080 × 1920 |
| 16:9 | 1920 × 1080 |
| 1:1 | 1080 × 1080 |
| 4:5 | 1080 × 1350 |
