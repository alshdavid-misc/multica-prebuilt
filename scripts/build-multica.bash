#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"

# Configuration
REPO="multica-ai/multica"
WORK_DIR="${REPO_DIR}/multica-build-workspace"

echo "==> Resolving the release tag from $REPO..."
LATEST_TAG="$(bash "${REPO_DIR}/scripts/resolve-multica-tag.bash")"

echo "==> Using release: $LATEST_TAG"

# Setup workspace
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

ARCHIVE_URL="https://github.com/$REPO/archive/refs/tags/$LATEST_TAG.tar.gz"
ARCHIVE_NAME="multica-${LATEST_TAG#v}.tar.gz"

echo "==> Downloading source code for $LATEST_TAG..."
curl -L -o "$ARCHIVE_NAME" "$ARCHIVE_URL"

echo "==> Extracting source code..."
tar -xzf "$ARCHIVE_NAME"

EXTRACTED_DIR="multica-${LATEST_TAG#v}"
if [ ! -d "$EXTRACTED_DIR" ]; then
  EXTRACTED_DIR=$(ls -d multica-*/ | head -n 1)
fi

cd "$EXTRACTED_DIR"
echo "==> Switched to source directory: $(pwd)"

# Create a common bin directory for output artifacts
mkdir -p bin

# -----------------------------------------------------------------------------
# 1. Build the Go Backend Server
# -----------------------------------------------------------------------------
echo "==> Building the Go backend server..."
if command -v go &> /dev/null; then
  # Mirrors Dockerfile: the same binaries and flags as the backend image
  VERSION="$LATEST_TAG"
  COMMIT="unknown"
  DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rm -rf bin/multica-server
  mkdir -p bin/multica-server
  cd server
  CGO_ENABLED=0 go build -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT}" -o ../bin/multica-server/server ./cmd/server
  CGO_ENABLED=0 go build -ldflags "-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}" -o ../bin/multica-server/multica ./cmd/multica
  CGO_ENABLED=0 go build -ldflags "-s -w" -o ../bin/multica-server/migrate ./cmd/migrate
  CGO_ENABLED=0 go build -ldflags "-s -w" -o ../bin/multica-server/maintenance ./cmd/maintenance
  CGO_ENABLED=0 go build -ldflags "-s -w" -o ../bin/multica-server/backfill_task_usage_hourly ./cmd/backfill_task_usage_hourly
  CGO_ENABLED=0 go build -ldflags "-s -w" -o ../bin/multica-server/backfill_codex_usage_cache ./cmd/backfill_codex_usage_cache
  cd ..
  cp -r server/migrations bin/multica-server/migrations
  cp LICENSE NOTICE bin/multica-server/
  echo "SUCCESS: Server binaries compiled at $(pwd)/bin/multica-server"
else
  echo "WARNING: 'go' is not installed. Skipping server build." >&2
fi

# -----------------------------------------------------------------------------
# 2. Build the Next.js Web App (Using pnpm workspaces)
# -----------------------------------------------------------------------------
echo "==> Preparing pnpm for monorepo build..."
if ! command -v pnpm &> /dev/null; then
  if command -v corepack &> /dev/null; then
    corepack enable
  else
    npm install -g pnpm
  fi
fi

echo "==> Installing monorepo dependencies using pnpm..."
pnpm install --frozen-lockfile

echo "==> Building the web app package (apps/web)..."
# Standalone output bundles a minimal server.js with traced node_modules
NEXT_PUBLIC_APP_VERSION="$LATEST_TAG" STANDALONE=true pnpm --filter @multica/web build

# Mirrors Dockerfile.web: standalone tree, plus static and public which
# standalone output does not include
rm -rf bin/multica-web
mkdir -p bin/multica-web/apps/web/.next
cp -a apps/web/.next/standalone/. bin/multica-web/
cp -a apps/web/.next/static bin/multica-web/apps/web/.next/static
cp -a apps/web/public bin/multica-web/apps/web/public
cp LICENSE NOTICE bin/multica-web/
