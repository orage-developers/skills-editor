# Reel motion effects

17 word-timed effects for talking-head reels, built in Hyperframes over the speaker. Each effect starts on the timestamp of its trigger word (`work/p3/words.json`) and ends before the next effect.

## Catalog

| # | Effect | Trigger | Duration | Layer | Build notes |
| --- | --- | --- | --- | --- | --- |
| 1 | **Keyword pop** | A key term | 0.8–1.5 s | Front | Big word scales 0.92 → 1, accent color, exits up. |
| 2 | **Number counter** | A number or percentage | 1.2–2 s | Front | Pre-rendered step spans flipped with `set` (see `hyperframes-animation.md`); suffix static. |
| 3 | **Bar chart** | Comparison of 2–5 values | 2–3 s | Behind or front | Bars grow from baseline with stagger 0.08 s; label after bar lands. |
| 4 | **Line chart** | Growth / trend | 2–3 s | Behind | SVG line inside a mask `div` whose `width` tweens left → right; end dot scales in. |
| 5 | **Donut chart** | Share / portion | 1.5–2.5 s | Front | Static `conic-gradient` ring revealed by a rotating half-mask (`rotation`); number in the center. |
| 6 | **Checklist** | "First… second…", steps | 0.6 s per item | Front | Items slide in; check mark draws on each spoken item. |
| 7 | **Orbiting icons** | Tools, features, integrations | 2–4 s | Behind | 3–6 icons on an ellipse around the head; rotate slowly, scale in with stagger. |
| 8 | **Title behind speaker** | Topic statement | 1.5–3 s | Behind | Huge text between background and alpha speaker; needs pass 2 matte. |
| 9 | **Emoji / sticker burst** | Emotion words | 0.6–1 s | Front | 3–5 elements burst from a point, fall with gravity ease. Respect emoji rule in the profile. |
| 10 | **Punch-in zoom** | Emphasis, punchline | 0.3 s in, hold | Speaker | Scale speaker 1 → 1.12 on the word; ease out back on the next sentence. |
| 11 | **Lower third** | Speaker name, credential | 2.5–3.5 s | Front | Name + role, brand plate, enters from the left. Usually in the first 5 s. |
| 12 | **Split comparison** | "Before / after", "vs" | 2–3 s | Front | Two panels with labels; divider wipes across. |
| 13 | **Progress timeline** | Steps over time, roadmap | 2–4 s | Front | Horizontal line with nodes lighting up on each spoken step. |
| 14 | **Quote card** | Testimonial, citation | 2.5–4 s | Front | Card with quote marks; text reveals by line; source line last. |
| 15 | **Screenshot reveal** | "Look at this", product mention | 2–3 s | Front | Device or browser frame slides up; optional zoom to a detail. |
| 16 | **Highlight underline** | Contrast word in captions | With caption | Captions | Accent bar draws under the active word. |
| 17 | **CTA end card** | Final call to action | ≥ 2 s hold | Front | CTA text + logo + handle; music hits on entry. |

## Rules

- 3–6 effects per 30–45 s reel. Leave at least 1.5 s of plain speaker between effects.
- Never cover the speaker's eyes or mouth with front-layer effects; move them to the side or behind.
- Effects 3, 4, 7, 8 look best behind the speaker and need the pass-2 alpha.
- Data effects show real numbers the speaker says. Don't invent figures; ask if the script is vague.
- Use brand tokens for every color; charts use primary, secondary and accent in that order.
- Keep each effect's code in its own `<div class="clip fx-N">` with its own beat constant so it can be retimed or removed independently.
- Layer with CSS `z-index`: background 0, behind-speaker effects 10, speaker alpha 20, front effects 30, captions 40.
- Validate with `hyperframes check --at-transitions` and snapshot each effect's start, middle and end.

## Picking effects

Read the tightened transcript and mark candidate trigger words:

- numbers → 2, 3, 4 or 5;
- enumerations → 6 or 13;
- named tools or features → 7 or 15;
- the main topic line → 8;
- strong claim or punchline → 1 or 10;
- testimonial → 14;
- ending → 17.

Propose the list (word, time, effect) to the user before building pass 4.
