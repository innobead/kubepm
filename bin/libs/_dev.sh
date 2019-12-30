#!/usr/bin/env bash

set -o errexit

# Import libs
BIN_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1090
source "${BIN_DIR}"/libs/_common.sh

# Constants
GOFISH_VERSION=${GOFISH_VERSION:-}
GO_VERSION=${GO_VERSION:-1.13.5}
PYTHON_VERSION=${PYTHON_VERSION:-3.7.1}
RUBY_VERSION=${RUBY_VERSION:-2.6.4}
BAZEL_VERSION=${BAZEL_VERSION:-1.2.1}

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
  # shellcheck disable=SC2086
  sudo zypper in $ZYPPER_INSTALL_OPTS snapd
  sudo systemctl enable snapd
  sudo systemctl start snapd
}

function install_gofish() {
  if [[ -z $GOFISH_VERSION ]]; then
    GOFISH_VERSION=$(git_release_version fishworks/gofish)
  fi

  if ! check_cmd gofish || [[ ! "$(gofish version)" != "GOFISH_VERSION" ]]; then
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
  else
    sdk upgrade gradle
  fi

  if ! check_cmd java; then
    sdk install java
  else
    sdk upgrade java
  fi
}

function install_go() {
  # shellcheck disable=SC2076
  if ! check_cmd go || [[ ! "$(go version)" =~ "$GO_VERSION" ]]; then
    pushd /tmp
    curl -LO "https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz"
    tar -C /usr/local -xzf go*.tar.gz && rm go*.tar.gz
    popd

    cat <<EOF >>"$HOME"/.bashrc
export GOBIN=\$HOME/go/bin
export PATH=\$PATH:/usr/local/go/bin:\$GOBIN
EOF
  fi

  if ! check_cmd gore; then
    go get -u github.com/motemen/gore/cmd/gore
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
    # shellcheck disable=SC2086
    sudo zypper in $ZYPPER_INSTALL_OPTS zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel patch
    # shellcheck disable=SC2086
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

    # shellcheck disable=SC2086
    sudo zypper in $ZYPPER_INSTALL_OPTS gcc-c++ libmariadb-devel
  fi

  rbenv install "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
}

function install_bazel() {
  if [[ -z $BAZEL_VERSION ]]; then
    BAZEL_VERSION=$(git_release_version bazelbuild/bazel)
  fi

  if ! check_cmd gofish || [[ "$(bazel --version | awk '{print $2}')" != "$BAZEL_VERSION" ]]; then
    pushd /tmp

    installer=bazel-"$BAZEL_VERSION"-installer-linux-x86_64.sh
    curl -sL -O https://github.com/bazelbuild/bazel/releases/download/"$BAZEL_VERSION"/"$installer"
    chmod +x "$installer"

    sudo mkdir -p /usr/local/lib/bazel && sudo chown $USER /usr/local/lib/bazel
    ./"$installer" && rm -f "$installer"

    popd
  fi
}
