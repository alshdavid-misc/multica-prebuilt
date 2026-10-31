#!/usr/bin/env bash
set -euxo pipefail

REPO_DIR="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git libatomic1

bash "${REPO_DIR}/scripts/download-go.bash"
export PATH="${REPO_DIR}/go/bin:$PATH"

bash "${REPO_DIR}/scripts/download-node.bash"
export PATH="${REPO_DIR}/node/bin:$PATH"
export PATH="${REPO_DIR}/node:$PATH"

ls -la "${REPO_DIR}"
ls -la "${REPO_DIR}/go"
ls -la "${REPO_DIR}/node"

which go
go version

which node
node --version

bash "${REPO_DIR}/scripts/build-multica.bash"

rm -rf "${REPO_DIR}/go"
rm -rf "${REPO_DIR}/node"
