#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/../../bin/libs/_common.sh

# Constants
SKUBA_TF_DIR=${SKUBA_TF_DIR:-~/github/caasp/skuba/ci/infra/openstack}
KUBECONFIG=${KUBECONFIG:~/.kube/config}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}

function install_prerequites() {
  sudo zypper in $ZYPPER_INSTALL_OPTS mozilla-nss-tools jq

  [[ ! -f auth ]] || htpasswd -bc auth admin admin
}

function build_certs() {
  mkcert -install
  mkcert monitoring.example.com prometheus.example.com prometheus-alertmanager.example.com grafana.example.com

  mv monitoring.example.com*key.pem monitoring.key
  mv monitoring.example.com*.pem monitoring.crt

  ip=$(cd "$SKUBA_TF_DIR" && terraform output -json | jq -r ".ip_masters.value[0]")
  echo "$ip  prometheus.example.com prometheus-alertmanager.example.com grafana.example.com" | sudo tee -a /etc/hosts
}

function install_hostpath_provisioner() {
  helm repo add rimusz "https://charts.rimusz.net"
  helm upgrade --install hostpath-provisioner --namespace kube-system rimusz/hostpath-provisioner
}

function install_nginx_ingress() {
  helm upgrade --install nginx-ingress stable/nginx-ingress \
    --namespace monitoring \
    --values manifests/nginx-ingress-config-values.yaml
}

function install_prometheus() {
  kubectl create -n monitoring secret tls monitoring-tls \
    --key ./monitoring.key \
    --cert ./monitoring.crt

  kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=auth

  ip=$(cd "$SKUBA_TF_DIR" && terraform output -json | jq -r ".ip_masters.value[0]")
  ssh -i "$SSH_KEY" sles@"$ip" "cd /etc/kubernetes && \\
    sudo kubectl --kubeconfig=admin.conf -n monitoring create secret generic etcd-certs \\
      --from-file=/etc/kubernetes/pki/etcd/ca.crt \\
      --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt \\
      --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key"

  helm upgrade --install prometheus stable/prometheus \
    --namespace monitoring \
    --values manifests/prometheus-config-values.yaml
}

function install_grafana() {
  helm upgrade --install grafana stable/grafana \
    --namespace monitoring \
    --values manifests/grafana-config-values.yaml

  kubectl create -f manifests/grafana-datasources.yaml

  pushd /tmp
  [[ -d caasp-monitoring ]] || git clone https://github.com/SUSE/caasp-monitoring
  kubectl apply -f caasp-monitoring/
  popd
}

function show_etcd_scrapconfig() {
  kubectl get pods -n kube-system -l component=etcd -o wide

  cat <<EOF
kubectl edit -n monitoring configmap prometheus-server

scrape_configs:
  - job_name: etcd
    static_configs:
    - targets: ['<etcd server IP>:2379']
    scheme: https
    tls_config:
      ca_file: /etc/secrets/ca.crt
      cert_file: /etc/secrets/healthcheck-client.crt
      key_file: /etc/secrets/healthcheck-client.key
EOF
}

install_prerequites
install_hostpath_provisioner

build_certs
install_nginx_ingress
install_prometheus
install_grafana
