# Brag slim

A lighter launch-video workflow using only local tools already installed. No voiceover. Use when Hyperframes isn't available, when the user wants something quick, or when narration isn't needed.

## Differences from `brag.md`

| | `brag` | `brag-slim` |
| --- | --- | --- |
| Engine | Hyperframes + GSAP | Single HTML page captured with Playwright, or FFmpeg alone |
| Voice | Optional Kokoro | None — music and on-screen text only |
| Length | 15–25 s | 10–20 s |
| Beats | Hook, reveal, 3 features, proof, CTA | Hook, 2–3 features, CTA |

## Path A — FFmpeg only (screenshots)

1. Prepare 3–5 screenshots at the target resolution (`scale` + `pad` in brand color).
2. Turn each into a 3 s clip with a slow zoom:
   ```bash
   ffmpeg -loop 1 -t 3 -i shot1.png -vf "zoompan=z='min(zoom+0.0015,1.12)':d=90:s=1080x1920:fps=30,format=yuv420p" -c:v libx264 s1.mp4
   ```
3. Add captions with `drawtext` using the brand font file:
   ```bash
   -vf "drawtext=fontfile=brand/assets/fonts/Head.ttf:text='Ship in minutes':fontsize=96:fontcolor=white:x=(w-tw)/2:y=260:enable='between(t,0.2,2.8)'"
   ```
4. Join with `xfade` (`transition=slideleft:duration=0.35`) or hard cuts, add music, normalize loudness, export with the social preset.

## Path B — HTML + Playwright frame capture

When animated type is needed but Hyperframes isn't installed: build one HTML page with a paused GSAP timeline (same determinism rules as `hyperframes-core.md`), capture frames by seeking the timeline with Playwright (`tl.seek(i / 30)` + `page.screenshot` per frame), then encode with `ffmpeg -framerate 30 -i frames/%05d.png …`.

## Delivery

Same as every job: draft → approval → `scripts/qa.sh` → `scripts/deliver.sh`.
