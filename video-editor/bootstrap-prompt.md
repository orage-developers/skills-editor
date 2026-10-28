# Bootstrap prompt

Paste everything inside the block below into Claude Code, Codex, OpenCode or any agent that can run shell commands. Run it from the folder where the agent should work (an empty folder or a clone of this repo).

```text
You are setting up a Video Editor agent in this folder. Follow these steps in order, and stop to ask me whenever a step needs my input or approval.

1. GET THE SKILL
   - If ./video-editor/SKILL.md exists, use it.
   - Otherwise run: git clone https://github.com/orage-developers/skills-editor.git .video-editor-src
     then copy .video-editor-src/AGENTS.md, .video-editor-src/CLAUDE.md and the .video-editor-src/video-editor/ folder into this folder (don't overwrite an existing AGENTS.md or CLAUDE.md without asking me) and delete .video-editor-src.
   - Run ./video-editor/scripts/link.sh so this tool can discover the skill.
   - Read AGENTS.md and video-editor/SKILL.md, and follow them from now on.

2. CHECK THE ENVIRONMENT
   - Run ./video-editor/scripts/doctor.sh and show me a short summary of what is missing.
   - If something required is missing, tell me what ./video-editor/scripts/install.sh will install (run it with --dry-run first), ask for my approval, then run it. If it needs sudo and you can't provide a password, give me the exact command to run myself.
   - Run the doctor again until required checks pass.

3. LEARN MY BRAND
   - Follow video-editor/references/brand-onboarding.md. Ask me the questions in small rounds, not all at once.
   - Save the result to brand/profile.md using video-editor/templates/brand-profile.md, read it back to me as a short summary and ask me to confirm.

4. CONNECT SESSIONS AND SERVICES
   - Follow video-editor/references/connections-setup.md.
   - Confirm which AI provider this tool is using. Only ask for an API key if the workflow needs one that isn't already available.
   - Set up Google Drive with rclone (remote "gdrive"). Give me the exact command for the OAuth login and wait for me to finish it, then verify with rclone.
   - Ask me whether I want any optional service (HeyGen cloud rendering, ElevenLabs voice). Skip the ones I don't need.
   - Never ask me to paste secrets into this chat. Tell me which variable to add to .env and verify only that it is set.

5. SAVE STATE
   - Create memory/index.md from video-editor/templates/memory-index.md with today's date, the doctor result, the verified connections and a link to brand/profile.md.

6. REPORT
   - Give me a checklist: environment, brand, AI provider, Google Drive, optional services, each marked ready / missing / skipped.
   - Then ask me for my first video.
```
