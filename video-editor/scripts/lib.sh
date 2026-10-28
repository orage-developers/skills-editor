# Shared helpers for video-editor scripts. Source it; don't run it.
# shellcheck shell=bash

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Load KEY=VALUE pairs from the project's .env without executing it.
# Variables already set in the environment win.
load_env() {
  local file="${1:-$PROJECT_ROOT/.env}" line key value
  [ -f "$file" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
    key="${BASH_REMATCH[2]}"
    value="${BASH_REMATCH[3]}"
    if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
      value="${BASH_REMATCH[1]}"
    else
      value="${value%%[[:space:]]#*}"
      value="${value%"${value##*[![:space:]]}"}"
    fi
    [ -n "${!key+x}" ] || export "$key=$value"
  done < "$file"
}

load_env

VIDEO_EDITOR_DATA="${VIDEO_EDITOR_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/video-editor}"
REEL_VENV="${REEL_VENV:-$VIDEO_EDITOR_DATA/reel-venv}"
REEL_PYTHON="${REEL_PYTHON:-$REEL_VENV/bin/python}"
MATTE_MODEL="${MATTE_MODEL:-$VIDEO_EDITOR_DATA/models/rvm_mobilenetv3_fp32.onnx}"
GDRIVE_REMOTE="${GDRIVE_REMOTE:-gdrive}"
GDRIVE_FOLDER="${GDRIVE_FOLDER:-Video Editor}"
export VIDEO_EDITOR_DATA REEL_VENV REEL_PYTHON MATTE_MODEL GDRIVE_REMOTE GDRIVE_FOLDER

have() { command -v "$1" >/dev/null 2>&1; }

# Major version of a "vX.Y.Z" / "X.Y.Z" string.
major() { local v="${1#v}"; echo "${v%%.*}"; }

# Find a Chromium-family browser: Playwright cache first, then system browsers.
find_chromium() {
  local c
  for c in "${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"/chromium-*/chrome-linux*/chrome \
           "$HOME/Library/Caches/ms-playwright"/chromium-*/chrome-mac*/Chromium.app/Contents/MacOS/Chromium; do
    [ -x "$c" ] && { echo "$c"; return 0; }
  done
  for c in chromium chromium-browser google-chrome google-chrome-stable; do
    have "$c" && { command -v "$c"; return 0; }
  done
  c="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  [ -x "$c" ] && { echo "$c"; return 0; }
  return 1
}
