#!/usr/bin/env bash
# https://rook.github.io/docs/rook/master/ceph-quickstart.html#deploy-the-rook-operator

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${DIR}"/../../bin/libs/_init.sh
# shellcheck disable=SC2164
cd "$DIR"

version=$(git_release_version vmware-tanzu/sonobuoy)

if ! command -v sonobuoy || [[ "$(sonobuoy version --short)" != "$version" ]]; then
  pushd /tmp

  curl -sSfL "https://github.com/vmware-tanzu/sonobuoy/releases/download/${version}/sonobuoy_${version:1}_linux_amd64.tar.gz" -o sonobuoy.tar.gz
  mkdir sonobuoy && tar zxvf sonobuoy.tar.gz -C sonobuoy
  install sonobuoy/sonobuoy "$INSTALL_BIN" && rm -rf sonobuoy*

  popd
fi

cat << EOF
sonobuoy run --wait
results=\$(sonobuoy retrieve)
sonobuoy results \$results
sonobuoy delete --wait

sonobuoy status
sonobuoy logs
EOF