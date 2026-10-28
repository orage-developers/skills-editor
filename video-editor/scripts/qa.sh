#!/usr/bin/env bash
# QA an export against the delivery spec and write frames for visual review.
#
#   qa.sh FILE.mp4             expected size from orientation: 9:16 → 1080x1920, 16:9 → 1920x1080, 1:1 → 1080x1080
#   qa.sh FILE.mp4 --no-audio  skip loudness checks (silent videos)
#
# Checks: H.264 yuv420p, AAC 48 kHz, 30 fps, size, −14 LUFS ±1, true peak < −1 dBTP, fast-start.
# Writes <name>-first.png, <name>-1.2s.png and <name>-sheet.png to jobs/<job>/work/qa/
# (or a qa/ folder next to the file). Exits 1 if a check fails.
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FILE=""
AUDIO=1
for arg in "$@"; do
  case "$arg" in
    --no-audio) AUDIO=0 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) FILE="$arg" ;;
  esac
done
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: qa.sh FILE.mp4 [--no-audio]" >&2; exit 2; }
have ffprobe && have ffmpeg || { echo "qa: ffmpeg/ffprobe not installed — run scripts/doctor.sh" >&2; exit 2; }

FAILS=0
ok()   { printf '  ok    %-14s %s\n' "$1" "$2"; }
warn() { printf '  warn  %-14s %s\n' "$1" "$2"; }
fail() { printf '  FAIL  %-14s %s\n' "$1" "$2"; FAILS=$((FAILS + 1)); }

probe() { ffprobe -v error -select_streams "$1" -show_entries "stream=$2" -of default=nw=1:nk=1 "$FILE" | head -1; }

echo "QA $FILE"

# Video stream
vcodec="$(probe v:0 codec_name)"
pix="$(probe v:0 pix_fmt)"
w="$(probe v:0 width)"; h="$(probe v:0 height)"
rate="$(probe v:0 avg_frame_rate)"
fps="$(awk -F/ '{ if ($2 > 0) printf "%.3f", $1 / $2; else print $1 }' <<<"$rate")"
dur="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$FILE")"

[ "$vcodec" = h264 ] && ok codec "h264" || fail codec "${vcodec:-none} (want h264)"
[ "$pix" = yuv420p ] && ok pix_fmt "$pix" || fail pix_fmt "${pix:-none} (want yuv420p)"

if [ "${w:-0}" -lt "${h:-0}" ]; then want="1080x1920"
elif [ "${w:-0}" -gt "${h:-0}" ]; then want="1920x1080"
else want="1080x1080"; fi
[ "${w}x${h}" = "$want" ] && ok size "${w}x${h}" || fail size "${w}x${h} (want $want)"

if awk -v f="$fps" 'BEGIN { exit !(f > 29.99 && f < 30.01) }'; then ok fps "$fps"
elif awk -v f="$fps" 'BEGIN { exit !(f > 29.9 && f < 30.1) }'; then warn fps "$fps (want exactly 30)"
else fail fps "$fps (want 30)"; fi
ok duration "$(printf '%.2f s' "$dur")"

# Fast-start: the moov atom must come before mdat.
order="$(python3 - "$FILE" <<'PY'
import struct, sys
with open(sys.argv[1], "rb") as f:
    seen = []
    while True:
        head = f.read(8)
        if len(head) < 8:
            break
        size, kind = struct.unpack(">I4s", head)
        if size == 1:
            size = struct.unpack(">Q", f.read(8))[0]
            f.seek(size - 16, 1)
        elif size == 0:
            seen.append(kind.decode("latin1"))
            break
        else:
            f.seek(size - 8, 1)
        seen.append(kind.decode("latin1"))
        if kind in (b"moov", b"mdat") and len({"moov", "mdat"} & set(seen)) == 2:
            break
print(" ".join(seen))
PY
)"
if [[ " $order " == *" moov "*" mdat "* ]]; then ok faststart "moov before mdat"
else fail faststart "moov after mdat — re-mux with -movflags +faststart"; fi

# Audio
acodec="$(probe a:0 codec_name)"
if [ "$AUDIO" = 0 ]; then
  warn audio "skipped (--no-audio)"
elif [ -z "$acodec" ]; then
  fail audio "no audio stream (pass --no-audio if intended)"
else
  rate_hz="$(probe a:0 sample_rate)"
  [ "$acodec" = aac ] && ok audio "aac ${rate_hz} Hz" || fail audio "$acodec (want aac)"
  [ "$rate_hz" = 48000 ] || warn sample-rate "$rate_hz Hz (want 48000)"

  stats="$(ffmpeg -hide_banner -nostats -i "$FILE" -map 0:a:0 -af loudnorm=I=-14:TP=-1.5:print_format=json -f null - 2>&1 | sed -n '/^{/,/^}/p')"
  li="$(sed -n 's/.*"input_i" *: *"\([^"]*\)".*/\1/p' <<<"$stats")"
  tp="$(sed -n 's/.*"input_tp" *: *"\([^"]*\)".*/\1/p' <<<"$stats")"
  if [ -z "$li" ]; then
    fail loudness "could not measure"
  else
    if awk -v v="$li" 'BEGIN { exit !(v >= -15 && v <= -13) }'; then ok loudness "$li LUFS"
    else fail loudness "$li LUFS (want -14 ±1)"; fi
    if awk -v v="$tp" 'BEGIN { exit !(v < -1) }'; then ok true-peak "$tp dBTP"
    else fail true-peak "$tp dBTP (want < -1)"; fi
  fi
fi

# Frames for visual review
dir="$(cd "$(dirname "$FILE")" && pwd)"
if [ "$(basename "$dir")" = out ] && [ -d "$dir/../work" ]; then qa_dir="$(cd "$dir/../work" && pwd)/qa"; else qa_dir="$dir/qa"; fi
mkdir -p "$qa_dir"
name="$(basename "${FILE%.*}")"
tile_cols=6
[ "${w:-0}" -lt "${h:-0}" ] && tile_cols=8
step="$(awk -v d="$dur" -v n="$((tile_cols * 3))" 'BEGIN { s = d / n; if (s < 0.1) s = 0.1; printf "%.3f", s }')"
ffmpeg -hide_banner -loglevel error -y -i "$FILE" -frames:v 1 "$qa_dir/$name-first.png"
ffmpeg -hide_banner -loglevel error -y -ss 1.2 -i "$FILE" -frames:v 1 "$qa_dir/$name-1.2s.png"
ffmpeg -hide_banner -loglevel error -y -i "$FILE" -vf "fps=1/$step,scale=240:-1,tile=${tile_cols}x3" -frames:v 1 "$qa_dir/$name-sheet.png"
ok frames "$qa_dir/$name-{first,1.2s,sheet}.png — review them visually"

echo
if [ "$FAILS" -gt 0 ]; then echo "qa: $FAILS check(s) failed"; exit 1; fi
echo "qa: pass"
