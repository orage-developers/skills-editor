# Environment setup

Install and verify the local toolchain. The standard pipeline renders locally and needs no paid API for FFmpeg, Chromium, GSAP, Hyperframes, Whisper transcription or ONNX matting — but it needs network access to download packages and models the first time.

## Requirements

| Tool | Why | Minimum |
| --- | --- | --- |
| FFmpeg + FFprobe | Cutting, encoding, loudness, QA | 5.x with `libx264`, `aac`, `loudnorm` |
| Node.js + npm/npx | Hyperframes CLI, Playwright | 24 |
| Chromium / Chrome | Rendering HTML scenes to frames | Playwright-managed or system |
| Hyperframes CLI | Motion-video projects | latest (`npx hyperframes`) |
| Python | Reel scripts | 3.10 |
| Reel venv | `faster-whisper`, `onnxruntime`, `numpy`, `opencv-python-headless` | at `$VIDEO_EDITOR_DATA/reel-venv` |
| Matting model | Background removal | `rvm_mobilenetv3_fp32.onnx` in `$VIDEO_EDITOR_DATA/models/` |
| rclone | Google Drive delivery | 1.60 |
| Git | Fetching this skill and updates | any |

## Procedure

1. Run `scripts/doctor.sh`. It prints one line per check (`ok`, `warn`, `FAIL`) and exits non-zero if a required check fails.
2. Run `scripts/install.sh --dry-run` and show the user what it will do.
3. With approval, run `scripts/install.sh`. It:
   - uses the system package manager (apt, dnf, pacman, zypper or Homebrew) for FFmpeg, Python, rclone and Git;
   - installs Chromium through Playwright (`npx playwright install chromium`);
   - installs the Hyperframes CLI globally with npm;
   - (re)creates the reel venv, replacing it if its interpreter symlink is broken;
   - downloads the matting model.
   Flags: `--skip-system` (no package manager, no sudo), `--skip-reel`, `--dry-run`.
4. If `sudo` needs a password you can't enter, give the user the exact command and ask them to run it (in Claude Code they can type `! <command>`).
5. Node is not installed by the script when missing. Recommend nvm (`nvm install 24`) or the system package, then rerun.
6. Run `scripts/doctor.sh` again. Record the result and date in `memory/index.md`.

## Known failure: broken reel venv

The reel interpreter can be a symlink whose target Python was removed or upgraded. Symptoms: `reel-venv/bin/python: No such file or directory`, or the scripts fall back to a system Python without `faster-whisper`, `onnxruntime`, `numpy` or OpenCV. A setup check that marks those packages optional can still say "ready" — it doesn't mean transcription or matting work.

Fix: `scripts/install.sh --skip-system` recreates the venv. Then verify:

```bash
"$REEL_PYTHON" -c "import faster_whisper, onnxruntime, numpy, cv2; print('reel ok')"
```

Adding an API key does not fix this.

## Platform notes

- **macOS:** Homebrew installs `ffmpeg`, `python@3.12`, `rclone`. Chrome is fine as the renderer.
- **Windows:** use WSL2 (Ubuntu) and run everything inside it.
- **Containers / CI:** use `--skip-system` and install system packages in the image instead.
- **Apple Silicon / no GPU:** faster-whisper runs on CPU with `int8`; use the `small` or `base` model for speed.
