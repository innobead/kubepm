#!/usr/bin/env bash

# Import libs
CRT_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${CRT_DIR}"/../bin/libs/_common.sh

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

SKUBA_VERSION=${SKUBA_VERSION:-}
SKUBA_MODE=${SKUBA_MODE:-} # release, staging, `empty`

WORKDING_DIR=${WORKDING_DIR:-$(pwd)/_caasp}
INFRA=${INFRA:-libvirt}
CLUSTER_NAME=${CLUSTER_NAME:-testing}

SUSE_REG_CODE=${SUSE_REG_CODE:-}
MASTER_COUNT=${MASTER_COUNT:-1}
WORKER_COUNT=${MASTER_COUNT:-1}
IMAGE_URI=${IMAGE_URI:-}
SSH_KEY=${SSH_KEY:-$HOME/.ssh/id_rsa.pub}

mkdir -p "$WORKDING_DIR" || true

# git clone skuba by release or master version
if [[ -z $SKUBA_VERSION ]]; then
  SKUBA_VERSION=$(git_release_version SUSE/skuba)
fi

pushd /tmp
if ! check_cmd skuba || [[ ! "$(skuba version)" =~ "$SKUBA_VERSION" ]]; then
  rm -rf skuba* &&
    curl -fsSL "https://github.com/SUSE/skuba/archive/$SKUBA_VERSION.tar.gz" -o skuba.tar.gz &&
    mkdir skuba &&
    tar zxvf skuba.tar.gz --strip-components=1 -C skuba

  pushd skuba
  cmd="make install"
  if [[ -n $SKUBA_MODE ]]; then
    cmd="make $SKUBA_MODE"
  elif [[ -n $SUSE_REG_CODE ]]; then
    SKUBA_MODE=release
    cmd="make release"
  fi
  $cmd

  # shellcheck disable=SC2086
  cp -rf ci/infra/$INFRA "$WORKDING_DIR"

  popd
  rm -rf skuba*
fi
popd

# terraform apply
cd "$WORKDING_DIR/$INFRA"

cp terraform.tfvars.json.ci.example terraform.tfvars.json
# shellcheck disable=SC2002
updated_vars_json=$(cat terraform.tfvars.json | jq ". | .masters=$MASTER_COUNT | .workers=$WORKER_COUNT | .authorized_keys=[\"$SSH_KEY\"] | .image_uri=\"$IMAGE_URI\"")

if [[ -n $SUSE_REG_CODE ]]; then
  updated_vars_json=$(echo "$updated_vars_json" | jq ". | .repositories={} | .lb_repositories={}")
  sed -i -E "s/#caasp_registry_code = .*/caasp_registry_code = \"$SUSE_REG_CODE\"/" registration.auto.tfvars
fi

echo "$updated_vars_json" > terraform.tfvars.json

terraform init
terraform plan
terraform apply -auto-approve

# get ips from terraform output
mapfile -t ips < <(terraform output -json | jq -r '.[].value[]')

lb_ip=${ips[0]}
master_ips=${ips[1:$MASTER_COUNT]}
worker_ips=${ips[1:$WORKER_COUNT]}

# deploy by sequences
# shellcheck disable=SC2086
skuba cluster init $CLUSTER_NAME --control-plane "$lb_ip" -v 5

skuba node bootstrap master -s -u sles -t "${master_ips[0]}" -v 5
for i in ${master_ips[1:]}; do
  # shellcheck disable=SC2086
  skuba node join master$i -r master -s -u sles -t $i"" -v 5
done

for i in ${worker_ips[1:]}; do
  # shellcheck disable=SC2086
  skuba node join worker$i -r worker -s -u sles -t $i"" -v 5
done