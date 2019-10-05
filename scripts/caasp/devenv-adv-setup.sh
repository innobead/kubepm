#!/usr/bin/env bash

BIN_DIR=$(dirname "$(realpath "$0")")

# shellcheck disable=SC1090
source "${BIN_DIR}"/_common.sh

echo "
Prerequisites:
- OpenSUSE Leap 15
"

echo "# Installing development tools"

echo "## Installing SDKMAN"
if ! check_cmd sdk; then
  curl -s "https://get.sdkman.io" | bash
  # shellcheck disable=SC1090
  source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

echo "## Installing GoFish"
if ! check_cmd gofish; then
  curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
  gofish init
  gofish update
fi

echo "## Installing Gradle"
if ! check_cmd gradle; then
  sdk install gradle
fi

echo "## Installing Java"
if ! check_cmd java; then
  sdk install java
fi

echo "## Installing Python env"
if ! check_cmd pyenv; then
  curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
  cat <<EOT >>"$HOME"/.bashrc
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOT

  # https://github.com/pyenv/pyenv/wiki/common-build-problems
  sudo zypper in -y zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel patch
  sudo zypper in -y python3-devel python-devel
fi

echo "## Installing Ruby env"
if ! check_cmd rbenv; then
  cat <<EOT >>"$HOME"/.bashrc
export PATH="\$HOME/.rbenv/bin:\$PATH"
eval "\$(rbenv init -)"
EOT
  curl -sL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
  sudo zypper in -y gcc-c++ libmariadb-devel
fi
