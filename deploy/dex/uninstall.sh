#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC2164
cd "$DIR"

helm uninstall dex
helm uninstall gangway
helm uninstall openldap
