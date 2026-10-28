# Hyperframes CLI

Project initialization, linting, inspection, preview and rendering. `scripts/install.sh` installs the CLI globally; otherwise use `npx hyperframes`. Command names below are the documented workflow; confirm flags with `hyperframes --help` and `hyperframes <command> --help` before first use on a machine, and note differences in `memory/misc.md`.

## Commands

| Step | Command | Notes |
| --- | --- | --- |
| Scaffold | `hyperframes init <dir>` | Creates the project and a starter composition. Run inside `jobs/<job>/work/`. |
| Lint | `hyperframes lint` | Run after every structural change. Fix all errors before rendering. |
| Inspect | `hyperframes inspect` | Lists compositions, clips, tracks and durations — use it to check timing against the beat map. |
| Preview | `hyperframes preview` | Local browser preview with scrubbing. Share the URL with the user if they're on the same machine. |
| Render | `hyperframes render` | Local render through Chromium to MP4. Write to `renders/draft-vN.mp4` or `renders/final.mp4`. |
| Cloud render | `hyperframes cloud render` | Managed rendering on HeyGen. Paid; ask first. |

## Local render tips

- Render drafts at full resolution but consider a lower quality preset if the CLI offers one; render finals at the highest quality.
- If Chromium isn't found, run `npx playwright install chromium` or point the CLI at the system Chrome (see `--help` for the browser path option or environment variable).
- Long renders: run in the background and check progress rather than blocking the session.
- After rendering, always run `scripts/qa.sh`. If loudness is off, fix it with FFmpeg (`ffmpeg.md` → loudness) instead of re-rendering.

## Cloud rendering (optional)

Use only when the user chooses it (slow local machine, very long render, batch jobs). Credentials, any one of:

- `HEYGEN_API_KEY`
- `HYPERFRAMES_API_KEY`
- `HEYGEN_ACCESS_TOKEN`
- a saved HeyGen OAuth login through the CLI

Cloud credits are billed separately from AI model usage. Confirm the cost model with the user before the first cloud render.

## AWS Lambda / Google Cloud Run (optional)

The Hyperframes references describe self-hosted rendering on Lambda or Cloud Run. Adopt them only when the user deliberately asks; they need provider accounts, deployment and their own credentials. They are not required for the local pipeline.
