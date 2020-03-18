#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

PWD=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
CONTAINER_NAME=sle15-init
IMG=registry.suse.com/suse/sle15:latest
TMP_DIR=$PWD/".$(basename "${BASH_SOURCE[0]%.sh}")"
SCRIPT_NAME=setup.sh
SCRIPT=$TMP_DIR/$SCRIPT_NAME

cd "$PWD"
(rm -rf "$TMP_DIR" || true) && mkdir "$TMP_DIR"

function clean() {
  # Clean intermediate images
  none_imgs=$(docker images | grep none | awk '{print $3}')
  for i in ${none_imgs}; do
    docker rmi -f "$i"
  done
}
trap clean EXIT ERR INT TERM

ssh-keygen -b 2048 -t rsa -f "$TMP_DIR"/sshkey -q -N ""
pubkey=$(cat "$TMP_DIR"/sshkey.pub)

cat <<EOF >"$SCRIPT"
#!/usr/bin/env bash

zypper ar http://download.opensuse.org/distribution/leap/15.1/repo/oss/ oss
zypper ar http://download.opensuse.org/distribution/leap/15.1/repo/non-oss/ non-oss
zypper ar http://download.opensuse.org/update/leap/15.1/oss/ update-oss
zypper ar http://download.opensuse.org/update/leap/15.1/non-oss/ update-non-oss

zypper --gpg-auto-import-keys ref

zypper in -f -y systemd
ln -s /usr/lib/systemd/systemd /sbin/init

zypper in -f -y openssh
sed -i -E "s/#PasswordAuthentication no/PasswordAuthentication no/g" /etc/ssh/sshd_config
mkdir -p ~/.ssh/authorized_keys
echo "$pubkey" >> ~/.ssh/authorized_keys
systemctl enable sshd

echo -e "suse\nsuse" | passwd \$(whoami)

EOF
chmod +x "$SCRIPT"

docker pull $IMG

# Run an intermediate container to install systemd pkgs, then save to a new image
if docker ps -a | grep $CONTAINER_NAME; then
  docker rm -f $CONTAINER_NAME
fi

docker run --name $CONTAINER_NAME -v "$SCRIPT":/workspace/$SCRIPT_NAME $IMG /workspace/$SCRIPT_NAME
cid=$(docker ps | grep $CONTAINER_NAME | awk '{print $1}' | tr -d '\n')
docker commit "$cid" $CONTAINER_NAME:latest
docker rm -f "$cid"

# Run a priviledged container
# docker run -it --rm --name sles15-init --cap-add SYS_ADMIN --tmpfs /run --tmpfs /run/lock --tmpfs /tmp -v /sys/fs/cgroup:/sys/fs/cgroup:ro sle15-init /sbin/init