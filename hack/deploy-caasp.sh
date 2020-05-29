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

WORKDING_DIR=${WORKDING_DIR:-$(pwd)/.caasp}
INFRA=${INFRA:-libvirt}
CLUSTER_NAME=${CLUSTER_NAME:-testing}

SUSE_REG_CODE=${SUSE_REG_CODE:-}
MASTER_COUNT=${MASTER_COUNT:-1}
WORKER_COUNT=${MASTER_COUNT:-1}

IMAGE_DOWNLOAD_URI="https://download.suse.de/install/SLE-15-SP1-JeOS-QU2/SLES15-SP1-JeOS.x86_64-15.1-OpenStack-Cloud-QU2.qcow2"
IMAGE_NAME=${IMAGE_DOWNLOAD_URI##*/}
IMAGE_URI=${IMAGE_URI:-/opt/images/$IMAGE_NAME}

SSH_KEY=${SSH_KEY:-$HOME/.ssh/id_rsa.pub}

function libvirt() {
  if [[ ! -f "$IMAGE_URI" ]]; then
    curl -sSfLO $IMAGE_DOWNLOAD_URI && mv $IMAGE_NAME "$IMAGE_URI"
  fi

  cp terraform.tfvars.json.ci.example terraform.tfvars.json
  # shellcheck disable=SC2002
  updated_vars_json=$(cat terraform.tfvars.json | jq ". | .masters=$MASTER_COUNT | .workers=$WORKER_COUNT | .authorized_keys=[\"$(cat "$SSH_KEY")\"] | .image_uri=\"$IMAGE_URI\"")

  if [[ -n $SUSE_REG_CODE ]]; then
    updated_vars_json=$(echo "$updated_vars_json" | jq ". | .repositories={} | .lb_repositories={}")
    sed -i -E "s/#caasp_registry_code = .*/caasp_registry_code = \"$SUSE_REG_CODE\"/" registration.auto.tfvars
  fi

  echo "$updated_vars_json" >terraform.tfvars.json
}

# pre-flight checking
mkdir -p "$WORKDING_DIR" || true

# git clone skuba by release or master version
if [[ -z $SKUBA_VERSION ]]; then
  SKUBA_VERSION=$(git_release_version SUSE/skuba)
fi

# shellcheck disable=SC2076
if ! check_cmd skuba || [[ ! "$(skuba version)" =~ "$SKUBA_VERSION" ]]; then
  rm -rf skuba* &&
    curl -fsSL "https://github.com/SUSE/skuba/archive/$SKUBA_VERSION.tar.gz" -o skuba.tar.gz &&
    mkdir skuba &&
    tar zxvf skuba.tar.gz --strip-components=1 -C skuba

  pushd skuba
  cmd="git init; "
  if [[ -n $SKUBA_MODE ]]; then
    cmd+="make $SKUBA_MODE"
  elif [[ -n $SUSE_REG_CODE ]]; then
    SKUBA_MODE=release
    cmd+="make release"
  else
    cmd+="make install"
  fi
  eval "$cmd"

  # shellcheck disable=SC2086
  cp -rf ci/infra/$INFRA "$WORKDING_DIR"

  popd
  rm -rf skuba*
fi

cd "$WORKDING_DIR/$INFRA"
mkdir -p "$(dirname "$IMAGE_URI")" || true

# create infra
$INFRA

terraform init
terraform plan
terraform apply -auto-approve

# get ips from terraform output
mapfile -t ips < <(terraform output -json | jq -r '.[].value[]')

for i in "${ips[@]}"; do
  # shellcheck disable=SC2086
  ssh-keygen -R $i -f "$HOME/.ssh/known_hosts"
done

lb_ip=${ips[0]}
master_ips=("${ips[@]:1:$MASTER_COUNT}")
worker_ips=("${ips[@]:$((1 + MASTER_COUNT)):$WORKER_COUNT}")

# deploy CaaSP by node sequences
if [[ ! -d "$CLUSTER_NAME" ]]; then
  skuba cluster init "$CLUSTER_NAME" --control-plane "$lb_ip" -v 5 | tee console.log
fi
cd "$CLUSTER_NAME"

skuba node bootstrap master -s -u sles -t "${master_ips[0]}" -v 5 | tee -a console.log
for i in "${master_ips[@]:1}"; do
  # shellcheck disable=SC2086
  skuba node join master$i -r master -s -u sles -t $i"" -v 5 | tee -a console.log
done

for i in "${worker_ips[@]}"; do
  # shellcheck disable=SC2086
  skuba node join worker$i -r worker -s -u sles -t $i"" -v 5 | tee -a console.log
done
