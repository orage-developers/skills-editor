# Hyperframes

Entry point for motion videos built as HTML/CSS/JavaScript and rendered to MP4 through headless Chromium. Use it for explainers, kinetic typography, title cards, product launches, animated captions and overlays on footage.

## When to use something else

- Pure cutting, trimming or format conversion → `ffmpeg.md`.
- Talking-head reel → `five-pass-reel-edit.md` (it uses Hyperframes for pass 4 only).

## Project layout

```
jobs/<job>/work/hf/
├── index.html          # The root composition
├── compositions/       # Optional nested scenes
├── assets/             # Footage, images, fonts, audio copied into the project
└── renders/            # Draft and final renders
```

Keep footage, images, fonts and audio inside the project. GSAP loads from the CDN by default; copy it into `assets/` when renders must work offline.

## Workflow

1. **Brief.** Confirm aspect ratio, duration, message, CTA and assets. Pull colors and fonts from `brand/profile.md`.
2. **Plan scenes** with `hyperframes-creative.md`: a beat list with timestamps, on-screen text and the motion for each beat.
3. **Scaffold** with `hyperframes init hf --resolution portrait|landscape --non-interactive` inside `jobs/<job>/work/` (`hyperframes-cli.md`), then write the composition following `hyperframes-core.md`.
4. **Animate** following `hyperframes-animation.md`. One paused GSAP timeline per composition.
5. **Check and preview.** Run `hyperframes check --at-transitions` and fix every error. Look at `hyperframes snapshot` frames for the hook (0–1.2 s), each scene change and the last frame.
6. **Draft render** with `hyperframes render -q draft -o renders/draft-vN.mp4`, run `scripts/qa.sh`, show the user.
7. **Final render** after approval, normalize audio with FFmpeg if the composition has sound, copy to `jobs/<job>/out/`, deliver.

## Checklist before showing a draft

- Title visible on frame 0; hook lands by 1.2 s.
- Text inside safe areas (see `hyperframes-creative.md`).
- Brand fonts actually loaded (not a fallback) — check a frame.
- No element pops in or out without an animation unless it's a deliberate hard cut.
- Last frame holds long enough to read the CTA (≥ 1.5 s).
