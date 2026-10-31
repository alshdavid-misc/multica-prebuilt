#!/usr/bin/env bash
set -euo pipefail

# Prints the Multica release tag to use. Honours MULTICA_TAG if already set so
# separate scripts (build, CLI download) stay on the same release.

if [ -n "${MULTICA_TAG:-}" ]; then
  echo "$MULTICA_TAG"
  exit 0
fi

REPO="multica-ai/multica"

LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  echo "Error: Could not fetch the latest release tag." >&2
  exit 1
fi

echo "$LATEST_TAG"
