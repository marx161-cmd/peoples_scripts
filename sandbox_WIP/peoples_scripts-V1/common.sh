#!/usr/bin/env bash
set -euo pipefail

log(){ printf '%s\n' "$*" >&2; }
is_termux(){ [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]]; }

# -------- Detect platform --------
if is_termux; then
  PLATFORM="termux"
else
  PLATFORM="ubuntu"
fi
log "Detected: $PLATFORM"

# -------- Install deps --------
if [[ "$PLATFORM" == "termux" ]]; then
  # Termux packages (Android)
  pkg update -y
  pkg install -y bash coreutils python-yt-dlp ffmpeg aria2 lynx pandoc nodejs termux-api jq

  # Set up Android storage links (safe to re-run)
  termux-setup-storage || true

  # readability-cli is optional; only try if npm exists
  if command -v npm >/dev/null 2>&1; then
    npm i -g readability-cli || true
  else
    log "npm not found — skipping readability-cli (optional)."
  fi

else
  # Ubuntu / Debian-ish
  sudo apt update -y
  sudo apt install -y yt-dlp ffmpeg aria2 lynx pandoc xdg-user-dirs xclip wl-clipboard nodejs npm jq
  sudo npm i -g readability-cli || true
  xdg-user-dirs-update || true
fi

# -------- Install helper to ~/.scripts/common.sh --------
mkdir -p "$HOME/.scripts"

# If a project copy of common.sh is present, prefer that. Else install a built-in one.
if [[ -f "./common.sh" ]]; then
  install -m 0755 "./common.sh" "$HOME/.scripts/common.sh"
  log "Installed helper from project common.sh"
else
  cat > "$HOME/.scripts/common.sh" <<"EOF"
#!/usr/bin/env bash
# Common helpers for Termux + Ubuntu

is_termux() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]]
}

# ------- XDG-aware target folders -------
_xdg_dir() {
  local key="$1"
  if command -v xdg-user-dir >/dev/null 2>&1; then
    xdg-user-dir "$key"
  else
    case "$key" in
      DOCUMENTS) echo "$HOME/Documents" ;;
      PICTURES)  echo "$HOME/Pictures" ;;
      MUSIC)     echo "$HOME/Music" ;;
      VIDEOS)    echo "$HOME/Videos" ;;
      DOWNLOAD)  echo "$HOME/Downloads" ;;
      *)         echo "$HOME" ;;
    esac
  fi
}

documents_dir() { if is_termux; then echo "$HOME/storage/shared/Documents"; else _xdg_dir DOCUMENTS; fi; }
pictures_dir()  { if is_termux; then echo "$HOME/storage/shared/Pictures";  else _xdg_dir PICTURES;  fi; }
music_dir()     { if is_termux; then echo "$HOME/storage/shared/Music";     else _xdg_dir MUSIC;     fi; }
videos_dir()    { if is_termux; then echo "$HOME/storage/shared/Movies";    else _xdg_dir VIDEOS;    fi; }
downloads_dir() { if is_termux; then echo "$HOME/storage/shared/Download";  else _xdg_dir DOWNLOAD;  fi; }

ensure_dir(){ mkdir -p "$1"; }

# ------- Clipboard (Termux / Wayland / X11) -------
clipboard_get(){
  if command -v termux-clipboard-get >/dev/null 2>&1; then termux-clipboard-get; return; fi
  if command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline; return; fi
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o 2>/dev/null; return; fi
  if command -v xsel  >/dev/null 2>&1; then xsel --clipboard --output 2>/dev/null; return; fi
  return 1
}

# ------- Media scan (Android only) -------
media_scan(){ if command -v termux-media-scan >/dev/null 2>&1; then termux-media-scan "$@"; fi; }

# ------- Utilities -------
sanitize_filename(){ printf '%s' "$1" | sed 's#[/:*?"<>|]#_#g; s/  \+/_/g'; }
EOF
  chmod +x "$HOME/.scripts/common.sh"
  log "Installed built-in helper to ~/.scripts/common.sh"
fi

# -------- Optional: add ~/scripts to PATH (only once) --------
if ! grep -q 'export PATH="$HOME/scripts:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  printf '\nexport PATH="$HOME/scripts:$PATH"\n' >> "$HOME/.bashrc"
  log 'Added ~/scripts to PATH in ~/.bashrc (run: source ~/.bashrc)'
fi

log "Setup complete ✅"