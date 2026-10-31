#!/usr/bin/sh
set -e

ARCH=""
case "$(uname -m)" in
  x86_64 | x86-64 | x64 | amd64) ARCH="amd64";;
  aarch64 | arm64) ARCH="arm64";;
  *) ARCH="";;
esac

OS=""
case "$(uname -s)" in
  Darwin) OS="macos";;
  Linux) OS="linux";;
  MINGW64_NT* | Windows_NT | MSYS_NT*) OS="windows";;
  *) OS="";;
esac

>&2 echo ARCH: $ARCH
>&2 echo OS: $OS

export OS_ARCH="${OS}-${ARCH}"
echo "export OS_ARCH=\"${OS_ARCH}\""

if ! [ "$GITHUB_ENV" = "" ]; then
  echo "OS_ARCH=${OS_ARCH}" >> $GITHUB_ENV
fi
