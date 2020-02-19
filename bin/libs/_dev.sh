#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

# Constants
GOFISH_VERSION=${GOFISH_VERSION:-}
GO_VERSION=${GO_VERSION:-}
PYTHON_VERSION=${PYTHON_VERSION:-3.7.1}
RUBY_VERSION=${RUBY_VERSION:-2.6.4}
BAZEL_VERSION=${BAZEL_VERSION:-}

function install_sdkman() {
  if ! check_cmd sdk; then
    pushd "${KU_TMP_DIR}"
    curl -sSfL "https://get.sdkman.io" | bash
    popd
  fi

  # shellcheck disable=SC1090
  source "$HOME/.sdkman/bin/sdkman-init.sh"
}

function install_snap() {
  if ! check_cmd snap; then
    sudo zypper in $KU_ZYPPER_INSTALL_OPTS snapd
  else
    sudo zypper up $KU_ZYPPER_INSTALL_OPTS snapd
  fi

  if ! in_container; then
    sudo systemctl enable snapd
    sudo systemctl start snapd
  fi
}

function install_gofish() {
  if [[ -z $GOFISH_VERSION ]]; then
    GOFISH_VERSION=$(git_release_version fishworks/gofish)
  fi

  if ! check_cmd gofish || [[ ! "$(gofish version)" != "GOFISH_VERSION" ]]; then
    pushd "${KU_TMP_DIR}"
    curl -sSfL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
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
    pushd "${KU_TMP_DIR}"
    curl -sSfLO "https://dl.google.com/go/go$GO_VERSION.linux-amd64.tar.gz"
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
    pushd "${KU_TMP_DIR}"
    curl -sSfL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    popd

    cat <<EOT >>"$HOME"/.bashrc
export PATH=\$HOME/.pyenv/bin:\$PATH
eval "\$(pyenv init -)"
EOT

    # https://github.com/pyenv/pyenv/wiki/common-build-problems
    # shellcheck disable=SC2086
    sudo zypper in $KU_ZYPPER_INSTALL_OPTS zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel patch
    # shellcheck disable=SC2086
    sudo zypper in $KU_ZYPPER_INSTALL_OPTS python3-devel python-devel
  fi

  pyenv install --skip-existing "$PYTHON_VERSION"
  pyenv global "$PYTHON_VERSION"
}

function instal_ruby() {
  if ! check_cmd rbenv; then
    cat <<EOT >>"$HOME"/.bashrc
export PATH=\$HOME/.rbenv/bin:\$PATH
eval "\$(rbenv init -)"
EOT

    pushd "${KU_TMP_DIR}"
    curl -sSfL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
    popd

    # shellcheck disable=SC2086
    sudo zypper in $KU_ZYPPER_INSTALL_OPTS gcc-c++ libmariadb-devel
  fi

  rbenv install "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
}

function install_bazel() {
  if [[ -z $BAZEL_VERSION ]]; then
    BAZEL_VERSION=$(git_release_version bazelbuild/bazel)
  fi

  if ! check_cmd bazel || [[ "$(bazel --version | awk '{print $2}')" != "$BAZEL_VERSION" ]]; then
    pushd "${KU_TMP_DIR}"

    installer=bazel-"$BAZEL_VERSION"-installer-linux-x86_64.sh
    curl -sSfL -O https://github.com/bazelbuild/bazel/releases/download/"$BAZEL_VERSION"/"$installer"
    chmod +x "$installer"

    sudo mkdir -p /usr/local/lib/bazel && sudo chown $KU_USER /usr/local/lib/bazel
    ./"$installer" && rm -f "$installer"

    popd
  fi
}

function install_rust() {
  if ! check_cmd rustup; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  else
    rustup self update
    rustup update

    source "$HOME"/.cargo/env
    rustc --version
  fi
}

function install_protobuf() {
  if [[ -z $PROTOC_VERSION ]]; then
    PROTOC_VERSION=$(git_release_version protocolbuffers/protobuf)
  fi

  install_go

  # shellcheck disable=SC2076
  if ! check_cmd protoc || [[ ! "$(protoc --version)" =~ "${PROTOC_VERSION:1}" ]]; then
    pushd "${KU_TMP_DIR}"

    installer=protoc-"${PROTOC_VERSION:1}"-linux-x86_64.zip
    curl -sSfL -O https://github.com/protocolbuffers/protobuf/releases/download/"$PROTOC_VERSION"/"$installer"
    unzip -d protoc "$installer"
    sudo install protoc/bin/protoc "$KU_INSTALL_BIN" && rm -rf protoc*

    go get -u github.com/golang/protobuf/protoc-gen-go

    popd
  fi
}

function install_jwt() {
  go install github.com/dgrijalva/jwt-go/cmd/jwt
}

function install_hub() {
  if [[ -z $HUB_VERSION ]]; then
    HUB_VERSION=$(git_release_version github/hub)
  fi

  install_go

  if ! check_cmd hub || [[ ! "$(hub version)" =~ "${HUB_VERSION}" ]]; then
    pushd "${KU_TMP_DIR}"

    curl -sSfLO "https://github.com/github/hub/releases/download/${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION:1}.tgz"
    mkdir hub &&
      tar zxvf hub*.tgz  --strip-components=1 -C hub &&
      ./hub/install &&
      rm -rf hub*

    popd
  fi
}

function install_devenv() {
  #TODO fzf, tmux, asciinema, ...
  :
}
