# k8s-utils

This is a project about setting up K8s development, runtime and solution environment.

## Prerequisites

Right now, this repo only supports openSUSE LEAP and Tumbleweed.

## Common Development
```
./bin/install-dev.sh [sdkman|bazel|snap|gofish|go|gradle|python|...]
```

## Kubernetes Development
```
./bin/install-k8s-tools.sh [kind|minikube|helm|kubectl|...]
```

## Runtime
```
./bin/install-dev.sh [docker|libvirt|virtualbox|vargrant|...]
```

## Tools
```
./bin/install-dev.sh [terraform|cri_tools|cert_tools|salt|...]
```
