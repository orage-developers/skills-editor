#!/usr/bin/env python3
"""Tighten a talking-head take: drop long pauses and filler words, then render the cut.

Plan (writes an editable EDL):
    tighten.py words.json -o edl.json [--max-gap 0.35] [--pad 0.06] [--fillers "um,uh,o sea"]

Render (applies the EDL to the source):
    tighten.py --render SOURCE.mp4 OUT.mp4 --edl edl.json

EDL format — edit it by hand between the two steps:
    {"source": "...",
     "keep": [[start, end], ...],   # ranges played in this order; delete or reorder entries freely
     "cut":  [[start, end], ...],   # extra ranges to remove (retakes, false starts)
     "removed": [{"word", "start", "end", "reason"}, ...]}   # for review only

Uses only the standard library; rendering needs ffmpeg on PATH.
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

DEFAULT_FILLERS = "um,uh,erm,ehm,eh,mm,mmm,hmm"


def norm(token):
    return re.sub(r"[^\w']+", "", token.lower())


def find_fillers(words, fillers):
    """Return indexes of words that are part of a filler phrase."""
    phrases = sorted((f.split() for f in fillers), key=len, reverse=True)
    tokens = [norm(w["word"]) for w in words]
    drop = set()
    i = 0
    while i < len(tokens):
        for phrase in phrases:
            n = len(phrase)
            if tokens[i:i + n] == phrase:
                drop.update(range(i, i + n))
                i += n - 1
                break
        i += 1
    return drop


def plan(args):
    data = json.loads(Path(args.words).read_text())
    words = data["words"]
    fillers = [norm_phrase for f in args.fillers.split(",") if (norm_phrase := " ".join(norm(t) for t in f.split()))]
    drop = find_fillers(words, fillers)

    # Group kept words into runs of word indexes; a dropped word or a long pause ends a run.
    removed, runs = [], []
    cur = []
    for i, w in enumerate(words):
        if i in drop:
            removed.append({**{k: w[k] for k in ("word", "start", "end")}, "reason": "filler"})
            if cur:
                runs.append(cur)
                cur = []
            continue
        if cur and w["start"] - words[cur[-1]]["end"] > args.max_gap:
            runs.append(cur)
            cur = []
        cur.append(i)
    if cur:
        runs.append(cur)

    # Pad each run without reaching into the neighbouring (possibly dropped) words.
    duration = data.get("duration") or (words[-1]["end"] if words else 0)
    padded = []
    for run in runs:
        first, last = run[0], run[-1]
        lo = words[first - 1]["end"] if first > 0 else 0.0
        hi = words[last + 1]["start"] if last + 1 < len(words) else duration
        s = max(lo, words[first]["start"] - args.pad)
        e = min(hi, words[last]["end"] + args.pad)
        if padded and s <= padded[-1][1]:
            padded[-1][1] = max(padded[-1][1], e)
        else:
            padded.append([round(s, 3), round(e, 3)])

    before = duration
    after = sum(e - s for s, e in padded)
    edl = {"source": data.get("source", ""), "keep": padded, "cut": [], "removed": removed}
    Path(args.output).parent.mkdir(parents=True, exist_ok=True)
    Path(args.output).write_text(json.dumps(edl, ensure_ascii=False, indent=1))
    print(f"tighten: {len(padded)} segments, {before:.1f} s → {after:.1f} s, "
          f"{len(removed)} filler word(s) removed → {args.output}", file=sys.stderr)


def subtract(ranges, cuts):
    out = []
    for s, e in ranges:
        pieces = [[s, e]]
        for cs, ce in cuts:
            nxt = []
            for ps, pe in pieces:
                if ce <= ps or cs >= pe:
                    nxt.append([ps, pe])
                    continue
                if cs > ps:
                    nxt.append([ps, cs])
                if ce < pe:
                    nxt.append([ce, pe])
            pieces = nxt
        out += [p for p in pieces if p[1] - p[0] > 0.05]
    return out


def has_audio(src):
    r = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a", "-show_entries", "stream=index",
                        "-of", "csv=p=0", src], capture_output=True, text=True)
    return bool(r.stdout.strip())


def render(args):
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg not found on PATH")
    edl = json.loads(Path(args.edl).read_text())
    segs = subtract(edl["keep"], edl.get("cut", []))
    if not segs:
        sys.exit("EDL has nothing to keep")
    src, out = args.render
    audio = has_audio(src)

    parts, labels = [], []
    for i, (s, e) in enumerate(segs):
        d = e - s
        parts.append(f"[0:v]trim=start={s:.3f}:end={e:.3f},setpts=PTS-STARTPTS[v{i}]")
        labels.append(f"[v{i}]")
        if audio:
            fade = min(0.01, d / 4)
            parts.append(f"[0:a]atrim=start={s:.3f}:end={e:.3f},asetpts=PTS-STARTPTS,"
                         f"afade=t=in:d={fade:.3f},afade=t=out:st={d - fade:.3f}:d={fade:.3f}[a{i}]")
            labels.append(f"[a{i}]")
    n = len(segs)
    parts.append("".join(labels) + f"concat=n={n}:v=1:a={1 if audio else 0}[v]" + ("[a]" if audio else ""))
    graph = ";".join(parts)

    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-stats", "-y", "-i", src,
           "-filter_complex", graph, "-map", "[v]"]
    if audio:
        cmd += ["-map", "[a]", "-c:a", "aac", "-b:a", "192k", "-ar", "48000"]
    cmd += ["-c:v", "libx264", "-crf", "18", "-preset", "medium", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", out]
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(cmd, check=True)
    print(f"tighten: rendered {n} segment(s), {sum(e - s for s, e in segs):.1f} s → {out}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("words", nargs="?", help="words JSON from transcribe.py")
    ap.add_argument("-o", "--output", help="EDL path to write")
    ap.add_argument("--max-gap", type=float, default=0.35, help="pauses longer than this are cut (s)")
    ap.add_argument("--pad", type=float, default=0.06, help="padding kept around each segment (s)")
    ap.add_argument("--fillers", default=DEFAULT_FILLERS, help=f"comma-separated filler words/phrases (default: {DEFAULT_FILLERS})")
    ap.add_argument("--render", nargs=2, metavar=("SOURCE", "OUT"), help="render SOURCE through --edl to OUT")
    ap.add_argument("--edl", help="EDL to render")
    args = ap.parse_args()

    if args.render:
        if not args.edl:
            ap.error("--render needs --edl")
        render(args)
    else:
        if not (args.words and args.output):
            ap.error("planning needs WORDS and -o EDL")
        plan(args)


if __name__ == "__main__":
    main()
