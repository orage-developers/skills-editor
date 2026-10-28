# Connections setup

Request only the sessions a task needs, verify each one, and never handle secret values in the chat.

## Rules for secrets

- Never ask the user to paste a key into the conversation. Tell them which variable to add to `.env` (template: `templates/env.example`) or which login command to run in their own terminal.
- Verify presence, not value: `[ -n "$VAR" ] && echo set || echo missing` after sourcing `.env`.
- Never print `.env`, `rclone.conf` or tokens, and never commit them.
- If a secret appears in the chat anyway, don't repeat it and suggest rotating it.

## 1. AI provider (required)

The agent's reasoning runs on whatever model the host tool uses. Usually nothing extra is needed.

| Host tool | Session | Check |
| --- | --- | --- |
| Claude Code | Claude login or `ANTHROPIC_API_KEY` | `claude` is already running — you are the session. |
| Codex | `codex login` (ChatGPT plan) or `OPENAI_API_KEY` | Codex is already running. |
| OpenCode | `opencode auth login` for the chosen provider | OpenCode is already running. |
| Headless / scripted runs | `ANTHROPIC_API_KEY` (default), or `OPENAI_API_KEY`, `OPENROUTER_API_KEY`, `GOOGLE_API_KEY` | Variable set in `.env`. |

Only one provider is needed. OpenRouter requires a funded account with access to the selected model. Record which provider is in use in `memory/index.md`.

## 2. Google Drive via rclone (required for delivery)

Drive access is an OAuth authorization, not an API key.

1. Check: `rclone listremotes | grep -qx "${GDRIVE_REMOTE:-gdrive}:"`.
2. If missing, give the user this command to run in their terminal (it opens a browser for the Google login):
   ```bash
   rclone config create gdrive drive scope=drive
   ```
   On a headless machine, they run `rclone authorize "drive"` on a computer with a browser and paste the resulting token into `rclone config` on the server.
3. Verify: `rclone lsd gdrive: --max-depth 1` lists folders without error.
4. Create the delivery folder: `rclone mkdir "gdrive:${GDRIVE_FOLDER:-Video Editor}"`.
5. Verify a link can be generated: `rclone link "gdrive:${GDRIVE_FOLDER:-Video Editor}"`. If link sharing is blocked by the workspace policy, deliver the Drive path instead and tell the user.

Use `scripts/deliver.sh` for uploads; it verifies the uploaded size and prints the link.

If the host tool also has a Google Drive connector (MCP), you may use it to search and read assets. Keep uploads on rclone so size verification works the same everywhere.

## 3. Optional services — ask, don't assume

Offer these once during bootstrap and again only when a task needs them. Each one costs money or credits separately from the AI model.

| Service | Credential | Needed only for | Verify |
| --- | --- | --- | --- |
| HeyGen / Hyperframes cloud render | `HEYGEN_API_KEY`, or `HYPERFRAMES_API_KEY`, or `HEYGEN_ACCESS_TOKEN`, or a saved HeyGen OAuth login | `hyperframes cloud render` instead of local rendering | Variable set; see `hyperframes-cli.md` for the CLI's auth check |
| ElevenLabs | `ELEVENLABS_API_KEY` | A voiceover the user explicitly asked to generate with ElevenLabs | Variable set |
| AWS Lambda / Google Cloud Run rendering | Provider account credentials | Deliberately adopting cloud rendering | Provider CLI login (`aws sts get-caller-identity`, `gcloud auth list`) |

Not needed: posting credentials for social platforms (publishing is out of scope), any key for FFmpeg, Chromium, GSAP, local Hyperframes, local Whisper or ONNX matting, or Kokoro narration through Hyperframes.

## Recording

Update the setup status table in `memory/index.md` with each connection's state (`verified`, `missing`, `skipped`) and the date.
