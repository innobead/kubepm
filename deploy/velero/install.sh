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

./uninstall.sh || true

./../../bin/setup-tools.sh velero

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
  --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000

minio_pod=$(kubectl -n velero get pod -l component=minio -o jsonpath='{.items[0].metadata.name}')
# shellcheck disable=SC2086
kubectl -n velero wait --for=condition=Ready --timeout=60s pod $minio_pod

nginx_pod=$(kubectl -n nginx-example get pods -o jsonpath='{.items[0].metadata.name}')
# shellcheck disable=SC2086
kubectl -n nginx-example annotate pod $nginx_pod backup.velero.io/backup-volumes=nginx-logs

kubectl -n velero port-forward pod/$minio_pod 9000:9000 &
kubectl -n velero patch backupstoragelocation default --type='json' -p '[{"op": "replace", "path": "/spec/config/publicUrl", "value":"http://localhost:9000"}]'
