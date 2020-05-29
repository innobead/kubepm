#!/usr/bin/env bash

set -o errexit

# Import libs
LIB_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
# shellcheck disable=SC1090
source "${LIB_DIR}"/_init.sh

# Constants
GOFISH_VERSION=${GOFISH_VERSION:-}
GO_VERSION=${GO_VERSION:-go1.14}
PYTHON_VERSION=${PYTHON_VERSION:-3.7.1}
RUBY_VERSION=${RUBY_VERSION:-2.6.4}
BAZEL_VERSION=${BAZEL_VERSION:-}

function install_sdkman() {
  if ! check_cmd sdk; then
    curl -sSfL "https://get.sdkman.io" | bash
  fi

  # shellcheck disable=SC1090
  source "$HOME/.sdkman/bin/sdkman-init.sh"
}

function install_snap() {
  if ! check_cmd snap; then
    sudo zypper in "$KU_ZYPPER_INSTALL_OPTS" snapd
  else
    sudo zypper up "$KU_ZYPPER_INSTALL_OPTS" snapd
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
    curl -sSfL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
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
  if [[ -z "$GO_VERSION" ]]; then
    # ISSUE: can't get the latest version from github, only golang/go has this problem
    GO_VERSION=$(git_release_version golang/go)
  fi

  # shellcheck disable=SC2076
  if ! check_cmd go || [[ ! "$(go version)" =~ "$GO_VERSION" ]]; then
    curl -sSfLO "https://dl.google.com/go/$GO_VERSION.linux-amd64.tar.gz"
    tar -C /usr/local -xzf go*.tar.gz && rm go*.tar.gz
    cat <<EOF >>"$HOME"/.bashrc
export GOBIN=\$HOME/go/bin
export PATH=\$PATH:/usr/local/go/bin:\$GOBIN
EOF
  fi

  install_go_dev_tools
}

function install_go_dev_tools() {
  # install golang tools
  go get -u \
    golang.org/x/tools/... \
    golang.org/x/lint/golint

  # install golangci-lint
  repo_path=golangci/golangci-lint \
    download_url="https://github.com/golangci/golangci-lint/releases/download/v{VERSION}/golangci-lint-{VERSION}-linux-amd64.tar.gz" \
    exec_name=golangci-lint \
    exec_version_cmd="--version" \
    install_github_pkg

  # install Go REPL
  if ! check_cmd gore; then
    go get -u github.com/motemen/gore/cmd/gore
  fi
}

function install_python() {
  if ! check_cmd pyenv; then
    curl -sSfL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

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

    curl -sSfL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash

    # shellcheck disable=SC2086
    sudo zypper in $KU_ZYPPER_INSTALL_OPTS gcc-c++ libmariadb-devel
  fi

  rbenv install "$RUBY_VERSION"
  rbenv global "$RUBY_VERSION"
}

function install_bazel() {
  sudo mkdir -p /usr/local/lib/bazel || true
  sudo chown "$KU_USER" /usr/local/lib/bazel

  repo_path=bazelbuild/bazel \
    version="$PROTOC_VERSION" \
    download_url="{VERSION}/bazel-{VERSION}-installer-linux-x86_64.sh" \
    exec_name=protoc \
    exec_version_cmd="--version" \
    install_github_pkg
}

function install_rust() {
  if ! check_cmd rustup; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  else
    rustup self update
    rustup update

    # shellcheck disable=SC1090
    source "$HOME"/.cargo/env
    rustc --version
  fi
}

function install_protobuf() {
  repo_path=protocolbuffers/protobuf \
    version="$PROTOC_VERSION" \
    download_url="v{VERSION}/protoc-{VERSION}-linux-x86_64.zip" \
    exec_name=protoc \
    exec_version_cmd="--version" \
    install_github_pkg

  go get -u github.com/golang/protobuf/protoc-gen-go
}

function install_jwt() {
  go install github.com/dgrijalva/jwt-go/cmd/jwt
}

function install_hub() {
  # shellcheck disable=SC2153
  repo_path=github/hub \
    version="$HUB_VERSION" \
    download_url="v{VERSION}/hub-linux-amd64-{VERSION}.tgz" \
    exec_name=hub \
    exec_version_cmd="version" \
    install_cmd="install" \
    install_github_pkg
}

function install_bcrypt() {
  go get -u github.com/bitnami/bcrypt-cli
}

function install_direnv() {
  repo_path=direnv/direnv \
    download_url="v{VERSION}/direnv.linux-amd64" \
    exec_name=direnv \
    exec_version_cmd="version" \
    install_github_pkg
}

function install_gimme() {
  pushd "$KU_TMP_DIR"

  curl -sSfLO https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
  chmod +x gimme && sudo mv gimme "$KU_INSTALL_BIN"

  popd
}
