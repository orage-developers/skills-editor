# Video editing

General workflow for turning raw footage into an assembled edit. Commands live in `ffmpeg.md`; this file is the process.

## 1. Ingest

1. `scripts/workspace.py job <slug> --title "…"` creates `jobs/<YYYY-MM-DD>-<slug>/{src,work,out}` and indexes it. Fill in `brief.md`, then copy or download sources into `src/` (Drive: `rclone copy "gdrive:<path>" src/`).
2. `ffprobe` every file; log resolution, fps, duration and audio in `work/sources.md`.
3. Normalize to CFR 30 fps / 48 kHz in `work/norm/` if sources are mixed or VFR.
4. For long footage, make low-res proxies for review.

## 2. Log

- Transcribe speech with `scripts/reel/transcribe.py` (word timestamps, local Whisper).
- Sample frames (`ffmpeg … -vf fps=1/5 …`) and review them with vision to note shots, b-roll and problems (focus, exposure, background noise).
- Write `work/log.md`: per source, the usable moments with timecodes.

## 3. Paper edit

Write the edit as a cut list before touching the timeline, and confirm it with the user for anything longer than a minute:

```
# work/cutlist.md
1. A-roll 00:12.40–00:18.90  "Here's the problem…"   (hook)
2. B-roll screen.mp4 00:03.0–00:06.0 over A-roll audio
3. A-roll 01:02.10–01:09.75  "So we built…"
```

## 4. Assemble

- Cut each segment with frame-accurate re-encoding; join with the concat filter.
- Lay b-roll over A-roll audio with `overlay` and `enable='between(t,a,b)'`, or build the assembly as a Hyperframes composition when graphics are involved.
- Add captions, titles and graphics (Hyperframes) after the cut is approved — retiming graphics is expensive.

## 5. Finish

- Audio: clean dialogue (`highpass=f=80,afftdn`), music bed with ducking, loudness to −14 LUFS.
- Color: light correction only unless asked (`eq=contrast=1.05:saturation=1.08`), match shots side by side.
- Export with the preset for the target platform.

## 6. Review and deliver

- Draft → `work/draft-vN.mp4` + a preview-size copy for chat. List what changed since the last version.
- Mark progress: `scripts/workspace.py status <job> draft` when you send a draft, `approved` on sign-off.
- After approval: final export → `out/`, `scripts/qa.sh`, `scripts/deliver.sh`, then `scripts/workspace.py status <job> delivered --link <drive-link>`.

## Generated assets (optional)

Generated voiceover, music or footage are opt-in and may cost money:

- **Voiceover:** prefer narration the user supplies; edit it locally. Kokoro through Hyperframes is the free path (`brag.md`). ElevenLabs only when the user asks for it and `ELEVENLABS_API_KEY` is set — confirm cost first.
- **Images / footage:** only from sources the user provides or approves; record licenses in `work/sources.md`.
