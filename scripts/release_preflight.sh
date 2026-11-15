#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

apps=(
  SoloGuard
  FocusBox
  SlowCard
  AmbientLog
  TabStash
  AtEase
)

echo "==> Checking release metadata"
for app in "${apps[@]}"; do
  manifest="Apps/$app/Project.swift"
  privacy="Apps/$app/Resources/PrivacyInfo.xcprivacy"
  icon="Apps/$app/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
  bundle="com.pocketapps.$(echo "$app" | tr '[:upper:]' '[:lower:]')"
  metadata="fastlane/metadata/$bundle"

  test -f "$manifest" || { echo "Missing manifest: $manifest"; exit 1; }
  test -f "$privacy" || { echo "Missing privacy manifest: $privacy"; exit 1; }
  test -f "$icon" || { echo "Missing app icon: $icon"; exit 1; }
  test -f "$metadata/name.txt" || { echo "Missing App Store name: $metadata/name.txt"; exit 1; }
  test -f "$metadata/description.txt" || { echo "Missing App Store description: $metadata/description.txt"; exit 1; }
  plutil -lint "$privacy" >/dev/null
  for file in "$metadata"/*.txt; do
    if [ ! -s "$file" ]; then
      echo "Empty metadata file: $file"
      exit 1
    fi
  done

  expected_version="1.3.0"
  if [ "$app" == "AtEase" ]; then
    expected_version="1.0.0"
  fi
  if ! grep -q "version: \"$expected_version\"" "$manifest"; then
    echo "Expected version $expected_version in $manifest"
    exit 1
  fi
  echo "OK: $app"
done

echo "==> Generating workspace"
./scripts/generate.sh

echo "==> Linting"
./scripts/lint.sh

echo "==> Testing shared packages"
./scripts/test.sh

echo "==> Testing apps"
IOS_SIMULATOR_NAME="${IOS_SIMULATOR_NAME:-iPhone 17}" ./scripts/test_apps.sh

echo "==> Building release candidates"
./scripts/build_apps.sh

echo "Release preflight passed."
