# Brag — launch videos

Short product, app or website launch videos, 15–25 s, built with Hyperframes. Optional narration uses Kokoro through Hyperframes (`--voice`).

## Inputs

Ask for whatever is missing:

- product name, one-line value proposition and 3 key features;
- URL or screenshots / screen recordings (if only a URL: `hyperframes capture <url>`, or Playwright screenshots at 1440×900 and mobile 390×844);
- CTA (URL, "Try it free", launch date) and logo;
- format: 16:9 (landing page, X, LinkedIn) or 9:16 (Reels, TikTok, Shorts);
- voice: none, Kokoro narration (`--voice`), or a supplied recording.

## Structure (20 s example)

| Time | Beat | Content |
| --- | --- | --- |
| 0–2 s | Hook | Bold claim or the pain in ≤ 6 words. Title on frame 0. |
| 2–5 s | Reveal | Logo + product name, hero screenshot slides in. |
| 5–14 s | Features | 3 beats × 3 s: screenshot zoomed to the relevant UI + 3–5-word caption. |
| 14–17 s | Proof | Metric, testimonial or "Used by…" logos (only real ones). |
| 17–20 s | CTA | CTA text, URL, logo; hold ≥ 1.5 s. |

Scale proportionally for 15 s (2 features) or 25 s (4 features or longer proof).

## Build

1. Plan beats and copy with `hyperframes-creative.md`; confirm copy with the user.
2. Prepare screenshots: crop, add device or browser frame, export at 2× for zooms.
3. Compose in Hyperframes (`hyperframes-core.md`); use the "product tour" blueprint and one transition type (`hyperframes-animation.md`).
4. Music: energetic bed from `brand/assets/music/`; hit points on the reveal and CTA.

## Narration with `--voice`

- Write the script to the beat timing (~2.5 words/s, ≈ 45–50 words for 20 s).
- Generate it locally with Kokoro: `HYPERFRAMES_PYTHON="$REEL_PYTHON" hyperframes tts work/script.txt -o work/voice.wav --voice <id> --lang <es|en-us|…>` (`hyperframes tts --list` shows voices; Spanish: `ef_dora`). Kokoro needs `kokoro-onnx` and `soundfile`, which `install.sh` puts in the reel venv; the first run downloads the voice model.
- Transcribe the result (`hyperframes transcribe work/voice.wav --json` or `scripts/reel/transcribe.py`) and retime beats to the actual word timestamps.
- If Kokoro isn't available, ask the user for a recording or offer `brag-slim.md`. Use ElevenLabs only if the user explicitly asks for it and the key is set.

## Delivery

Draft → approval → final render → `scripts/loudness.sh` → `scripts/qa.sh` → `scripts/deliver.sh`. For landing pages, also offer a muted, looping WebM/MP4 version without the CTA card.
