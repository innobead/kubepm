#!/usr/bin/env bash

# Please change to the container compatible with the local host
IMG="innobead/k8s-utils:leap-15.1-latest"

docker pull "$IMG"

docker run -it \
  --user "$(id -u):$(id -g)" \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/sudoers:/etc/sudoers:ro \
  -v /etc/sudoers.d/:/etc/sudoers.d:ro \
  -v /usr/bin/zypper:/usr/bin/zypper:ro \
  -v /usr/lib:/usr/lib \
  -v /usr/lib64:/usr/lib64 \
  -v /lib:/lib \
  -v /lib64:/lib64 \
  -v /usr/bin:/usr/bin \
  -v /usr/local/bin:/usr/local/bin \
  -v /usr/local/lib:/usr/local/lib \
  -v /usr/local/lib64:/usr/local/lib64 \
  "$IMG"
