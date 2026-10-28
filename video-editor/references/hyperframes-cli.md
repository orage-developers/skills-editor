# Hyperframes CLI

Project initialization, linting, inspection, preview and rendering. Checked against v0.8.x. `scripts/install.sh` installs the CLI globally (`npm install -g hyperframes`); otherwise prefix commands with `npx hyperframes`. Run `hyperframes <command> --help` when a flag below fails — the CLI changes quickly.

## Everyday commands

| Step | Command |
| --- | --- |
| Scaffold | `hyperframes init <name> --resolution portrait --non-interactive` (add `--video src.mp4 --language es` to import footage and transcribe it) |
| Docs | `hyperframes docs data-attributes` · `compositions` · `gsap` · `rendering` · `troubleshooting` |
| Lint | `hyperframes lint` |
| Full gate | `hyperframes check --at-transitions` — lint, runtime errors, layout overflow, motion and WCAG contrast in one pass. Add `--caption-zone "x0=0;y0=.62;x1=1;y1=.78"` for 9:16 captions. |
| Timing | `hyperframes timeline` · `hyperframes compositions` · `hyperframes info` |
| Frames | `hyperframes snapshot` (PNG key frames for visual review) · `hyperframes inspect` (layout across the timeline) |
| Preview | `hyperframes preview` (studio with scrubbing) |
| Render draft | `hyperframes render -q draft -o renders/draft-v1.mp4` |
| Render final | `hyperframes render -q delivery -f 30 -o renders/final.mp4` |
| Alpha overlay | `hyperframes render --format mov -o renders/overlay.mov` (ProRes 4444 with alpha) |
| Environment | `hyperframes doctor` · `hyperframes browser` (manage the render Chrome) |

## Media helpers (local, no API key)

| Need | Command |
| --- | --- |
| Word-level transcript | `hyperframes transcribe src.mp4 --language es --json` (whisper.cpp, or Parakeet if installed via `hyperframes models install parakeet`) |
| Caption sidecar | `hyperframes transcribe src.mp4 --to srt -o captions.srt` |
| Background removal | `hyperframes remove-background src.mp4 -o speaker.webm` (`.mov` for ProRes 4444, `-b bg.webm` for the background plate) |
| Narration (Kokoro) | `hyperframes tts script.txt -o voice.wav --voice af_heart --lang es` (`--list` for voices) |
| Beat detection | `hyperframes beats` (writes `beats/<audio>.json` for cutting on the music) |
| Audio analysis | `hyperframes audio` · `hyperframes normalize-audio` |
| Website capture | `hyperframes capture <url>` (for launch videos) |

These are the fallback when the reel venv (`scripts/reel/*.py`) is broken, and the default for `brag`.

## Render tips

- Local rendering uses bundled Chromium (Puppeteer) and the **system FFmpeg** — FFmpeg must be installed.
- `-q draft` for review, `-q delivery` for finals. `-w 4` workers is usually best.
- Use `--video-frame-format png` for screen recordings and saturated UI colors.
- Long renders: run in the background and check progress instead of blocking the session.
- After rendering, always run `scripts/qa.sh`. Fix loudness with FFmpeg (`ffmpeg.md`) rather than re-rendering.

## Official Hyperframes skills (optional)

`hyperframes skills` installs the upstream HyperFrames and GSAP skills into every supported AI tool; `hyperframes skills check` / `update` keep them current. They complement this skill with deeper authoring rules. `init` also installs missing core skills unless you pass `--skip-skills`.

## Cloud rendering (optional, paid)

`hyperframes cloud render` renders on HeyGen instead of locally. Ask first; credits are billed separately from AI model usage.

- Sign in: `hyperframes auth login` (OAuth) or `hyperframes auth login --api-key`; or set `HEYGEN_API_KEY`, `HYPERFRAMES_API_KEY` or `HEYGEN_ACCESS_TOKEN`.
- Check: `hyperframes auth status`.
- Manage renders: `hyperframes cloud list|get|delete`.

## AWS Lambda / Google Cloud Run (optional)

`hyperframes lambda` and `hyperframes cloudrun` deploy distributed rendering. Adopt only when the user deliberately asks; they need provider accounts and their own credentials, and are not required for the local pipeline.

## Telemetry

The CLI collects anonymous usage data. If the brand profile or user asks for no telemetry: `hyperframes telemetry disable`.
