#!/usr/bin/env bash
# Upload a finished file to Google Drive, verify its size and print a link.
#
#   deliver.sh FILE                 → <remote>:<GDRIVE_FOLDER>/<YYYY-MM-DD>/FILE
#   deliver.sh FILE --date 2026-10-28
#   deliver.sh FILE --dry-run
#
# Uses GDRIVE_REMOTE (default gdrive) and GDRIVE_FOLDER (default "Video Editor") from the env or .env.
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FILE=""
DAY="$(date +%F)"
DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --date) DAY="$2"; shift ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) FILE="$1" ;;
  esac
  shift
done
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: deliver.sh FILE [--date YYYY-MM-DD] [--dry-run]" >&2; exit 2; }
have rclone || { echo "deliver: rclone not installed — see references/environment-setup.md" >&2; exit 2; }
rclone listremotes | grep -qx "$GDRIVE_REMOTE:" || {
  echo "deliver: rclone remote '$GDRIVE_REMOTE:' is not configured — see references/connections-setup.md" >&2; exit 2; }

name="$(basename "$FILE")"
dest="$GDRIVE_REMOTE:$GDRIVE_FOLDER/$DAY/$name"
local_size="$(wc -c < "$FILE" | tr -d ' ')"

echo "deliver: $FILE ($local_size bytes) → $dest"
if [ "$DRY" = 1 ]; then echo "deliver: dry run — nothing uploaded"; exit 0; fi

rclone copyto "$FILE" "$dest" --progress=false || { echo "deliver: upload failed" >&2; exit 1; }

remote_size="$(rclone size --json "$dest" 2>/dev/null | sed -n 's/.*"bytes":\([0-9]*\).*/\1/p')"
if [ "$remote_size" != "$local_size" ]; then
  echo "deliver: size mismatch — local $local_size, remote ${remote_size:-unknown}" >&2
  exit 1
fi
echo "deliver: verified $remote_size bytes on Drive"

if link="$(rclone link "$dest" 2>/dev/null)"; then
  echo "deliver: link $link"
else
  echo "deliver: no shareable link (sharing may be restricted); path: $dest"
fi
