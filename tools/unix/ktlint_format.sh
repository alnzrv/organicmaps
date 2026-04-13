#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/tools/hooks/format-config.bash"

if ! command -v ktlint >/dev/null 2>&1; then
  echo "Warning: ktlint not found, skipping Kotlin files."
  exit 0
fi

ktlint --version
echo "Running ktlint on Kotlin files..."

# Unlike clang-format (native, instant startup), ktlint runs on the JVM (~2s startup).
# Use find -exec + to batch all files into a single ktlint invocation.
for entry in "${KTLINT_TARGETS[@]}"; do
  dir="${entry%%|*}"
  pattern="${entry##*|}"
  [ -d "$REPO_ROOT/$dir" ] || continue
  find "$REPO_ROOT/$dir" -type f -name "$pattern" \
    -exec ktlint --editorconfig="$REPO_ROOT/android/.editorconfig" --format {} +
done

git diff --exit-code
