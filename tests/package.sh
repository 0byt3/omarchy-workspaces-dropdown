#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
declare -a source=()
# shellcheck source=/dev/null
source "$project/PKGBUILD"
for name in "${source[@]}"; do mkdir -p "$stage/$(dirname "$name")"; cp "$project/$name" "$stage/$name"; done
cp "$project/PKGBUILD" "$stage/"
cd "$stage"
makepkg --nodeps --noconfirm
bsdtar -xOf ./*.pkg.tar.zst .INSTALL | grep -q nier-workspaces-dropdown-enable
bsdtar -tf ./*.pkg.tar.zst | grep -q '^usr/bin/nier-workspaces-dropdown-enable$'
if [[ -n ${NIER_PACKAGE_OUTPUT:-} ]]; then mkdir -p "$NIER_PACKAGE_OUTPUT"; cp ./*.pkg.tar.zst "$NIER_PACKAGE_OUTPUT/"; fi
