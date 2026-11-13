#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

swiftformat --lint .
swiftlint lint --quiet
