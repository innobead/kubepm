#!/usr/bin/env bash
# https://velero.io/docs/v1.2.0/contributions/minio/

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${DIR}"/../../bin/libs/_common.sh
# shellcheck disable=SC2164
cd "$DIR"

./destroy.sh || true

version=$(git_release_version vmware-tanzu/velero)
f="velero-$version-linux-amd64.tar.gz"

if ! command -v velero || [[ ! "$(velero version --client-only)" =~ $version ]]; then
  curl -sL -O "https://github.com/vmware-tanzu/velero/releases/download/$version/$f"
  mkdir velero && tar zxvf "$f" --strip-components=1 -C velero
  chmod +x velero/velero && sudo mv velero/velero /usr/local/bin/
fi

kubectl create -f manifests
kubectl create -f manifests/nginx-app/with-pv.yaml

aws_access_key_id=$(kubectl get deployment minio -n velero -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="MINIO_ACCESS_KEY")].value}')
aws_secret_access_key=$(kubectl get deployment minio -n velero -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="MINIO_SECRET_KEY")].value}')

cat <<EOF >credentials-velero
[default]
aws_access_key_id=$aws_access_key_id
aws_secret_access_key=$aws_secret_access_key
EOF

# or --no-default-backup-location w/o specifying backup & volume snappshot location
velero install \
  --use-restic \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.0.0 \
  --bucket velero \
  --secret-file ./credentials-velero \
  --use-volume-snapshots=false \
  --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000

function cleanup() {
  [[ -n "$f" ]] && rm -rf "$f"
}

signal_handle cleanup
