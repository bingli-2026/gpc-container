#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/local/project-kit/0.1.0"

mkdir -p "$DEST"
cp "$ROOT/typst.toml" "$DEST/typst.toml"
cp "$ROOT/project-kit.typ" "$DEST/project-kit.typ"

echo "Installed project-kit to: $DEST"
echo 'Use: #import "@local/project-kit:0.1.0": *'
