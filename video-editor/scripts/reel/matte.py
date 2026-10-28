#!/usr/bin/env python3
"""Remove the background from talking-head footage with the local RVM ONNX model.

    "$REEL_PYTHON" matte.py INPUT.mp4 -o speaker.mov [--bg "#111827" --preview preview.mp4]

Outputs:
    -o *.mov    ProRes 4444 with alpha (default; best for compositing)
    -o *.webm   VP9 with alpha (smaller; loads in Hyperframes/Chrome)
    --preview   optional H.264 composite over --bg for quick review

Model: $MATTE_MODEL, default $VIDEO_EDITOR_DATA/models/rvm_mobilenetv3_fp32.onnx (installed by install.sh).
Needs numpy, opencv-python-headless, onnxruntime and ffmpeg on PATH.
"""
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


def default_model():
    if os.environ.get("MATTE_MODEL"):
        return os.environ["MATTE_MODEL"]
    data = os.environ.get("VIDEO_EDITOR_DATA") or os.path.join(
        os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share"), "video-editor")
    return os.path.join(data, "models", "rvm_mobilenetv3_fp32.onnx")


def hex_rgb(value):
    v = value.lstrip("#")
    return tuple(int(v[i:i + 2], 16) for i in (0, 2, 4))


def encoder_args(path):
    if path.suffix.lower() == ".webm":
        return ["-c:v", "libvpx-vp9", "-pix_fmt", "yuva420p", "-b:v", "0", "-crf", "30", "-row-mt", "1",
                "-c:a", "libopus"]
    return ["-c:v", "prores_ks", "-profile:v", "4444", "-pix_fmt", "yuva444p10le", "-c:a", "aac", "-b:a", "192k"]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("-o", "--output", required=True, help=".mov (ProRes 4444) or .webm (VP9 alpha)")
    ap.add_argument("--model", default=default_model())
    ap.add_argument("--downsample", type=float, help="RVM downsample ratio (default: auto, ~0.25 for 1080p)")
    ap.add_argument("--preview", help="also write an H.264 composite over --bg")
    ap.add_argument("--bg", default="#00b140", help="preview background color (default: green)")
    args = ap.parse_args()

    try:
        import cv2
        import numpy as np
        import onnxruntime as ort
    except ImportError as e:
        sys.exit(f"{e.name} is not installed in this interpreter. Run scripts/install.sh or use REEL_PYTHON.")
    if not Path(args.model).is_file():
        sys.exit(f"matting model not found: {args.model}. Run scripts/install.sh.")
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg not found on PATH")

    cap = cv2.VideoCapture(args.input)
    if not cap.isOpened():
        sys.exit(f"cannot open {args.input}")
    w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    ratio = args.downsample or min(1.0, 512 / max(w, h))

    preferred = [p for p in ("CUDAExecutionProvider", "CoreMLExecutionProvider") if p in ort.get_available_providers()]
    sess = ort.InferenceSession(args.model, providers=preferred + ["CPUExecutionProvider"])
    rec = [np.zeros([1, 1, 1, 1], dtype=np.float32)] * 4
    dsr = np.array([ratio], dtype=np.float32)

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    raw_in = ["-f", "rawvideo", "-pix_fmt", "rgba", "-s", f"{w}x{h}", "-r", f"{fps}", "-i", "-"]
    audio_in = ["-i", args.input, "-map", "0:v", "-map", "1:a?"]
    main_proc = subprocess.Popen(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *raw_in, *audio_in,
                                  *encoder_args(out), "-shortest", str(out)], stdin=subprocess.PIPE)
    prev_proc = None
    if args.preview:
        Path(args.preview).parent.mkdir(parents=True, exist_ok=True)
        prev_proc = subprocess.Popen(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                                      "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{w}x{h}", "-r", f"{fps}", "-i", "-",
                                      *audio_in, "-c:v", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
                                      "-c:a", "aac", "-shortest", "-movflags", "+faststart", args.preview],
                                     stdin=subprocess.PIPE)
        bg = np.array(hex_rgb(args.bg), dtype=np.float32).reshape(1, 1, 3) / 255.0

    n = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0
        src = rgb.transpose(2, 0, 1)[None]
        fgr, pha, *rec = sess.run(None, {"src": src, "r1i": rec[0], "r2i": rec[1], "r3i": rec[2], "r4i": rec[3],
                                         "downsample_ratio": dsr})
        fg = fgr[0].transpose(1, 2, 0)
        a = pha[0].transpose(1, 2, 0)
        rgba = np.concatenate([fg, a], axis=2)
        main_proc.stdin.write((np.clip(rgba, 0, 1) * 255).astype(np.uint8).tobytes())
        if prev_proc:
            comp = fg * a + bg * (1 - a)
            prev_proc.stdin.write((np.clip(comp, 0, 1) * 255).astype(np.uint8).tobytes())
        n += 1
        if n % 30 == 0:
            print(f"\r  matte {n}/{total or '?'} frames", end="", file=sys.stderr)

    cap.release()
    for p in (main_proc, prev_proc):
        if p:
            p.stdin.close()
            p.wait()
    print(f"\rmatte: {n} frames → {out}" + (f" (+ preview {args.preview})" if prev_proc else ""), file=sys.stderr)
    if main_proc.returncode or (prev_proc and prev_proc.returncode):
        sys.exit("ffmpeg failed while encoding")


if __name__ == "__main__":
    main()
