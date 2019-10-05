#!/usr/bin/env bash

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

set -o errexit
#set -o nounset
set -o pipefail
set -o xtrace

# Constants
GO_VERSION=${GO_VERSION:-1.13.1}
PYTHON_VERSION=${PYTHON_VERSION:-3.7.1}
RUBY_VERSION=${RUBY_VERSION:-2.6.4}

function install_sdkman() {
  if ! check_cmd sdk; then
    pushd /tmp
    curl -s "https://get.sdkman.io" | bash
    popd
  fi

  # shellcheck disable=SC1090
  source "$HOME/.sdkman/bin/sdkman-init.sh"
}

function install_snap() {
  sudo zypper --no-gpg-checks in $ZYPPER_INSTALL_OPTS snapd
  sudo systemctl enable snapd
  sudo systemctl start snapd
}

function install_gofish() {
  if ! check_cmd gofish; then
    pushd /tmp
    curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
    popd

    gofish init
    gofish update
  fi
}

function install_gradle() {
  if ! check_cmd gradle; then
    sdk install gradle
  fi

  if ! check_cmd java; then
    sdk install java
  fi
}

function install_go() {
  if ! check_cmd go; then
    pushd /tmp
    curl -LO https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz
    tar -C /usr/local -xzf go*.tar.gz && rm go*.tar.gz
    popd

    cat <<EOF >>"$HOME"/.bashrc
export GOBIN=\$HOME/go/bin
export PATH=\$PATH:/usr/local/go/bin:\$GOBIN
EOF
  fi
}

function install_python() {
  if ! check_cmd pyenv; then
    pushd /tmp
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    popd

    cat <<EOT >>"$HOME"/.bashrc
export PATH=\$HOME/.pyenv/bin:\$PATH
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOT

    # https://github.com/pyenv/pyenv/wiki/common-build-problems
    sudo zypper in $ZYPPER_INSTALL_OPTS zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel patch
    sudo zypper in $ZYPPER_INSTALL_OPTS python3-devel python-devel

  fi

  pyenv install "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"
}

function instal_ruby() {
  if ! check_cmd rbenv; then
    cat <<EOT >>"$HOME"/.bashrc
export PATH=\$HOME/.rbenv/bin:\$PATH
eval "\$(rbenv init -)"
EOT

    pushd /tmp
    curl -sL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
    popd

    sudo zypper in $ZYPPER_INSTALL_OPTS gcc-c++ libmariadb-devel
  fi

  rbenv install "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
}

install_sdkman
install_snap
install_gofish
install_go
install_gradle
install_python
instal_ruby
