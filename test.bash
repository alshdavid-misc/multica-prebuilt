#!/usr/bin/env bash
set -euo pipefail

docker run \
  --rm \
  -it \
  -v "${PWD}:${PWD}:Z" \
  -w "${PWD}" \
  debian:13 \
  bash -c '
    set -e
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl git
    git config --global --add safe.directory "*"
    bash build/build-linux-amd64.bash
  '
