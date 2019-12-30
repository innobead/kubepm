# k8s-utils

This is a project about setting up K8s development, runtime and solution environment.

## Prerequisites

Right now, this repo only supports openSUSE LEAP and Tumbleweed.

## Common Development
```
./bin/setup-dev.sh [sdkman|bazel|snap|gofish|go|gradle|python|...]
```

## Kubernetes Development
```
./bin/setup-k8s-tools.sh [kind|minikube|helm|kubectl|...]
```

## Runtime
```
./bin/setup-dev.sh [docker|libvirt|virtualbox|vargrant|...]
```

## Tools
```
./bin/setup-dev.sh [terraform|cri_tools|cert_tools|salt|...]
```
