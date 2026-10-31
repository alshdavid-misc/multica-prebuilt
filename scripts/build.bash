#!/usr/bin/env bash
set -euo pipefail

# Configuration
REPO="multica-ai/multica"
WORK_DIR="./multica-build-workspace"

echo "==> Fetching the latest release tag from $REPO..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  echo "Error: Could not fetch the latest release tag." >&2
  exit 1
fi

echo "==> Latest release found: $LATEST_TAG"

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
  cd server
  go build -o ../bin/multica-server ./cmd/server
  cd ..
  echo "SUCCESS: Server binary compiled at $(pwd)/bin/multica-server"
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
pnpm install

echo "==> Building the web app package (apps/web)..."
pnpm --filter web build

echo "-----------------------------------------------------------------------------"
echo "Build procedure completed for Multica version: $LATEST_TAG"
echo "Server Binary : $(pwd)/bin/multica-server"
echo "Web App Build : $(pwd)/apps/web/.next"
echo "-----------------------------------------------------------------------------"
