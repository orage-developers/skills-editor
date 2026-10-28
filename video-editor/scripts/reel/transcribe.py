#!/usr/bin/env python3
"""Transcribe speech to word-level timestamps with local faster-whisper.

    "$REEL_PYTHON" transcribe.py INPUT -o words.json [--srt captions.srt] [--model small] [--language es]

Output JSON:
    {"source", "language", "duration",
     "words":    [{"word", "start", "end", "prob"}, ...],
     "segments": [{"start", "end", "text"}, ...]}
"""
import argparse
import json
import sys
from pathlib import Path


def srt_time(t):
    ms = int(round(t * 1000))
    h, ms = divmod(ms, 3_600_000)
    m, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", help="audio or video file")
    ap.add_argument("-o", "--output", required=True, help="words JSON path")
    ap.add_argument("--srt", help="also write segment-level SRT here")
    ap.add_argument("--model", default="small", help="tiny, base, small, medium, large-v3 (default: small)")
    ap.add_argument("--language", help="language code, e.g. es or en (default: auto-detect)")
    ap.add_argument("--device", default="auto", help="auto, cpu or cuda")
    ap.add_argument("--compute-type", default="default", help="faster-whisper compute type (int8 on CPU is fastest)")
    args = ap.parse_args()

    try:
        from faster_whisper import WhisperModel
    except ImportError:
        sys.exit("faster-whisper is not installed in this interpreter. Run scripts/install.sh or use REEL_PYTHON.")

    model = WhisperModel(args.model, device=args.device, compute_type=args.compute_type)
    segments, info = model.transcribe(
        args.input,
        language=args.language,
        word_timestamps=True,
        vad_filter=False,  # keep pauses visible to tighten.py
        condition_on_previous_text=False,
    )

    words, segs = [], []
    for seg in segments:
        segs.append({"start": round(seg.start, 3), "end": round(seg.end, 3), "text": seg.text.strip()})
        for w in seg.words or []:
            words.append({
                "word": w.word.strip(),
                "start": round(w.start, 3),
                "end": round(w.end, 3),
                "prob": round(w.probability, 3),
            })
        print(f"  {seg.start:7.2f}–{seg.end:7.2f}  {seg.text.strip()}", file=sys.stderr)

    out = {
        "source": str(Path(args.input)),
        "language": info.language,
        "duration": round(info.duration, 3),
        "words": words,
        "segments": segs,
    }
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.output).write_text(json.dumps(out, ensure_ascii=False, indent=1))

    if args.srt:
        lines = []
        for i, s in enumerate(segs, 1):
            lines += [str(i), f"{srt_time(s['start'])} --> {srt_time(s['end'])}", s["text"], ""]
        Path(args.srt).parent.mkdir(parents=True, exist_ok=True)
        Path(args.srt).write_text("\n".join(lines), encoding="utf-8")

    print(f"transcribe: {len(words)} words, language {info.language}, {info.duration:.1f} s → {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
