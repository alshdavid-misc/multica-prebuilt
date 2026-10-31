#!/usr/bin/env bash
set -euxo pipefail

REPO_DIR="$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"

# rm -rf "${REPO_DIR}/.pnpm-store"
rm -rf "${REPO_DIR}/go"
rm -rf "${REPO_DIR}/node"
rm -rf "${REPO_DIR}/multica-build-workspace"
rm -rf "${REPO_DIR}/dist"

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

NEEDS_PUBLISH="$(bash "${REPO_DIR}/scripts/check-published.bash")"
if [ "${NEEDS_PUBLISH}" = "false" ]; then
  echo "Prebuilt release is already up to date with multica, skipping build"
  exit 0
fi

LATEST_TAG="$(bash "${REPO_DIR}/scripts/resolve-multica-tag.bash")"
LATEST_VERSION="${LATEST_TAG#v}"

# Resolve once so the source build and the CLI download use the same release
export MULTICA_TAG="$(bash "${REPO_DIR}/scripts/resolve-multica-tag.bash")"

bash "${REPO_DIR}/scripts/download-multica-cli.bash"
bash "${REPO_DIR}/scripts/build-multica.bash"
# node "${REPO_DIR}/scripts/resolve-linkts.mts" "${REPO_DIR}/multica-build-workspace/multica-${LATEST_VERSION}/apps/web/node_modules"

bash "${REPO_DIR}/scripts/download-multica-cli.bash"

mkdir -p "${REPO_DIR}/dist/bin"
mkdir -p "${REPO_DIR}/dist/lib"
mkdir -p "${REPO_DIR}/dist/lib/multica-web"
mkdir -p "${REPO_DIR}/dist/share"

echo "${LATEST_VERSION}"

BUILD_DIR="${REPO_DIR}/multica-build-workspace/multica-${LATEST_VERSION}"

# Same contents as /app in the backend and web images
cp -a "${BUILD_DIR}/bin/multica-server" "${REPO_DIR}/dist/lib/multica-server"
cp -a "${BUILD_DIR}/bin/multica-web" "${REPO_DIR}/dist/share/multica-web"
cp "$(which node)" "${REPO_DIR}/dist/lib/multica-web"

cp "${REPO_DIR}/bins/multica-server" "${REPO_DIR}/dist/bin/multica-server"
cp "${REPO_DIR}/bins/multica-web" "${REPO_DIR}/dist/bin/multica-web"

rm -rf "${REPO_DIR}/go"
rm -rf "${REPO_DIR}/node"
rm -rf "${REPO_DIR}/.pnpm-store"
rm -rf "${REPO_DIR}/multica-build-workspace"

cd dist
tar -czf "${REPO_DIR}/multica-linux-amd64.tar.gz" ./*
cd ..

gh release delete "$LATEST_TAG" --yes --cleanup-tag 2>/dev/null || true
gh release create "$LATEST_TAG" --draft --notes "Generating"
gh release edit "$LATEST_TAG" --title "$LATEST_TAG"
gh release upload "$LATEST_TAG" "${REPO_DIR}/multica-linux-amd64.tar.gz"
gh release edit "$LATEST_TAG" --draft=false