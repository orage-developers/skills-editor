#!/usr/bin/env bash
# Install what doctor.sh reports missing. Safe to rerun: installed pieces are skipped.
#
#   install.sh                 system packages, Chromium, Hyperframes CLI, reel venv and model
#   install.sh --dry-run       print the plan without changing anything
#   install.sh --skip-system   no package manager / sudo (user-level steps only)
#   install.sh --skip-reel     skip the Python reel venv and matting model
#
# Exit codes: 0 done, 1 a step failed, 3 system packages need a command the user must run.
set -uo pipefail
# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY=0
SKIP_SYSTEM=0
SKIP_REEL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --skip-system) SKIP_SYSTEM=1 ;;
    --skip-reel) SKIP_REEL=1 ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

MODEL_URL="https://github.com/PeterL1n/RobustVideoMatting/releases/download/v1.0.0/rvm_mobilenetv3_fp32.onnx"
REEL_PACKAGES=(faster-whisper onnxruntime numpy opencv-python-headless)
STATUS=0
USER_CMD=""

step() { printf '\n==> %s\n' "$*"; }
run() {
  printf '    $ %s\n' "$*"
  [ "$DRY" = 1 ] && return 0
  "$@" || { echo "    step failed: $*" >&2; STATUS=1; return 1; }
}

# ---------------------------------------------------------------- system packages
detect_pm() {
  if [ "$(uname -s)" = Darwin ]; then have brew && echo brew; return; fi
  for pm in apt-get dnf pacman zypper brew; do have "$pm" && { echo "$pm"; return; }; done
}

# Map a logical package to the manager's package name.
pkg_name() {
  case "$1:$2" in
    apt-get:python) echo "python3 python3-venv python3-pip" ;;
    dnf:python|zypper:python) echo "python3 python3-pip" ;;
    pacman:python) echo "python python-pip" ;;
    brew:python) echo "python@3.12" ;;
    *:ffmpeg|*:rclone|*:git|*:curl) echo "$2" ;;
  esac
}

install_cmd() {
  case "$1" in
    apt-get) echo "apt-get update && apt-get install -y $2" ;;
    dnf) echo "dnf install -y $2" ;;
    pacman) echo "pacman -S --needed --noconfirm $2" ;;
    zypper) echo "zypper install -y $2" ;;
    brew) echo "brew install $2" ;;
  esac
}

missing=()
have ffmpeg && have ffprobe || missing+=(ffmpeg)
have rclone || missing+=(rclone)
have git || missing+=(git)
have curl || missing+=(curl)
if ! have python3 || ! python3 -c 'import sys, venv, ensurepip; sys.exit(sys.version_info < (3, 10))' 2>/dev/null; then
  missing+=(python)
fi

step "System packages"
if [ ${#missing[@]} -eq 0 ]; then
  echo "    all present"
elif [ "$SKIP_SYSTEM" = 1 ]; then
  echo "    skipped (--skip-system); missing: ${missing[*]}"
else
  PM="$(detect_pm)"
  if [ -z "$PM" ]; then
    echo "    no supported package manager found; install manually: ${missing[*]}"
    STATUS=1
  else
    names=""
    for m in "${missing[@]}"; do names="$names $(pkg_name "$PM" "$m")"; done
    cmd="$(install_cmd "$PM" "${names# }")"
    if [ "$PM" = brew ]; then
      run bash -c "$cmd"
    elif [ "$(id -u)" = 0 ]; then
      run bash -c "$cmd"
    elif sudo -n true 2>/dev/null; then
      run sudo bash -c "$cmd"
    else
      USER_CMD="sudo bash -c '$cmd'"
      echo "    sudo needs a password. Ask the user to run:"
      echo "      $USER_CMD"
    fi
  fi
fi

# ---------------------------------------------------------------- node tooling
step "Node.js"
if have node && [ "$(major "$(node --version)")" -ge 24 ]; then
  echo "    node $(node --version)"
else
  echo "    Node.js >= 24 is required and is not installed by this script."
  echo "    Recommended: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && nvm install 24"
  STATUS=1
fi

if have npm; then
  step "Hyperframes CLI"
  if have hyperframes; then
    echo "    $(hyperframes --version 2>/dev/null | head -1)"
  else
    run npm install -g hyperframes
  fi

  step "Chromium"
  if c="$(find_chromium)"; then
    echo "    found $c"
  else
    run npx -y playwright install chromium
  fi
fi

# ---------------------------------------------------------------- reel environment
if [ "$SKIP_REEL" = 0 ]; then
  step "Reel Python environment ($REEL_VENV)"
  PY="$(command -v python3 || true)"
  if [ -z "$PY" ]; then
    echo "    python3 missing; rerun after the system packages are installed"
    STATUS=1
  else
    reel_ok=0
    if [ -x "$REEL_PYTHON" ] && "$REEL_PYTHON" -c "import faster_whisper, onnxruntime, numpy, cv2" 2>/dev/null; then
      reel_ok=1
    fi
    if [ "$reel_ok" = 1 ]; then
      echo "    ok ($("$REEL_PYTHON" --version 2>&1))"
    elif ! "$PY" -c 'import venv, ensurepip' 2>/dev/null; then
      echo "    $PY can't create venvs (python3-venv missing); rerun after the system packages are installed"
      [ -n "$USER_CMD" ] || STATUS=1
    else
      if [ -L "$REEL_PYTHON" ] && [ ! -e "$REEL_PYTHON" ]; then
        echo "    interpreter symlink is broken; recreating the venv"
      fi
      run mkdir -p "$VIDEO_EDITOR_DATA"
      run "$PY" -m venv --clear "$REEL_VENV" &&
        run "$REEL_VENV/bin/python" -m pip install --quiet --upgrade pip &&
        run "$REEL_VENV/bin/python" -m pip install --quiet "${REEL_PACKAGES[@]}"
    fi
  fi

  step "Matting model"
  if [ -s "$MATTE_MODEL" ]; then
    echo "    ok ($MATTE_MODEL)"
  elif have curl; then
    run mkdir -p "$(dirname "$MATTE_MODEL")" &&
      run curl -fsSL --retry 3 -o "$MATTE_MODEL.part" "$MODEL_URL" &&
      run mv "$MATTE_MODEL.part" "$MATTE_MODEL"
  else
    echo "    curl missing; rerun after the system packages are installed"
    STATUS=1
  fi
fi

# ---------------------------------------------------------------- summary
echo
if [ "$DRY" = 1 ]; then
  echo "install: dry run only — nothing changed."
  [ -n "$USER_CMD" ] && echo "install: the user must run: $USER_CMD"
  exit 0
fi
if [ -n "$USER_CMD" ]; then
  echo "install: user-level steps done. Waiting on system packages — the user must run:"
  echo "  $USER_CMD"
  echo "then rerun scripts/doctor.sh."
  exit 3
fi
[ "$STATUS" = 0 ] && echo "install: done. Run scripts/doctor.sh to confirm." || echo "install: some steps failed (see above)."
exit "$STATUS"
