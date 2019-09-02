#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

TF_DIR=${TF_DIR:-~/github/caasp/skuba/ci/infra/openstack}
WORKING_DIR=${WORKING_DIR:-~/v4test/test-cluster}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}

TMP_DIR=tmp

export KUBECONFIG="$WORKING_DIR"/admin.conf

function install_prerequites() {
  sudo zypper install -y mozilla-nss-tools jq

  mkdir -p "$TMP_DIR"

  [[ ! -f auth ]] || htpasswd -bc auth admin admin

  pushd $TMP_DIR
  if [[ ! -x "$(command -v mkcert)" ]]; then
    curl -L -o mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.0/mkcert-v1.4.0-linux-amd64 &&
      chmod +x mkcert &&
      cp mkcert /usr/local/bin/
  fi

  if [[ ! -x "$(command -v helm)" ]]; then
    curl -LO https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz &&
      tar -zxvf helm-*.tar.gz --strip-components 1 &&
      chmod +x helm &&
      cp helm /usr/local/bin/
  fi

  if [[ ! -x "$(command -v kubectl)" ]]; then
    curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"/bin/linux/amd64/kubectl &&
      chmod +x kubectl && cp kubectl /usr/local/bin/
  fi
  popd
}

function build_certs() {
  mkcert -install
  mkcert monitoring.example.com prometheus.example.com prometheus-alertmanager.example.com grafana.example.com

  mv monitoring.example.com*key.pem monitoring.key
  mv monitoring.example.com*.pem monitoring.crt

  ip=$(cd "$TF_DIR" && terraform output -json | jq -r ".ip_masters.value[0]")
  echo "$ip  prometheus.example.com prometheus-alertmanager.example.com grafana.example.com" | sudo tee -a /etc/hosts
}

function install_helm() {
  kubectl apply -f tiller-rbac.yaml
  helm init --service-account tiller
}

function install_hostpath_provisioner() {
  helm repo add rimusz https://charts.rimusz.net
  helm upgrade --install hostpath-provisioner --namespace kube-system rimusz/hostpath-provisioner
}

function install_nginx_ingress() {
  helm upgrade --install nginx-ingress stable/nginx-ingress \
    --namespace monitoring \
    --values nginx-ingress-config-values.yaml
}

function install_prometheus() {
  kubectl create -n monitoring secret tls monitoring-tls \
    --key ./monitoring.key \
    --cert ./monitoring.crt

  kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=auth

  ip=$(cd "$TF_DIR" && terraform output -json | jq -r ".ip_masters.value[0]")
  ssh -i "$SSH_KEY" sles@"$ip" "cd /etc/kubernetes && \\
    sudo kubectl --kubeconfig=admin.conf -n monitoring create secret generic etcd-certs \\
      --from-file=/etc/kubernetes/pki/etcd/ca.crt \\
      --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt \\
      --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key"

  helm upgrade --install prometheus stable/prometheus \
    --namespace monitoring \
    --values prometheus-config-values.yaml
}

function install_grafana() {
  helm upgrade --install grafana stable/grafana \
    --namespace monitoring \
    --values grafana-config-values.yaml

  kubectl create -f grafana-datasources.yaml

  pushd $TMP_DIR
  [[ -d caasp-monitoring ]] || git clone https://github.com/SUSE/caasp-monitoring
  kubectl apply -f caasp-monitoring/
  popd
}

function show_etcd_scrapconfig() {
  kubectl get pods -n kube-system -l component=etcd -o wide

  cat << EOF
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

function cleanup() {
  kubectl delete namespace monitoring || true

  charts="hostpath-provisioner nginx-ingress prometheus grafana"
  for c in $charts; do
    helm del --purge "$c" || true
  done

  rm -rf $TMP_DIR
}

cleanup

install_prerequites
install_helm
install_hostpath_provisioner

build_certs
install_nginx_ingress
install_prometheus
install_grafana
