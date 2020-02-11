#!/usr/bin/env bash

ssh USER@HOST <<"EOF"
zypper in -y jq

mapfile -t products < <(SUSEConnect -s | jq '. | map(.identifier+"/"+.version+"/"+.arch)[]')
for i in "${products[@]}"; do
  # shellcheck disable=SC2086
  SUSEConnect -d -p $i || true
done

mapfile -t repos < <(zypper lr -u | grep "download.suse.de" | awk '{print $3}')
for i in "${repos[@]}"; do
  # shellcheck disable=SC2086
  zypper rr $i
done

# shellcheck disable=SC2086
(
  pkg_name=$(zypper se -i | grep -i patterns-caasp | awk '{print $3}')
  zypper info --requires $pkg_name
  zypper rm -t pattern $pkg_name
)
EOF
