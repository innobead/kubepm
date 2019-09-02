## Prerequisites
Setup your K8s cluster by Skuba

## Define the environment variables
```
TF_DIR=${TF_DIR:-~/github/caasp/skuba/ci/infra/openstack}
WORKING_DIR=${WORKING_DIR:-~/skuba-cluster}
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
```

## Deploy monitoring stack (Promehtues, Grafana and Nginx ingress)
```
./run.sh
```
