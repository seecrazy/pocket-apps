#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v tuist >/dev/null 2>&1; then
  echo "tuist not found. Install Tuist 4.39.0 first."
  echo "  brew install tuist"
  exit 1
fi

echo "Generating Xcode workspace..."
tuist generate --no-open
