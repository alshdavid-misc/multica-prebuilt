#!/usr/bin/env bash
set -e

REPO_DIR="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
echo $REPO_DIR

rm -rf "$REPO_DIR/go"

ARCH="$ARCH"
if [ "$ARCH" = "" ]; then
  case "$(uname -m)" in
    x86_64 | x86-64 | x64 | amd64) ARCH="amd64";;
    aarch64 | arm64) ARCH="arm64";;
    *) ARCH="";;
  esac
fi

OS="$OS"
if [ "$OS" = "" ]; then
  case "$(uname -s)" in
    Darwin) OS="macos";;
    Linux) OS="linux";;
    MINGW64_NT* | Windows_NT | MSYS_NT*) OS="windows";;
    *) OS="";;
  esac
fi

echo ARCH: $ARCH
echo OS:   $OS

LATEST_GO="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n 1)"
LATEST_GO="${LATEST_GO#go}" 

URL=""
case "${OS}_${ARCH}" in
  linux_amd64) URL="https://go.dev/dl/go${LATEST_GO}.linux-amd64.tar.gz";;
  linux_arm64) URL="https://go.dev/dl/go${LATEST_GO}.linux-arm64.tar.gz";;
  macos_arm64) URL="https://go.dev/dl/go${LATEST_GO}.darwin-arm64.tar.gz";;
  windows_amd64) URL="https://go.dev/dl/go${LATEST_GO}.windows-amd64.zip";;
  *) URL="";;
esac

if [ "${URL}" = "" ]; then
  echo "Unable to find URL"
  exit 1
fi

echo OS:   $URL

if [ -d "$REPO_DIR/go" ]; then
  rm -rf "$REPO_DIR/go"
fi

# Archives contain a top level "go" directory
# If zip file
if [[ "$URL" == *.zip ]]; then
  curl -fsSL -o "$REPO_DIR/go.zip" "$URL"
  unzip -q "$REPO_DIR/go.zip" -d "$REPO_DIR"
  rm -f "$REPO_DIR/go.zip"
fi

# if tar file
if [[ "$URL" == *.tar.gz ]]; then
  curl -fsSL -o "$REPO_DIR/go.tar.gz" "$URL"
  tar -xzf "$REPO_DIR/go.tar.gz" -C "$REPO_DIR"
  rm -f "$REPO_DIR/go.tar.gz"
fi
