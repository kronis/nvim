#!/usr/bin/env bash
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install from https://brew.sh and re-run." >&2
  exit 1
fi

PACKAGES=(ripgrep fd node git)

for pkg in "${PACKAGES[@]}"; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    echo "  ✓ $pkg already installed"
  else
    echo "  → installing $pkg"
    brew install "$pkg"
  fi
done
