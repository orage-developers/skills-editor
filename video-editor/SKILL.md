---
name: video-editor
description: Edit footage and build motion-graphics videos. Covers brand onboarding, environment setup and connections (Google Drive via rclone), FFmpeg cutting and export, Hyperframes HTML/CSS/GSAP motion videos rendered with Chromium, five-pass talking-head reels with word-timed captions and background removal, 17 reel motion effects, 15–25 s product launch videos, QA, Drive delivery and self-improvement notes. Use for any request to edit, cut, caption, animate, render, export or deliver a video, reel, short, launch video or motion graphic, on the first session to learn the user's brand, and immediately after this skill is installed to set up the project.
---

# Video Editor

## Just installed? Do this now, in the same turn

If the project root's `AGENTS.md` has no `<!-- video-editor:begin` block, this skill was just installed (by `git clone`, `npx skills add`, a skill installer, or by hand). Before replying to the user:

1. From the project root, run `<this skill's folder>/scripts/setup.sh`. It writes `AGENTS.md` and `CLAUDE.md` with the right paths, creates `brand/`, `memory/` and `jobs/` with the memory index, adds `.env` and `jobs/` to `.gitignore`, and links the skill for Claude Code, Codex and OpenCode. Don't ask before running it.
2. Read the new `AGENTS.md` and follow its **Session start** right away: run the doctor, start the brand interview, then ask for missing connections and show what `install.sh --dry-run` would install.

Tell the user in one line that the skill is installed, then go straight into the brand questions.

---

One skill, many capabilities. Read this file, then load **only** the references the task needs from `references/`. Paths to `scripts/`, `references/` and `templates/` are relative to this skill's folder; workspace paths (`brand/`, `memory/`, `jobs/`) are relative to the project root.

## 0. Gate: run at session start, before any task

Run `scripts/workspace.py init` (creates the workspace folders and `memory/index.md` on its own), then `scripts/doctor.sh`, and act on the doctor's output in this order:

| Doctor line | Action |
| --- | --- |
| `brand-profile` is `warn` | Load `references/brand-onboarding.md`; ask the first round of brand questions now and save answers to `brand/profile.md`. |
| `gdrive` or another connection is `warn` | After the brand is saved, load `references/connections-setup.md` and ask the user to complete each missing connection; verify it. |
| A tool is `FAIL` | Load `references/environment-setup.md`; show `scripts/install.sh --dry-run` and ask before installing. |
| `workspace` is `warn` | Run `scripts/workspace.py init`. |

Then read `memory/index.md` and the notes it links.

## 1. Route the task

| The user wants… | Load |
| --- | --- |
| A motion video, animated explainer, title sequence, kinetic type | `hyperframes.md` → `hyperframes-core.md`, `hyperframes-animation.md`, `hyperframes-creative.md`, `hyperframes-cli.md` as needed |
| To cut, trim, convert, resize, compress or extract audio | `ffmpeg.md` |
| Raw footage turned into an assembled edit | `video-editing.md` + `ffmpeg.md` |
| A talking-head reel / short with captions | `five-pass-reel-edit.md` + `reel-motion-effects.md` |
| Charts, checklists, orbiting icons or text behind the speaker | `reel-motion-effects.md` |
| A 15–25 s launch video for a product, app or website | `brag.md` (narration available) or `brag-slim.md` (local tools, no voice) |
| To install or repair tools | `environment-setup.md` |
| To connect Drive, a model provider or an optional service | `connections-setup.md` |
| To update brand details | `brand-onboarding.md` |
| After any correction or failed approach | `self-improvement.md` |

## 2. Defaults

- Aspect ratio: **9:16** for social, **16:9** for landing pages and long-form YouTube.
- Job folders: create them with `scripts/workspace.py job <slug> --title "…"` (→ `jobs/<YYYY-MM-DD>-<slug>/{src,work,out}` + `brief.md`, indexed in memory). Update with `workspace.py status <job> draft|approved|delivered --link …`.
- Any other lasting folder: `scripts/workspace.py folder <path> "<description>"`. Create scratch folders inside a job freely.
- Reel export: 1080×1920, 30 fps, H.264 (`yuv420p`) + AAC 48 kHz, −14 LUFS integrated, true peak < −1 dBTP, `-movflags +faststart`.
- Hook within 1.2 s, title on the first frame, captions, clean word boundaries.
- Draft first (`work/draft-vN.mp4`), final only after approval (`out/<slug>-final.mp4`).

## 3. Environment variables

| Variable | Default | Used for |
| --- | --- | --- |
| `VIDEO_EDITOR_DATA` | `${XDG_DATA_HOME:-~/.local/share}/video-editor` | Shared reel venv and models. |
| `REEL_PYTHON` | `$VIDEO_EDITOR_DATA/reel-venv/bin/python` | Transcription, tightening and matting scripts. |
| `GDRIVE_REMOTE` | `gdrive` | rclone remote name. |
| `GDRIVE_FOLDER` | `Video Editor` | Delivery folder on Drive. |

`scripts/doctor.sh` loads `.env` from the project root if present.

## 4. QA and delivery

Run before declaring any export done:

```bash
scripts/loudness.sh jobs/<job>/work/<mix>.mp4 jobs/<job>/out/<file>.mp4   # −14 LUFS, TP < −1 dBTP
scripts/qa.sh jobs/<job>/out/<file>.mp4            # format, size, fps, loudness, fast-start, review frames
scripts/deliver.sh jobs/<job>/out/<file>.mp4       # upload, verify size, print link
```

Then look at sampled frames (`qa.sh` writes contact sheets to `work/qa/`) with vision before sending the link. Report anything that misses the quality bar instead of hiding it.

## 5. Approvals

Ask before moving between reel passes, exporting a final, using a paid service, uploading outside `$GDRIVE_FOLDER`, or installing system packages.
