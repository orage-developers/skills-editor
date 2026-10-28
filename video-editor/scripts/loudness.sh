#!/usr/bin/env bash
# Normalize a video's audio to −14 LUFS integrated with true peak below −1 dBTP. Video is stream-copied.
#
#   loudness.sh IN.mp4 OUT.mp4 [--target -14] [--ceiling -2]
#
# Measures, applies gain into a peak limiter, re-measures and corrects (up to 4 rounds) until the
# result is within ±0.5 LU of the target. Works where single loudnorm passes undershoot on speech.
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TARGET=-14
CEILING=-2   # limiter ceiling in dBFS; leaves room for AAC overshoot so true peak stays < −1 dBTP
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift ;;
    --ceiling) CEILING="$2"; shift ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) ARGS+=("$1") ;;
  esac
  shift
done
[ ${#ARGS[@]} -eq 2 ] || { echo "usage: loudness.sh IN.mp4 OUT.mp4 [--target -14] [--ceiling -2]" >&2; exit 2; }
IN="${ARGS[0]}"; OUT="${ARGS[1]}"
have ffmpeg || { echo "loudness: ffmpeg not installed" >&2; exit 2; }

# measure FILE → prints "I TP"
measure() {
  ffmpeg -hide_banner -nostats -i "$1" -map 0:a:0 -af loudnorm=print_format=json -f null - 2>&1 |
    sed -n '/^{/,/^}/p' | awk -F'"' '/"input_i"/ { i = $4 } /"input_tp"/ { tp = $4 } END { print i, tp }'
}

limit="$(awk -v c="$CEILING" 'BEGIN { printf "%.4f", 10 ^ (c / 20) }')"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gain=0
read -r li tp <<<"$(measure "$IN")"
[ -n "$li" ] || { echo "loudness: could not measure $IN (no audio?)" >&2; exit 1; }
echo "loudness: input $li LUFS, $tp dBTP"

for round in 1 2 3 4; do
  gain="$(awk -v g="$gain" -v t="$TARGET" -v i="$li" 'BEGIN { printf "%.2f", g + (t - i) }')"
  ffmpeg -hide_banner -loglevel error -y -i "$IN" -map 0 -c:v copy \
    -af "volume=${gain}dB,alimiter=limit=${limit}:attack=5:release=50:level=disabled" \
    -c:a aac -b:a 192k -ar 48000 -movflags +faststart "$tmp/out.mp4" || exit 1
  read -r li tp <<<"$(measure "$tmp/out.mp4")"
  echo "loudness: round $round gain ${gain} dB → $li LUFS, $tp dBTP"
  if awk -v i="$li" -v t="$TARGET" 'BEGIN { d = i - t; exit !(d <= 0.5 && d >= -0.5) }'; then break; fi
done

mkdir -p "$(dirname "$OUT")"
mv "$tmp/out.mp4" "$OUT"
if awk -v tp="$tp" 'BEGIN { exit !(tp < -1) }'; then
  echo "loudness: wrote $OUT"
else
  echo "loudness: wrote $OUT but true peak is $tp dBTP — rerun with --ceiling -3" >&2
  exit 1
fi
