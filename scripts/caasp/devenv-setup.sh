#!/usr/bin/env bash

BIN_DIR=$(dirname "$(realpath "$0")")

# shellcheck disable=SC1090
source "${BIN_DIR}"/_common.sh

echo "
Prerequisites:
- OpenSUSE Leap 15
"
echo "# Installing development tools"

echo "## Installing go"
if ! check_cmd go; then
  curl -LO https://dl.google.com/go/go1.11.5.linux-amd64.tar.gz
  tar -C /usr/local -xzf go*.tar.gz && rm go*.tar.gz

  cat <<EOF >>"$HOME"/.bashrc
  export GOBIN=\$HOME/go/bin
  export GOBIN=\$HOME/go/bin
  export PATH=$\PATH:/usr/local/go/bin:$GOBIN
EOF
fi

echo "## Installing terraform"
if ! check_cmd terraform; then
  curl -OL https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
  unzip terraform*.zip && rm terraform*.zip
  chmod +x terraform && sudo mv terraform /usr/local/bin
fi

echo "## Installing terraform-provider-libvirt"
if ! check_cmd ~/.terraform.d/plugins/terraform-provider-libvirt; then
  curl -LO https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.5.1/terraform-provider-libvirt-0.5.1.openSUSE_Leap_15.0.x86_64.tar.gz
  tar -zxvf terraform-provider-libvirt*.tar.gz && rm terraform-provider-libvirt*.tar.gz

  mkdir -p ~/.terraform.d/plugins
  mv terraform-provider-libvirt ~/.terraform.d/plugins
fi

echo "## Installing docker"
if ! check_cmd docker; then
  sudo zypper ar --refresh opensuse_factory_oss http://download.opensuse.org/tumbleweed/repo/oss/
  sudo zypper install -y docker
  sudo zypper mr -d opensuse_factory_oss
fi

echo "## Installing docker-compose"
if ! check_cmd docker-compose; then
  sudo pip install docker-compose
fi

echo "## Installing libvirtd"
if ! check_cmd virsh; then
  sudo zypper install -y -t pattern kvm_server kvm_tools
fi
