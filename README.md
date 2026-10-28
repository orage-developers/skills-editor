# Scout Agents — Video Editor

A template for creating **video editing and motion graphics agents** that share the same knowledge and skills. Everything ships as a single skill, `video-editor/`, that works in any tool supporting `AGENTS.md` / `SKILL.md`: Claude Code, Codex, OpenCode and similar.

## Install

Pick one. All three end with the agent asking about your brand, saving it to `brand/profile.md`, and asking for any missing connections.

### A. Ask your agent (recommended)

Open Claude Code, Codex, OpenCode or any agent that can run shell commands, in the folder where the video agent should work, and say:

```text
Install this: https://github.com/orage-developers/skills-editor
```

The agent installs the skill, sets up the project (`AGENTS.md`, `brand/`, `memory/`, `jobs/`), interviews you about your brand, saves it and asks for any missing connection. Agents whose skill installer only copies the skill (Codex) finish the setup on your next message about video — e.g. *"I want to make a reel for my brand"*. For a step-by-step guided setup, paste [`video-editor/bootstrap-prompt.md`](video-editor/bootstrap-prompt.md) instead.

### B. Clone this repo and run the scripts

```bash
git clone https://github.com/orage-developers/skills-editor.git my-video-agent
cd my-video-agent
./video-editor/scripts/setup.sh           # AGENTS.md/CLAUDE.md, workspace folders, skill links
./video-editor/scripts/doctor.sh          # see what's missing
./video-editor/scripts/install.sh --dry-run && ./video-editor/scripts/install.sh
```

Then start your agent in that folder (`claude`, `codex` or `opencode`) and say hi. `AGENTS.md` (read by Codex and OpenCode, and by Claude Code through `CLAUDE.md`) makes it start with the brand interview and the connection checks.

### C. Install only the skill with a skills manager

```bash
npx skills add orage-developers/skills-editor --skill video-editor            # this project
npx skills add orage-developers/skills-editor --skill video-editor --global   # every project
```

This installs only the skill folder. Then run `<skill folder>/scripts/setup.sh` from your project root (or just tell your agent "set up the video editor") to add `AGENTS.md`, the workspace and the session-start brand interview.

### For AI agents installing this repo

If a user asked you to install this repository, do this without asking for confirmation:

1. **Get the skill.** Install the `video-editor/` folder with whatever installer you normally use (a skill installer, `npx skills add orage-developers/skills-editor --skill video-editor`, or `git clone --depth 1 https://github.com/orage-developers/skills-editor.git` and copy `video-editor/` into the project).
2. **Set up the project.** From the project root, run `<skill folder>/scripts/setup.sh`. It writes `AGENTS.md` (the Video Editor block, between markers, appended to an existing file) and `CLAUDE.md`, creates `brand/`, `memory/` and `jobs/` with the memory index, and links the skill for Claude Code, Codex and OpenCode.
3. **Take over as the Video Editor agent.** Read `AGENTS.md` and follow its *Session start* now: run the doctor, interview the user about their brand and save it, ask for every missing connection, and show `install.sh --dry-run` before installing requirements (ask first; if `sudo` needs a password, give the user the command to run).

The same steps are at the top of [`video-editor/SKILL.md`](video-editor/SKILL.md), so installers that copy only the skill folder still get them.

### Where each tool looks for the skill

`video-editor/scripts/link.sh` creates these links (`--global` for the user-level column, `--copy` to copy instead of symlink, `--unlink` to remove):

| Tool | Instructions file | Project skill folder | User skill folder |
| --- | --- | --- | --- |
| Claude Code | `CLAUDE.md` → `@AGENTS.md` | `.claude/skills/video-editor` | `~/.claude/skills/video-editor` |
| Codex | `AGENTS.md` | `.agents/skills/video-editor` | `~/.agents/skills/video-editor` |
| OpenCode | `AGENTS.md` | `.opencode/skills/video-editor` | `~/.config/opencode/skills/video-editor` |

Other agents: point them at `AGENTS.md` and `video-editor/SKILL.md`.

## What the agent does

1. **Learns the brand first.** On the first message of a session it runs `doctor.sh`; if there is no confirmed `brand/profile.md` it interviews you in short rounds (name, audience, tone, colors, fonts, logo, platforms, caption style, references, rules) and saves the answers.
2. **Asks for missing connections.** Google Drive through rclone (for delivery), the AI provider if your tool doesn't already supply one, and optional services (HeyGen cloud rendering, ElevenLabs) only if you want them. It never asks you to paste secrets into the chat.
3. **Prepares its environment.** It shows what `install.sh` will install and asks before installing FFmpeg, rclone, Python venv support, the Hyperframes CLI, the reel venv and the matting model.
4. **Edits with a proven pipeline.** FFmpeg for real footage, Hyperframes (HTML/CSS/JS + GSAP rendered through Chromium) for motion, a draft before every final, QA and Drive delivery.

Then ask for your first video: *"Make a 30 s 9:16 reel from this clip: …"*.

## Structure

```
.
├── README.md                    # This file
├── AGENTS.md                    # Agent instructions (generated by setup.sh from templates/AGENTS.md)
├── CLAUDE.md                    # Imports AGENTS.md for Claude Code
└── video-editor/                # The skill — single source of truth
    ├── SKILL.md                 # Entry point: session gate and routing to references
    ├── bootstrap-prompt.md      # Prompt to paste: installs requirements, asks for brand and connections
    ├── references/              # One file per capability (see below)
    ├── scripts/
    │   ├── setup.sh             # Post-install: writes AGENTS.md/CLAUDE.md, creates the workspace, links the skill
    │   ├── doctor.sh            # Checks brand profile, memory, tools, reel venv and connections
    │   ├── install.sh           # Installs system packages, Hyperframes, reel venv and matting model
    │   ├── link.sh              # Links the skill into .claude/, .agents/ and .opencode/
    │   ├── workspace.py         # Creates brand/, memory/, jobs/ and indexes jobs, folders and notes in memory
    │   ├── loudness.sh          # Normalizes audio to −14 LUFS with true peak below −1 dBTP
    │   ├── qa.sh                # Checks an export (codec, size, fps, loudness, fast-start) and writes review frames
    │   ├── deliver.sh           # Uploads to Drive, verifies the size, prints the link
    │   ├── lib.sh               # Shared helpers (.env loading, paths)
    │   └── reel/
    │       ├── transcribe.py    # Word timestamps with local faster-whisper
    │       ├── tighten.py       # Removes pauses and fillers via an editable EDL, renders the cut
    │       └── matte.py         # Background removal with the local RVM ONNX model
    └── templates/
        ├── AGENTS.md            # Source of the agent instructions ({{SKILL_DIR}} filled in by setup.sh)
        ├── brand-profile.md     # Brand profile template
        ├── memory-index.md      # Memory index template
        └── env.example          # Credential names (never values)
```

The tool-specific skill folders (`.claude/skills`, `.agents/skills`, `.opencode/skills`) are generated by `link.sh` and ignored by git.

### Created at runtime (ignored by git)

The agent creates these itself with `workspace.py` and keeps them listed in `memory/index.md`.

| Path | Contents |
| --- | --- |
| `brand/profile.md` | The user's brand profile, filled in during onboarding. |
| `brand/assets/` | `logo/`, `fonts/`, `music/` and any folder added with `workspace.py folder`. |
| `memory/` | `index.md` (setup status, workspace map, jobs, notes), `misc.md` and dated notes under `important/`. |
| `jobs/<date>-<slug>/` | `brief.md`, `src/`, `work/` and `out/` for each job, created with `workspace.py job`. |
| `.env` | Credential values. |

## Capabilities

Each former standalone skill is now a reference inside `video-editor/references/`. `SKILL.md` loads only the ones a task needs.

### Editing

| Reference | What it covers |
| --- | --- |
| `hyperframes` | Entry point for HTML/CSS/JS motion-video projects. |
| `hyperframes-core` | Composition structure, timing, clips, tracks and deterministic rendering. |
| `hyperframes-animation` | Animation rules, scene blueprints, transitions and runtime adapters such as GSAP. |
| `hyperframes-creative` | Visual direction, typography, palettes, narration planning and scene pacing. |
| `hyperframes-cli` | Init, check, snapshot, preview and render; local transcribe, background removal and Kokoro TTS; optional cloud rendering. |
| `ffmpeg` | Cutting, conversion, scaling, compression, audio extraction and export prep. |
| `video-editing` | General workflow from raw footage to an assembled edit. |
| `five-pass-reel-edit` | Talking-head reels in five passes with review between each. |
| `reel-motion-effects` | 17 word-timed effects: charts, checklists, orbiting elements, graphics behind the speaker. |
| `brag` | 15–25 s product/app/website launch videos with Hyperframes; optional Kokoro narration. |
| `brag-slim` | Lighter launch-video workflow with local tools only; no voiceover. |
| `self-improvement` | Records mistakes, corrections and better approaches for future jobs. |

### Bootstrap

| Reference | What it covers |
| --- | --- |
| `brand-onboarding` | Session-start brand interview; creates and updates `brand/profile.md`. |
| `environment-setup` | Detects the OS, installs requirements and repairs the reel Python environment. |
| `connections-setup` | Requests and verifies sessions: AI provider, Google Drive (rclone) and optional services. |

## Editing pipeline

1. Read `memory/index.md`, `brand/profile.md` and notes on proven pipelines.
2. Pick the aspect ratio: **9:16** for social, **16:9** for landing pages and long-form YouTube.
3. Real footage → FFmpeg. Motion → Hyperframes + GSAP → Chromium → MP4.
4. Talking-head reels → five passes: transcribe and tighten, remove the background, word-timed captions, motion graphics, sound mix. Preview and approval between passes.
5. Draft before final: hook within 1.2 s, title on the first frame, captions, clean word boundaries.
6. QA with FFprobe and visual review. Reel target: 1080×1920, 30 fps, H.264/AAC, −14 LUFS integrated, true peak below −1 dB, MP4 fast-start.
7. Save to `jobs/<job>/out/`, upload to `gdrive:<Folder>/<YYYY-MM-DD>/`, verify the uploaded size and return the link.

Out of scope: strategy, broader copywriting, scheduling and social publishing.

## Credentials

Values go in `.env` or the tool's credential store — **never** in prompts or git.

| Level | Credential | When |
| --- | --- | --- |
| Required | AI provider (`ANTHROPIC_API_KEY` or your tool's own session) | Planning, tool use and editing decisions. |
| Required | Google Drive OAuth via `rclone` (remote `gdrive:`) | Reading assets and delivering videos. |
| Alternative | `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, `GOOGLE_API_KEY`, Codex login | Only if you choose that provider. |
| Optional | `HEYGEN_API_KEY` / `HYPERFRAMES_API_KEY` / `HEYGEN_ACCESS_TOKEN` | Only for `hyperframes cloud render`. |
| Optional | `ELEVENLABS_API_KEY` | Only for an explicitly requested ElevenLabs voiceover. |
| Optional | AWS or Google Cloud accounts | Only for Lambda or Cloud Run rendering. |

FFmpeg, Chromium, GSAP, local Hyperframes, local Whisper transcription and ONNX matting need **no** API keys, though they need network access to download packages and models.

## System requirements

- FFmpeg and FFprobe (Hyperframes renders need the system FFmpeg too)
- Node.js ≥ 24 with npm/npx, and the Hyperframes CLI (`npm install -g hyperframes`)
- Chromium or Chrome (Hyperframes bundles one; `npx playwright install chromium` also works)
- Python ≥ 3.10 with venv support, and a dedicated reel venv at `~/.local/share/video-editor/reel-venv`: `faster-whisper`, `av<18`, `onnxruntime`, `numpy`, `opencv-python-headless`, `kokoro-onnx`, `soundfile`
- The RVM matting model `rvm_mobilenetv3_fp32.onnx` (downloaded by `install.sh`)
- `rclone`, Git and curl

`video-editor/scripts/doctor.sh` checks all of the above. An API key won't fix a broken venv: if the doctor reports transcription or matting failures, run `video-editor/scripts/install.sh`.

## Creating a new agent

Each agent is a copy of this repo with its own brand and memory:

```bash
git clone https://github.com/orage-developers/skills-editor.git my-agent && cd my-agent
./video-editor/scripts/setup.sh
```

Then paste the prompt from `video-editor/bootstrap-prompt.md`. Knowledge and skills are shared; `brand/`, `memory/` and `jobs/` belong to each instance.
