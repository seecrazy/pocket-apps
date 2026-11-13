#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

apps=(
  SoloGuard
  FocusBox
  SlowCard
  AmbientLog
  TabStash
)

for app in "${apps[@]}"; do
  echo "Building ${app}..."
  xcodebuild \
    -workspace PocketApps.xcworkspace \
    -scheme "$app" \
    -destination "generic/platform=iOS Simulator" \
    build
done
