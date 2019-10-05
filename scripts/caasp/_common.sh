#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

check_cmd() {
    type "$1" 2>/dev/null
    return $?
}

SCRIPT_DIR=${$(basename "$0")/.sh/}

[[ -d "$SCRIPT_DIR" ]] || mkdir "$SCRIPT_DIR"
cd "$SCRIPT_DIR"
