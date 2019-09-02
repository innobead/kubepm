#!/usr/bin/env bash

BIN_DIR=$(dirname `realpath $0`)
ZSH_VERSION=

source "${BIN_DIR}"/_common.sh

echo "
Prerequisites:
- OpenSUSE Leap 15
"

echo "# Installing development tools"

echo "## Installing SDKMAN"
check_cmd sdk
if [[ $? -ne 0 ]]; then
    curl -s "https://get.sdkman.io" | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

echo "## Installing GoFish"
check_cmd gofish
if [[ $? -ne 0 ]]; then
    curl -fsSL https://raw.githubusercontent.com/fishworks/gofish/master/scripts/install.sh | bash
    gofish init
    gofish update
fi

echo "## Installing Gradle"
check_cmd gradle
if [[ $? -ne 0 ]]; then
    sdk install gradle
fi

echo "## Installing Java"
check_cmd java
if [[ $? -ne 0 ]]; then
    sdk install java
fi

echo "## Installing Python env"
check_cmd pyenv
if [[ $? -ne 0 ]]; then
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
    cat <<EOT >> $HOME/.bashrc
export PATH="\$HOME/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOT

    # https://github.com/pyenv/pyenv/wiki/common-build-problems
    sudo zypper in -y zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel patch
    sudo zypper in -y python3-devel python-devel
fi

echo "## Installing Ruby env"
check_cmd rbenv
if [[ $? -ne 0 ]]; then
    cat <<EOT >> $HOME/.bashrc
export PATH="\$HOME/.rbenv/bin:\$PATH"
eval "\$(rbenv init -)"
EOT
    curl -sL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
    sudo zypper in -y gcc-c++ libmariadb-devel
fi

echo "## Installing chromedriver"
check_cmd chromedriver
if [[ $? -ne 0 ]]; then
    curl -OL https://chromedriver.storage.googleapis.com/73.0.3683.20/chromedriver_linux64.zip
    unzip chromedriver_linux64.zip && rm chromedriver_linux64.zip
    chmod +x chromedriver && sudo mv chromedriver /usr/local/bin
fi