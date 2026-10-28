# Hyperframes animation

Animation rules, scene blueprints, transitions and runtime adapters. GSAP is the default adapter; use another adapter (Lottie, CSS) only when the CLI supports it and the lint passes.

## Motion rules

- **Entrances** 0.35–0.6 s with `power3.out` or `expo.out`. **Exits** faster: 0.2–0.35 s with `power2.in`.
- **Stagger** text by word (0.04–0.08 s) or line (0.1–0.15 s), never by letter for body text.
- **Move less than you think:** 40–120 px offsets at 1080 wide. Scale from 0.9–0.96, not from 0.
- **One focal motion at a time.** Background elements move slower and smaller than the foreground.
- **Hold** important text for at least 0.25 s per word on screen before it exits; the closing line ≥ 2 s.
- **Frame 0 shows the title.** Don't start the hook with a `from(opacity: 0)` at t=0 — the first frame (the thumbnail on most platforms) comes out empty or half-drawn. Start the title fully visible and animate something secondary (scale 1.04 → 1, accent word, underline), or use `fromTo` with a start state that is already legible.
- **Ease out of everything that arrives, ease in to everything that leaves.** Avoid `linear` except for continuous drift and progress bars.
- Animate `transform` and `opacity`. Avoid animating `width`, `height`, `top`, `left` or filters on large elements — they slow rendering.
- Respect the brand profile's motion style: "snappy" → shorter durations and `back.out(1.4)` accents; "smooth" → longer durations and `sine`/`power2` eases; "minimal" → opacity and small translations only.

## Scene blueprints

| Blueprint | Beats |
| --- | --- |
| **Hook → value → CTA** (social, 15–30 s) | Hook statement (0–1.2 s) · 3 value beats (2–4 s each) · CTA + logo (≥ 2 s hold) |
| **Problem → solution** | Pain (big type) · twist · product reveal · 2–3 proof points · CTA |
| **List / countdown** | Title · N items, same layout per item · recap · CTA |
| **Stat reveal** | Context line · number counts up · comparison · source line |
| **Product tour** | Device frame · 3–5 screenshots with zoom-to-detail · feature captions · CTA |

## Transitions

| Transition | Use | Duration |
| --- | --- | --- |
| Hard cut | Default between beats; on the beat of the music | 0 |
| Crossfade | Mood change, slower brands | 0.3–0.5 s |
| Push / slide | Sequential items in a list | 0.35–0.5 s |
| Mask wipe | Reveal a new scene with a brand-color bar | 0.4–0.6 s |
| Zoom through | Moving from overview into detail | 0.4–0.6 s |
| Match cut | Same shape or position across scenes | 0 |

Pick one or two transition types per video and reuse them.

## Patterns

```js
// Hook title: legible on frame 0, settles in, then exits word by word
const words = gsap.utils.toArray("#title .w");
tl.fromTo("#title", { scale: 1.06 }, { scale: 1, duration: 0.6, ease: "power3.out" }, BEATS.hook)
  .from("#title .accent", { y: 24, duration: 0.4, ease: "back.out(1.6)" }, BEATS.hook)
  .to(words, { y: -40, opacity: 0, duration: 0.25, ease: "power2.in", stagger: 0.03 }, BEATS.problem - 0.3);

// Later titles can enter from nothing
tl.from("#scene2 .w", { y: 60, opacity: 0, duration: 0.45, ease: "power3.out", stagger: 0.06 }, BEATS.scene2);

// Number count-up with supported properties only: pre-render the steps as spans,
// then flip visibility with set() — deterministic at any seek position.
const steps = gsap.utils.toArray("#stat .step");          // <span class="step">0%</span> … <span class="step">87%</span>
steps.forEach((el, i) => {
  const t = BEATS.stat + 1.2 * (1 - Math.pow(1 - i / (steps.length - 1), 2)); // ease-out spacing
  tl.set(steps, { visibility: "hidden" }, t).set(el, { visibility: "visible" }, t);
});

// Bar grows from the baseline (transform-origin: bottom in CSS)
tl.from(".bar", { scaleY: 0, duration: 0.6, ease: "power3.out", stagger: 0.08 }, BEATS.chart);
```

Split text into `<span class="w">` elements in the HTML (or with a deterministic helper at load), not with a paid plugin that may not be installed.

Stick to the supported subset in `hyperframes-core.md`. Before using `onUpdate`, SVG stroke tweens or text tweens, prove them with `hyperframes check` and a `hyperframes snapshot` at several timestamps.
