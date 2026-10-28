#!/usr/bin/env bash
# Make the video-editor skill discoverable by Claude Code, Codex and OpenCode.
#
#   link.sh                 link into <project>/.claude/skills, .agents/skills, .opencode/skills
#   link.sh --global        link into ~/.claude/skills, ~/.agents/skills, ~/.config/opencode/skills
#   link.sh --copy          copy instead of symlink (for tools or filesystems that ignore symlinks)
#   link.sh --project DIR   project root to link into (default: parent of the skill folder)
#   link.sh --unlink        remove the links/copies this script created
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_NAME="$(basename "$SKILL_DIR")"
PROJECT="$(dirname "$SKILL_DIR")"
MODE=project
METHOD=link
ACTION=install

while [ $# -gt 0 ]; do
  case "$1" in
    --global) MODE=global ;;
    --copy) METHOD=copy ;;
    --project) PROJECT="$(cd "$2" && pwd)"; shift ;;
    --unlink) ACTION=remove ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ "$MODE" = global ]; then
  TARGETS=("$HOME/.claude/skills" "$HOME/.agents/skills" "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills")
else
  TARGETS=("$PROJECT/.claude/skills" "$PROJECT/.agents/skills" "$PROJECT/.opencode/skills")
fi

for dir in "${TARGETS[@]}"; do
  dest="$dir/$SKILL_NAME"
  if [ "$ACTION" = remove ]; then
    if [ -L "$dest" ] || [ -f "$dest/.installed-by-link-sh" ]; then
      rm -rf "$dest" && echo "removed  $dest"
    fi
    continue
  fi

  mkdir -p "$dir"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] || [ -f "$dest/.installed-by-link-sh" ]; then
      rm -rf "$dest"
    else
      echo "skip     $dest (exists and was not created by link.sh)" >&2
      continue
    fi
  fi

  if [ "$METHOD" = copy ]; then
    cp -R "$SKILL_DIR" "$dest"
    touch "$dest/.installed-by-link-sh"
    echo "copied   $dest"
  else
    if [ "$MODE" = project ] && command -v realpath >/dev/null 2>&1 && realpath --help 2>&1 | grep -q -- --relative-to; then
      src="$(realpath --relative-to="$dir" "$SKILL_DIR")"
    else
      src="$SKILL_DIR"
    fi
    ln -s "$src" "$dest"
    echo "linked   $dest -> $src"
  fi
done
