# Brand onboarding

Learn the user's brand before the first edit, and keep `brand/profile.md` current afterwards. Every color, font, caption style and rule you use in a video comes from that file.

## When to run

- `brand/profile.md` is missing.
- It still contains `{{…}}` placeholders in a section the current task needs.
- The user corrects a brand detail ("our green is darker", "never use emoji") — update just that field.

## Interview

Ask in **rounds of 3–4 questions**. Accept "skip" or "don't know" and move on; mark skipped fields `TBD` instead of guessing. If the user shares a website, deck, brand guide or past videos, extract what you can from them first and ask only for what is still missing.

**Round 1 — identity**
1. What's the brand called, and what does it do in one sentence?
2. Who watches these videos?
3. Which languages do captions and on-screen text use?

**Round 2 — look**
4. Do you have a logo? Drop the files (SVG or transparent PNG; light and dark versions if you have them).
5. Brand colors as hex codes — primary, secondary, accent. (No codes? Share a site or image and I'll sample them for you to confirm.)
6. Fonts for headlines and captions. Are they on Google Fonts, or do you have the files?

**Round 3 — voice and video style**
7. Describe the tone in three words. Any words or phrases to always use or avoid?
8. Where will these videos run, and how long are they usually?
9. Caption style: word-by-word pop or two-line blocks? Emoji: yes, no or sparingly?
10. Music: genre and energy? Do you have licensed tracks?

**Round 4 — references and rules**
11. Share 1–3 videos you'd like to resemble and what you like about each.
12. Anything to never do (colors, claims, competitors, visual styles)?
13. Who approves drafts, and which Drive folder should finals go to?

## Saving

1. Copy `templates/brand-profile.md` to `brand/profile.md` and fill it in.
2. Save provided files under `brand/assets/logo/`, `brand/assets/fonts/` and `brand/assets/music/` (created by `workspace.py init`). Record license notes next to music. For any other asset type, `scripts/workspace.py folder brand/assets/<kind> "<description>"`.
3. If you sampled colors from an image or site, label them "sampled — confirm".
4. Read back a 5–8 line summary (name, audience, palette, fonts, caption style, platforms, never-do rules) and ask the user to confirm. Set `Confirmed by user: yes` only after they do.
5. Add a line to `memory/index.md` under setup status.

## Using the profile

- Load colors and fonts as CSS variables in every Hyperframes project:
  ```css
  :root { --brand-primary: #…; --brand-accent: #…; --font-head: "…"; --font-body: "…"; }
  ```
- Check caption contrast against the footage; if brand text colors fail, add a shadow or plate instead of changing the color.
- When a request conflicts with the profile ("make it neon pink"), follow the request for that job and ask whether to update the profile.
