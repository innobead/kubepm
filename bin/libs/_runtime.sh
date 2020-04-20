#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

function install_docker() {
  zypper_cmd=in
  if check_cmd docker; then
    zypper_cmd=up
  fi
  sudo zypper $zypper_cmd "$KU_ZYPPER_INSTALL_OPTS" docker

  sudo pip install --upgrade docker-compose
}

function install_libvirt() {
  zypper_cmd=in
  if check_cmd virsh; then
    zypper_cmd=up
  fi

  sudo zypper $zypper_cmd "$KU_ZYPPER_INSTALL_OPTS" -t pattern kvm_server kvm_tools

  virt-host-validate qemu
}

function install_virtualbox() {
  zypper_cmd=in
  if check_cmd virtualbox; then
    zypper_cmd=up
  fi

  sudo zypper $zypper_cmd "$KU_ZYPPER_INSTALL_OPTS" virtualbox
}

# https://github.com/vagrant-libvirt/vagrant-libvirt#installation
function install_vagrant() {
  pkgs=(
    qemu
    libvirt
    libvirt-devel
    ruby-devel
    gcc
    qemu-kvm
  )
  zypper_pkg_install "${pkgs[@]}"

  repo_path=hashicorp/vagrant \
    version="2.2.7" \
    download_url="https://releases.hashicorp.com/vagrant/{VERSION}/vagrant_{VERSION}_linux_amd64.zip" \
    exec_name=vagrant \
    exec_version_cmd="version" \
    install_github_pkg

  # v$(vagrant version | head -n 1 | awk '{print $3}')

  curl -sSfLO https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_linux_amd64.zip

  CONFIGURE_ARGS="with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib" vagrant plugin install vagrant-libvirt
}

function install_lxc() {
  cmd=install
  if check_cmd lxd; then
    cmd=refresh
  fi
  sudo snap "$cmd" --classic lxd

  sudo usermod -a -G lxd "${KU_USER}"
  sudo systemctl start snap.lxd.daemon.service
  sudo systemctl enable snap.lxd.daemon.service

  # when running `lxc list image images:` and encoutering a url unresolved issue, please reload snap.lxd.deamon. It's because network ready after snap for some reason.
  # sudo systemctl reload snap.lxd.daemon

  cat <<EOF
Use $(lxc help) to learn how to manage container and images.

lxc init: Please relogin to take effect all installation, then execute below commands.

  cat >lxd.yaml <<\EOF
config: {}
networks:
- config:
    ipv4.address: 172.22.0.1/16
    ipv4.nat: "true"
    ipv6.address: auto
  description: ""
  managed: false
  name: lxdbr0
  type: ""
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
cluster: null
\EOF

  cat lxd.yaml | lxd init --preseed - && rm lxd.yaml

Commands:
  lxc list image images:
  lxc launch images:opensuse/tumbleweed/amd64 opensuse
  lxc exec opensuse -- passwd root
  lxc config set opensuse limits.memory 1GB
  lxc exec opensuse -- free -h
  lxc delete opensuse --force
EOF
}

function install_podman() {
  if ! check_cmd podman; then
    sudo zypper in "$KU_ZYPPER_INSTALL_OPTS" podman
  else
    sudo zypper up "$KU_ZYPPER_INSTALL_OPTS" podman
  fi

  if ! in_container; then
    sudo systemctl enable snapd
    sudo systemctl start snapd
  fi
}
