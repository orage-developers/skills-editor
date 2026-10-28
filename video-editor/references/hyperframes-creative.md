# Hyperframes creative

Visual direction, typography, palettes, narration planning and scene pacing. Start from `brand/profile.md`; this file fills the gaps the profile doesn't cover.

## Visual direction

Before building, write a three-line direction and confirm it with the user on the first job for a brand:

1. **Mood:** e.g. "confident, clean, high contrast".
2. **Look:** background treatment, shapes, texture, photo vs. flat.
3. **Motion:** snappy / smooth / minimal (see `hyperframes-animation.md`).

## Typography

| Element | 9:16 (1080 wide) | 16:9 (1920 wide) |
| --- | --- | --- |
| Hook / title | 96–140 px, 1–5 words per line | 110–160 px |
| Supporting line | 54–72 px | 56–80 px |
| Captions | 64–84 px, max 2 lines, ≤ 28 chars per line | 48–60 px |
| Footnote / source | ≥ 30 px | ≥ 28 px |

- Two families at most: headline and body, from the brand profile.
- Line height 1.0–1.1 for titles, 1.2–1.3 for captions. Tighten title letter spacing slightly (−0.01 to −0.03 em).
- Emphasize with the accent color or weight, not with underline or italics.

## Color

- Build every scene from the brand tokens: background, text, accent. Use the accent on ≤ 15% of the frame.
- Text contrast at least 4.5:1 against what's behind it; over footage, use a plate, gradient or shadow.
- When the profile has no palette yet, propose one (background, text, accent, secondary) and ask before using it.

## Safe areas (9:16)

Platform UI covers parts of the frame. Keep text and faces out of:

- top 220 px (account name, progress bar);
- bottom 420 px (caption, buttons, audio label);
- right 140 px (like / comment / share column).

Captions sit above the bottom zone, roughly at y = 1180–1450.

## Pacing

| Format | Scene length | Notes |
| --- | --- | --- |
| Social 9:16, 15–45 s | 1.5–3 s per beat | A visual change every ≤ 3 s |
| Launch video 15–25 s | 2–4 s per beat | 5–8 beats total |
| 16:9 explainer | 4–8 s per beat | Slower, more text per frame allowed |

## Narration planning

- Script at ~2.5 words per second for energetic reads, ~2.2 for calm ones. A 20 s video ≈ 45–50 words.
- Write the script beat by beat; each beat's on-screen text is a shorter echo of the line, not a copy of it.
- Put the hook line first; no greetings or "in this video…".
- If narration audio exists, time beats to its word timestamps (`scripts/reel/transcribe.py`) instead of to estimates.
