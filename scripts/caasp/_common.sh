#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

check_cmd() {
    type $1 2>/dev/null
    return $?
}

HOME_DIR="$HOME/.caasp-auto-util"

[[ -d "$HOME_DIR" ]] || mkdir "$HOME_DIR"
cd "$HOME_DIR"

SCRIPT_DIR=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR/.sh/}

[[ -d "$SCRIPT_DIR" ]] || mkdir "$SCRIPT_DIR"
cd "$SCRIPT_DIR"

./$HOME/.bashrc