#!/usr/bin/env bash
set -euo pipefail

is_termux() { [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]]; }

log(){ printf '%s\n' "$*" >&2; }

# --- Detect platform ---
if is_termux; then
  PLATFORM="termux"
else
  PLATFORM="ubuntu"
fi

# --- Install deps ---
if [[ "$PLATFORM" == "termux" ]]; then
  pkg update -y
  pkg install -y bash coreutils yt-dlp ffmpeg aria2 lynx pandoc nodejs xclip || true
  termux-setup-storage || true
  npm i -g readability-cli || true
else
  sudo apt update -y
  sudo apt install -y yt-dlp ffmpeg aria2 lynx pandoc xdg-user-dirs xclip wl-clipboard nodejs npm
  sudo npm i -g readability-cli || true
  xdg-user-dirs-update || true
fi

# --- Install helper ---
mkdir -p "$HOME/.scripts"
cat > "$HOME/.scripts/common.sh" <<"EOF"
#!/usr/bin/env bash
# Common helpers for Termux + Ubuntu

is_termux(){ [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]]; }

_xdg_dir(){
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

documents_dir(){ if is_termux; then echo "$HOME/storage/shared/Documents"; else _xdg_dir DOCUMENTS; fi; }
pictures_dir(){  if is_termux; then echo "$HOME/storage/shared/Pictures";  else _xdg_dir PICTURES;  fi; }
music_dir(){     if is_termux; then echo "$HOME/storage/shared/Music";     else _xdg_dir MUSIC;     fi; }
videos_dir(){    if is_termux; then echo "$HOME/storage/shared/Movies";    else _xdg_dir VIDEOS;    fi; }
downloads_dir(){ if is_termux; then echo "$HOME/storage/shared/Download";  else _xdg_dir DOWNLOAD;  fi; }

ensure_dir(){ mkdir -p "$1"; }

clipboard_get(){
  if command -v termux-clipboard-get >/dev/null 2>&1; then termux-clipboard-get; return; fi
  if command -v wl-paste >/dev/null 2>&1; then wl-paste --no-newline; return; fi
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard -o 2>/dev/null; return; fi
  if command -v xsel  >/dev/null 2>&1; then xsel --clipboard --output 2>/dev/null; return; fi
  return 1
}

media_scan(){ if command -v termux-media-scan >/dev/null 2>&1; then termux-media-scan "$@"; fi; }

sanitize_filename(){ printf '%s' "$1" | sed 's#[/:*?"<>|]#_#g; s/  \+/_/g'; }
EOF
chmod +x "$HOME/.scripts/common.sh"