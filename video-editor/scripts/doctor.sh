#!/usr/bin/env bash
# Check the video-editor toolchain, reel environment and connections.
#
#   doctor.sh          required tools must pass; reel environment and connections are warnings
#   doctor.sh --reel   also require the reel environment (run before a five-pass reel)
#   doctor.sh --drive  also require the Google Drive remote (run before delivery)
#
# Prints one line per check (ok / warn / FAIL). Exits 1 if any required check fails.
# Never prints secret values — only whether a variable is set.
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REQUIRE_REEL=0
REQUIRE_DRIVE=0
for arg in "$@"; do
  case "$arg" in
    --reel) REQUIRE_REEL=1 ;;
    --drive) REQUIRE_DRIVE=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

FAILS=0
WARNS=0
ok()   { printf '  ok    %-22s %s\n' "$1" "${2:-}"; }
warn() { printf '  warn  %-22s %s\n' "$1" "${2:-}"; WARNS=$((WARNS + 1)); }
fail() { printf '  FAIL  %-22s %s\n' "$1" "${2:-}"; FAILS=$((FAILS + 1)); }
# miss REQUIRED NAME DETAIL — report a failure as FAIL (required) or warn (optional)
miss() { if [ "$1" = 1 ]; then fail "$2" "$3"; else warn "$2" "$3"; fi; }

echo "Workspace ($PROJECT_ROOT)"
profile="$PROJECT_ROOT/brand/profile.md"
if [ ! -f "$profile" ]; then
  warn brand-profile "missing — run the brand interview (references/brand-onboarding.md)"
elif grep -q '{{' "$profile"; then
  warn brand-profile "incomplete — $(grep -c '{{' "$profile") placeholder line(s) left"
elif ! grep -qi 'Confirmed by user: *yes' "$profile"; then
  warn brand-profile "not confirmed by the user yet"
else
  ok brand-profile "confirmed"
fi
if [ -f "$PROJECT_ROOT/memory/index.md" ]; then ok memory "memory/index.md"
else warn memory "missing — create from templates/memory-index.md"; fi

echo "Tools"
if have ffmpeg; then
  v="$(ffmpeg -hide_banner -version 2>/dev/null | head -1 | awk '{print $3}')"
  encoders="$(ffmpeg -hide_banner -encoders 2>/dev/null)"
  filters="$(ffmpeg -hide_banner -filters 2>/dev/null)"
  if ! grep -q libx264 <<<"$encoders"; then fail ffmpeg "$v — missing libx264 encoder"
  elif ! grep -q loudnorm <<<"$filters"; then fail ffmpeg "$v — missing loudnorm filter"
  else ok ffmpeg "$v"; fi
else
  fail ffmpeg "not found"
fi
have ffprobe && ok ffprobe "$(command -v ffprobe)" || fail ffprobe "not found"

if have node; then
  v="$(node --version)"
  if [ "$(major "$v")" -ge 24 ]; then ok node "$v"; else fail node "$v — need >= 24"; fi
else
  fail node "not found (install with nvm: nvm install 24)"
fi
have npx && ok npx "$(npx --version 2>/dev/null)" || fail npx "not found"

if have python3; then
  v="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
  if python3 -c 'import sys; sys.exit(sys.version_info < (3, 10))'; then ok python3 "$v"; else fail python3 "$v — need >= 3.10"; fi
else
  fail python3 "not found"
fi

if c="$(find_chromium)"; then ok chromium "$c"; else fail chromium "not found (npx playwright install chromium)"; fi
have git && ok git "$(git --version | awk '{print $3}')" || fail git "not found"
have rclone && ok rclone "$(rclone version 2>/dev/null | head -1 | awk '{print $2}')" || fail rclone "not found"

if have hyperframes; then ok hyperframes "$(hyperframes --version 2>/dev/null | head -1)"
else warn hyperframes "global CLI not found; will use npx hyperframes (needs network)"; fi

echo "Reel environment"
if [ -L "$REEL_PYTHON" ] && [ ! -e "$REEL_PYTHON" ]; then
  miss "$REQUIRE_REEL" reel-venv "broken symlink $REEL_PYTHON -> $(readlink "$REEL_PYTHON"); run install.sh --skip-system"
elif [ ! -x "$REEL_PYTHON" ]; then
  miss "$REQUIRE_REEL" reel-venv "missing at $REEL_VENV; run install.sh"
else
  ok reel-venv "$("$REEL_PYTHON" --version 2>&1)"
  for mod in faster_whisper onnxruntime numpy cv2; do
    if "$REEL_PYTHON" -c "import $mod" 2>/dev/null; then ok "  $mod" ""
    else miss "$REQUIRE_REEL" "  $mod" "not importable in reel venv"; fi
  done
fi
if [ -s "$MATTE_MODEL" ]; then ok matte-model "$(basename "$MATTE_MODEL")"
else miss "$REQUIRE_REEL" matte-model "missing at $MATTE_MODEL; run install.sh"; fi

echo "Connections"
if have rclone && rclone listremotes 2>/dev/null | grep -qx "$GDRIVE_REMOTE:"; then
  ok gdrive "remote $GDRIVE_REMOTE: configured (verify: rclone lsd $GDRIVE_REMOTE:)"
else
  miss "$REQUIRE_DRIVE" gdrive "remote $GDRIVE_REMOTE: not configured; see references/connections-setup.md"
fi

provider=""
for var in ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY GOOGLE_API_KEY; do
  [ -n "${!var:-}" ] && provider="$provider $var"
done
if [ -n "$provider" ]; then ok ai-provider "set:$provider"
else ok ai-provider "no API key in env; using the host tool's own session"; fi

for var in HEYGEN_API_KEY HYPERFRAMES_API_KEY HEYGEN_ACCESS_TOKEN ELEVENLABS_API_KEY; do
  if [ -n "${!var:-}" ]; then ok "$var" "set (optional)"; fi
done

echo
if [ "$FAILS" -gt 0 ]; then
  echo "doctor: $FAILS required check(s) failed, $WARNS warning(s). Run scripts/install.sh --dry-run to see the fix."
  exit 1
fi
echo "doctor: ready ($WARNS warning(s))"
