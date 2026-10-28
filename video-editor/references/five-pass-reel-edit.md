# Five-pass reel edit

Talking-head footage → finished 9:16 reel in five passes. **Show a preview and get the user's approval after every pass** before starting the next. Each pass writes to `jobs/<job>/work/pN-*/` so any pass can be redone without repeating earlier ones.

Target: 1080×1920, 30 fps, H.264/AAC, −14 LUFS integrated, true peak < −1 dBTP, `+faststart`.

## Before pass 1

```bash
scripts/doctor.sh --reel      # fails if faster-whisper, onnxruntime, numpy, OpenCV or the model are missing
```

If it fails, follow `environment-setup.md` → broken reel venv. Don't start a reel with a broken environment.

## Pass 1 — Transcribe and tighten

```bash
"$REEL_PYTHON" scripts/reel/transcribe.py src/aroll.mp4 -o work/p1/words.json --srt work/p1/raw.srt
"$REEL_PYTHON" scripts/reel/tighten.py work/p1/words.json -o work/p1/edl.json \
    --max-gap 0.35 --pad 0.06 --fillers "um,uh,erm,like,you know,este,eh,o sea"
"$REEL_PYTHON" scripts/reel/tighten.py work/p1/words.json --render src/aroll.mp4 work/p1/tight.mp4 --edl work/p1/edl.json
```

- Removes silences longer than `--max-gap`, filler words, and any ranges listed under `"cut"` in the EDL (retakes, false starts — edit the JSON by hand after reading the transcript).
- Hook check: the first spoken words must state the point. If not, move the strongest line to the start (edit `edl.json` order) and confirm with the user.
- Preview: `tight.mp4` + the tightened transcript. **Approve.**

## Pass 2 — Cut out (background removal)

```bash
"$REEL_PYTHON" scripts/reel/matte.py work/p1/tight.mp4 -o work/p2/alpha.mov
```

- Produces the speaker with an alpha channel (ProRes 4444) using the local ONNX matting model.
- Composite on a brand background or keep the original background for later "behind the speaker" effects — keep both the alpha file and `tight.mp4`.
- Preview: a composite over a solid brand color; check hair edges, hands and fast motion. **Approve.**
- Skip this pass when no effect needs it and the user agrees.

## Pass 3 — Word-timed captions

- Re-transcribe `tight.mp4` (timestamps changed in pass 1) → `work/p3/words.json`.
- Fix spelling of names and brand terms from `brand/profile.md`.
- Group words into caption chunks: 1–3 words for "pop" style, ≤ 2 lines of ≤ 28 chars for block style. Break on punctuation and natural pauses.
- Build captions in Hyperframes: each chunk is a clip from first word start to last word end; highlight the active word in the brand accent color.
- Position inside the safe area (y ≈ 1180–1450).
- Preview render. **Approve.**

## Pass 4 — Motion graphics

- Pick effects from `reel-motion-effects.md` triggered by specific words (numbers, lists, comparisons, key claims). 3–6 effects for a 30–45 s reel; never two at once.
- Title on frame 0, hook landing by 1.2 s.
- Layers bottom → top: background, behind-speaker graphics, speaker (alpha), front graphics, captions.
- Preview render. **Approve.**

## Pass 5 — Sound

- Dialogue: `highpass=f=80`, light de-noise (`afftdn=nf=-25`), gentle compression.
- Music bed from `brand/assets/music/` under the voice with sidechain ducking (`ffmpeg.md`), music ending on the CTA.
- Optional whooshes / pops on major motion beats, quiet (−20 dB under voice).
- Loudness two-pass to −14 LUFS, TP −1.5.
- Final export with the reel preset → `scripts/qa.sh` → user approval → `out/` → `scripts/deliver.sh`.

## Notes

- If the user wants it faster, offer to batch passes 3–5 into one review, but keep pass 1 approval separate: it decides the content.
- Record any pass that needed fixes in memory via `self-improvement.md`.
