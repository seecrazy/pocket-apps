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

simulator_name="${IOS_SIMULATOR_NAME:-iPhone 17}"

for app in "${apps[@]}"; do
  echo "Testing ${app} on iOS Simulator ${simulator_name}..."
  xcodebuild \
    -workspace PocketApps.xcworkspace \
    -scheme "$app" \
    -destination "platform=iOS Simulator,name=${simulator_name},OS=latest" \
    test
done
