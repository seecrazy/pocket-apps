#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

packages=(
  PocketCore
  PocketUI
  PocketTestKit
)

simulator_name="${IOS_SIMULATOR_NAME:-iPhone 17}"

for package in "${packages[@]}"; do
  echo "Testing ${package} on iOS Simulator ${simulator_name}..."
  (
    cd "Packages/${package}"
    xcodebuild \
      -scheme "$package" \
      -destination "platform=iOS Simulator,name=${simulator_name},OS=latest" \
      test
  )
done
