#!/usr/bin/env bash
set -euo pipefail

# Rootless podman maps container root to the current user, so files written
# to the mount are owned by the invoking user on the host
podman run \
  --rm \
  -it \
  --userns=keep-id:uid=0,gid=0 \
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
