#!/usr/bin/env bash
set -euo pipefail

MULTICA_LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/multica-ai/multica/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
PREBUILT_LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/alshdavid-misc/multica-prebuilt/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') || PREBUILT_LATEST_TAG="v0.0.0"

echo "MULTICA_LATEST_TAG:  $MULTICA_LATEST_TAG" >&2
echo "PREBUILT_LATEST_TAG: $PREBUILT_LATEST_TAG" >&2

HIGHEST_TAG=$(printf '%s\n%s\n' "$MULTICA_LATEST_TAG" "$PREBUILT_LATEST_TAG" | sort -V | tail -n1)

if [ "$MULTICA_LATEST_TAG" != "$PREBUILT_LATEST_TAG" ] && [ "$HIGHEST_TAG" = "$MULTICA_LATEST_TAG" ]; then
  echo "true"
else
  echo "false"
fi

