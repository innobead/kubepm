#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

PWD=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
CONTAINER_NAME=ignite-sles15
IMG=innobead/$CONTAINER_NAME:latest
ORG_IMG=registry.suse.com/suse/sle15:latest
TMP_DIR=$PWD/".$(basename "${BASH_SOURCE[0]%.sh}")"
SCRIPT_NAME=setup.sh
SCRIPT=$TMP_DIR/$SCRIPT_NAME

function clean() {
  set +o pipefail

  # Clean intermediate images
  none_imgs=$(docker images | grep none | awk '{print $3}')
  for i in ${none_imgs}; do
    docker rmi -f "$i"
  done
}
trap clean EXIT ERR INT TERM

function help() {
  cat <<EOF
There are some limitations as below:

1. Image object Json decoding issue

  Ignite v0.6.3 can not start container with a local image. It will cause some json decoding issue in ignite, ignite-spwan and others. But the issue is already fixed in master branch.

  The workaround is to push the local built image to a remote registry, then run the container by using the pushed image.
    > sudo ignite run innobead/ignite-sles15:latest --runtime docker --cpus 1 --ssh --memory 1GB --size 2GB --log-level trace

2. Run by root

  Right now, ignite only supports under root context, but it will be fixed in the future.

  Besides running from ignite, you can also run by docker.

    > docker run -it --rm --name innobead/ignite-sles15:latest--cap-add SYS_ADMIN --tmpfs /run --tmpfs /run/lock --tmpfs /tmp -v /sys/fs/cgroup:/sys/fs/cgroup:ro ignite-sles15 /sbin/init
EOF
}

cd "$PWD"
(rm -rf "$TMP_DIR" || true) && mkdir "$TMP_DIR"

ssh-keygen -b 2048 -t rsa -f "$TMP_DIR"/sshkey -q -N ""
pubkey=$(cat "$TMP_DIR"/sshkey.pub)

cat <<EOF >"$SCRIPT"
#!/usr/bin/env bash
# github/weaveworks/ignite/images/opensuse/Dockerfile

zypper ar http://download.opensuse.org/distribution/leap/15.1/repo/oss/ oss
zypper ar http://download.opensuse.org/distribution/leap/15.1/repo/non-oss/ non-oss
zypper ar http://download.opensuse.org/update/leap/15.1/oss/ update-oss
zypper ar http://download.opensuse.org/update/leap/15.1/non-oss/ update-non-oss

zypper --gpg-auto-import-keys ref

zypper in -f -y systemd
ln -s /usr/lib/systemd/systemd /sbin/init

# ignite: Install common utilities
zypper -n install -f -y \
        iproute \
        iputils \
        openssh \
        net-tools \
        systemd-sysvinit \
        udev \
        sudo \
        wget
        e2fsprogs \
        device-mapper

sed -i -E "s/#PasswordAuthentication no/PasswordAuthentication no/g" /etc/ssh/sshd_config
mkdir -p ~/.ssh
echo "$pubkey" >> ~/.ssh/authorized_keys
systemctl enable sshd

# ignite:
echo "root:root" | chpasswd

zypper clean --all

EOF
chmod +x "$SCRIPT"

docker pull $ORG_IMG

# Run an intermediate container to install systemd pkgs, then save to a new image
docker rm -f $(docker ps -a | grep $CONTAINER_NAME | awk '{print $1}') || true

docker run --name $CONTAINER_NAME -v "$SCRIPT":/workspace/$SCRIPT_NAME $ORG_IMG /workspace/$SCRIPT_NAME
cid=$(docker ps -a | grep $CONTAINER_NAME | awk '{print $1}' | tr -d '\n')
docker commit "$cid" $IMG
docker rm -f "$cid"

help
