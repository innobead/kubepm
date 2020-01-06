#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${DIR}"/../../bin/libs/_common.sh
# shellcheck disable=SC2164
cd "$DIR"

./uninstall.sh || true

DOWNLOAD_URL=$(curl -Ls "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases/latest" | jq -r .tarball_url)
DOWNLOAD_VERSION=$(grep -o '[^/v]*$' <<<"$DOWNLOAD_URL")
f=metrics-server-$DOWNLOAD_VERSION

function cleanup() {
  # shellcheck disable=SC2086
  echo rm -rf /tmp/$f*
}

signal_handle cleanup

pushd /tmp
curl -sSL "$DOWNLOAD_URL" -o "$f.tar.gz"
mkdir "$f"
tar -xzf "$f.tar.gz" -C "$f" --strip-components 1

# shellcheck disable=SC2086
kubectl create namespace metric-server
sed -i -E "s/namespace: .*/namespace: metric-server/g" ./$f/deploy/1.8+/*.yaml
kubectl apply -f "$f/deploy/1.8+/"
popd
