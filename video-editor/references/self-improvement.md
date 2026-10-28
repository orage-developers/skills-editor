# Self-improvement

Record mistakes, corrections and better approaches so the next job starts smarter. Run this after every user correction, every failed approach and every approved delivery that used a new technique.

## What to record

| Event | Where | Example |
| --- | --- | --- |
| Brand correction | `brand/profile.md` (update the field) + a line in `memory/misc.md` | "Accent is #00C389, not #00B37A." |
| Taste feedback | `memory/important/YYYY-MM-DD-<slug>.md` | "User prefers captions lower and smaller; 68 px at y=1400." |
| Failed approach | `memory/important/…` | "RVM matte flickers on green screens; key with chromakey instead." |
| Proven pipeline | `memory/important/…` + "Proven pipelines" in `memory/index.md` | "Brag 20 s, 16:9, Kokoro voice — shipped and approved." |
| Environment fix | `memory/misc.md` | "Hyperframes render needs `--browser` pointing at Chrome on this machine." |
| Small finding | `memory/misc.md` | "Client's phone footage is 29.97 VFR; normalize first." |

## Note format

```markdown
# <Short title>

- **Date:** YYYY-MM-DD
- **Job:** jobs/<job-name>
- **What happened:** <one or two lines>
- **Correction / better approach:** <what to do instead, concretely>
- **Applies to:** <reels / brag / all 9:16 / this brand only>
```

Create notes with `scripts/workspace.py note <slug> "<one-line summary>" --applies-to "<scope>" --job <job>` — it writes this skeleton to `memory/important/<date>-<slug>.md` and links it from `memory/index.md`; then fill in the TBD fields.

## Rules

- Write the note right after the correction, not at the end of the session.
- Record the fix, not just the problem. "Captions too big" is weak; "captions 68 px, max 2 lines, y=1400" is useful.
- Update or delete notes that turn out to be wrong instead of adding contradicting ones.
- Before each job, read `memory/index.md` and apply notes whose "Applies to" matches.
- Never store secrets, tokens or private client data in memory.
