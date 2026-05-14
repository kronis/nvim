#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/kronis/nvim.git}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/kronvim}"
NVIM_CONFIG="$HOME/.config/nvim"

DEV_MODE=0

logo() {
  cat <<'EOF'

██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░░░██╗██╗███╗░░░███╗
██║░██╔╝██╔══██╗██╔══██╗████╗░██║██║░░░██║██║████╗░████║
█████═╝░██████╔╝██║░░██║██╔██╗██║╚██╗░██╔╝██║██╔████╔██║
██╔═██╗░██╔══██╗██║░░██║██║╚████║░╚████╔╝░██║██║╚██╔╝██║
██║░╚██╗██║░░██║╚█████╔╝██║░╚███║░░╚██╔╝░░██║██║░╚═╝░██║
╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dev) DEV_MODE=1 ;;
      -h|--help)
        echo "Usage: installer.sh [--dev]"
        echo "  --dev   Symlink ~/.config/nvim to this repo (for development)"
        exit 0
        ;;
      *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
    shift
  done
}

ensure_deps() {
  echo "[deps] Ensuring system dependencies via Homebrew..."
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  bash "$script_dir/setup-brew.sh"
}

install_repo() {
  if [[ "$DEV_MODE" == "1" ]]; then
    INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    echo "[install] Dev mode: using repo at $INSTALL_DIR"
    return
  fi

  if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "[install] Repo exists at $INSTALL_DIR — pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only
  else
    echo "[install] Cloning $REPO_URL into $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
}

link_config() {
  local target="$INSTALL_DIR/config"

  if [[ ! -d "$target" ]]; then
    echo "[link] ERROR: $target does not exist" >&2
    exit 1
  fi

  if [[ -L "$NVIM_CONFIG" ]]; then
    echo "[link] Replacing existing symlink at $NVIM_CONFIG"
    rm "$NVIM_CONFIG"
  elif [[ -e "$NVIM_CONFIG" ]]; then
    local backup="$NVIM_CONFIG.bak-$(date +%Y%m%d-%H%M%S)"
    echo "[link] Backing up existing $NVIM_CONFIG → $backup"
    mv "$NVIM_CONFIG" "$backup"
  fi

  mkdir -p "$(dirname "$NVIM_CONFIG")"
  ln -s "$target" "$NVIM_CONFIG"
  echo "[link] Symlinked $NVIM_CONFIG → $target"
}

main() {
  logo
  parse_args "$@"
  ensure_deps
  install_repo
  link_config
  echo ""
  echo "Done. Launch nvim — lazy.nvim will install plugins on first run."
}

main "$@"
