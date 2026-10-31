#!/usr/bin/env bash
set -e

REPO_DIR="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
echo $REPO_DIR

rm -rf "$REPO_DIR/node"

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

LATEST_VERSION="$(curl -fsSL 'https://nodejs.org/dist/index.tab' | awk -F'\t' 'NR > 1 && $10 != "-" && !found { print $1; found = 1 }')"
LATEST_VERSION="${LATEST_VERSION#v}"

URL=""
case "${OS}_${ARCH}" in
  linux_amd64) URL="https://nodejs.org/dist/v${LATEST_VERSION}/node-v${LATEST_VERSION}-linux-x64.tar.gz";;
  linux_arm64) URL="https://nodejs.org/dist/v${LATEST_VERSION}/node-v${LATEST_VERSION}-linux-arm64.tar.gz";;
  macos_arm64) URL="https://nodejs.org/dist/v${LATEST_VERSION}/node-v${LATEST_VERSION}-darwin-arm64.tar.gz";;
  windows_amd64) URL="https://nodejs.org/dist/v${LATEST_VERSION}/node-v${LATEST_VERSION}-win-x64.zip";;
  *) URL="";;
esac

if [ "${URL}" = "" ]; then
  echo "Unable to find URL"
  exit 1
fi

echo OS:   $URL

# Archives contain a top level "node-v<version>-<os>-<arch>" directory,
# strip it so the contents land directly in "node"
rm -rf "$REPO_DIR/node"
mkdir -p "$REPO_DIR/node"

# If zip file
if [[ "$URL" == *.zip ]]; then
  curl -fsSL -o "$REPO_DIR/node.zip" "$URL"
  unzip -q "$REPO_DIR/node.zip" -d "$REPO_DIR/node.tmp"
  mv "$REPO_DIR"/node.tmp/*/* "$REPO_DIR/node"
  rm -rf "$REPO_DIR/node.tmp" "$REPO_DIR/node.zip"
fi

# if tar file
if [[ "$URL" == *.tar.gz ]]; then
  curl -fsSL -o "$REPO_DIR/node.tar.gz" "$URL"
  tar -xzf "$REPO_DIR/node.tar.gz" -C "$REPO_DIR/node" --strip-components=1
  rm -f "$REPO_DIR/node.tar.gz"
fi
