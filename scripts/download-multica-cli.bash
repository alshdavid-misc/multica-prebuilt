#!/usr/bin/env bash
set -e

REPO_DIR="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
echo $REPO_DIR

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

# Same release as build-multica.bash (set MULTICA_TAG to pin it)
LATEST_TAG="$(bash "${REPO_DIR}/scripts/resolve-multica-tag.bash")"
LATEST_VERSION="${LATEST_TAG#v}"

RELEASE_URL="https://github.com/multica-ai/multica/releases/download/${LATEST_TAG}"

ARCHIVE=""
case "${OS}_${ARCH}" in
  linux_amd64) ARCHIVE="multica-cli-${LATEST_VERSION}-linux-amd64.tar.gz";;
  linux_arm64) ARCHIVE="multica-cli-${LATEST_VERSION}-linux-arm64.tar.gz";;
  macos_amd64) ARCHIVE="multica-cli-${LATEST_VERSION}-darwin-amd64.tar.gz";;
  macos_arm64) ARCHIVE="multica-cli-${LATEST_VERSION}-darwin-arm64.tar.gz";;
  windows_amd64) ARCHIVE="multica-cli-${LATEST_VERSION}-windows-amd64.zip";;
  windows_arm64) ARCHIVE="multica-cli-${LATEST_VERSION}-windows-arm64.zip";;
  *) ARCHIVE="";;
esac

if [ "${ARCHIVE}" = "" ]; then
  echo "Unable to find URL"
  exit 1
fi

URL="${RELEASE_URL}/${ARCHIVE}"

echo URL:  $URL

BIN_DIR="$REPO_DIR/dist/bin"
TMP_DIR="$REPO_DIR/multica-cli.tmp"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR" "$BIN_DIR"

curl -fsSL -o "$TMP_DIR/$ARCHIVE" "$URL"
curl -fsSL -o "$TMP_DIR/checksums.txt" "${RELEASE_URL}/checksums.txt"

# Verify against the release checksums
EXPECTED="$(grep " ${ARCHIVE}\$" "$TMP_DIR/checksums.txt" | awk '{ print $1 }')"
if command -v sha256sum &> /dev/null; then
  ACTUAL="$(sha256sum "$TMP_DIR/$ARCHIVE" | awk '{ print $1 }')"
else
  ACTUAL="$(shasum -a 256 "$TMP_DIR/$ARCHIVE" | awk '{ print $1 }')"
fi

if [ "$EXPECTED" = "" ] || [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "Checksum mismatch for $ARCHIVE (expected: $EXPECTED, actual: $ACTUAL)"
  exit 1
fi

# Archives are flat (binary + LICENSE/NOTICE/README), only keep the binary
# If zip file
if [[ "$ARCHIVE" == *.zip ]]; then
  unzip -q "$TMP_DIR/$ARCHIVE" -d "$TMP_DIR/out"
  mv "$TMP_DIR/out/multica.exe" "$BIN_DIR/multica.exe"
fi

# if tar file
if [[ "$ARCHIVE" == *.tar.gz ]]; then
  mkdir -p "$TMP_DIR/out"
  tar -xzf "$TMP_DIR/$ARCHIVE" -C "$TMP_DIR/out"
  mv "$TMP_DIR/out/multica" "$BIN_DIR/multica"
fi

rm -rf "$TMP_DIR"
