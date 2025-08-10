#!/usr/bin/env bash
set -euo pipefail

log(){ printf '%s\n' "$*" >&2; }
is_termux(){ [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/* ]]; }

# ---- Flags ----
RUN_DEPS=true
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-deps) RUN_DEPS=false; shift ;;
    --force)   FORCE=true; shift ;;
    -h|--help)
      cat <<EOF
Usage: ./install.sh [--no-deps] [--force]

--no-deps   Skip running ./setup.sh (dependency install)
--force     Overwrite existing files in targets
EOF
      exit 0
      ;;
    *) log "Unknown option: $1"; exit 1 ;;
  esac
done

# ---- 1) Dependencies via setup.sh ----
if $RUN_DEPS; then
  if [[ -x ./setup.sh ]]; then
    log "Running setup.sh (deps + helper install)…"
    ./setup.sh
  else
    log "setup.sh not found or not executable; skipping deps."
  fi
fi

# ---- 2) Targets ----
SCRIPTS_DIR="$HOME/scripts"
SHORTCUTS_DIR="$HOME/.shortcuts"
mkdir -p "$SCRIPTS_DIR"
is_termux && mkdir -p "$SHORTCUTS_DIR"

# ---- 3) Copy scripts to ~/scripts ----
# We copy top-level .sh files, but skip the installer/installer-adjacent files.
shopt -s nullglob
mapfile -t TOPLEVEL_SCRIPTS < <(ls -1 ./*.sh | sed -E 's#^./##' | grep -Ev '^(install\.sh|setup\.sh)$')

if [[ ${#TOPLEVEL_SCRIPTS[@]} -eq 0 ]]; then
  log "No scripts to install at repo root."
else
  log "Installing scripts to $SCRIPTS_DIR:"
  for f in "${TOPLEVEL_SCRIPTS[@]}"; do
    if $FORCE; then
      install -m 0755 "./$f" "$SCRIPTS_DIR/$f"
    else
      # no overwrite unless forced
      [[ -e "$SCRIPTS_DIR/$f" ]] && { log "  - $f (exists, skip)"; continue; }
      install -m 0755 "./$f" "$SCRIPTS_DIR/$f"
    fi
    log "  - $f"
  done
fi

# ---- 4) Copy Termux widget wrappers (if present) ----
if is_termux && [[ -d ./shortcuts ]]; then
  shopt -s nullglob
  mapfile -t WRAPPERS < <(ls -1 ./shortcuts/*.sh 2>/dev/null | sed -E 's#^./shortcuts/##')
  if [[ ${#WRAPPERS[@]} -gt 0 ]]; then
    log "Installing Termux shortcuts to $SHORTCUTS_DIR:"
    for f in "${WRAPPERS[@]}"; do
      if $FORCE; then
        install -m 0755 "./shortcuts/$f" "$SHORTCUTS_DIR/$f"
      else
        [[ -e "$SHORTCUTS_DIR/$f" ]] && { log "  - $f (exists, skip)"; continue; }
        install -m 0755 "./shortcuts/$f" "$SHORTCUTS_DIR/$f"
      fi
      log "  - $f"
    done
    log "Note: refresh Termux Widget if new shortcuts don’t appear."
  fi
fi

# ---- 5) PATH tweak (optional QoL) ----
if ! command -v trans.sh >/dev/null 2>&1; then
  if ! grep -q 'export PATH="$HOME/scripts:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    printf '\nexport PATH="$HOME/scripts:$PATH"\n' >> "$HOME/.bashrc"
    log 'Added ~/scripts to PATH in ~/.bashrc (run: source ~/.bashrc or open a new shell).'
  fi
fi

log "✅ Install complete."