#!/usr/bin/env bash

BIN_DIR=$(dirname `realpath $0`)

source "${BIN_DIR}"/_common.sh

echo "
Prerequisites:
- OpenSUSE Leap 15
"
echo "# Installing development tools"

echo "## Installing go"
check_cmd go
if [[ $? -ne 0 ]]; then
    curl -LO https://dl.google.com/go/go1.11.5.linux-amd64.tar.gz
    tar -C /usr/local -xzf go*.tar.gz && rm go*.tar.gz

    echo 'export GOPATH="$HOME/go"' >> $HOME/.bashrc
    echo 'export GOBIN="$HOME/go/bin"' >> $HOME/.bashrc
    echo 'export PATH="$PATH:/usr/local/go/bin:$GOBIN"' >> $HOME/.bashrc
fi

echo "## Installing terraform"
check_cmd terraform
if [[ $? -ne 0 ]]; then
    curl -OL https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
    unzip terraform*.zip && rm terraform*.zip
    chmod +x terraform && sudo mv terraform /usr/local/bin
fi

echo "## Installing terraform-provider-libvirt"
check_cmd ~/.terraform.d/plugins/terraform-provider-libvirt
if [[ $? -ne 0 ]]; then
    curl -LO https://github.com/dmacvicar/terraform-provider-libvirt/releases/download/v0.5.1/terraform-provider-libvirt-0.5.1.openSUSE_Leap_15.0.x86_64.tar.gz
    tar -zxvf terraform-provider-libvirt*.tar.gz && rm terraform-provider-libvirt*.tar.gz

    mkdir -p ~/.terraform.d/plugins
    mv terraform-provider-libvirt ~/.terraform.d/plugins
fi

echo "## Installing docker"
check_cmd docker
if [[ $? -ne 0 ]]; then
    sudo zypper ar --refresh opensuse_factory_oss http://download.opensuse.org/tumbleweed/repo/oss/
    sudo zypper install -y docker
    sudo zypper mr -d opensuse_factory_oss
fi

echo "## Installing docker-compose"
check_cmd docker-compose
if [[ $? -ne 0 ]]; then
    sudo pip install docker-compose
fi

echo "## Installing libvirtd"
check_cmd virsh
if [[ $? -ne 0 ]]; then
    sudo zypper install -y -t pattern kvm_server kvm_tools
fi