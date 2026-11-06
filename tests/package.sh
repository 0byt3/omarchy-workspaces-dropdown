#!/usr/bin/env bash
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
declare -a source=()
# shellcheck source=/dev/null
source "$project/PKGBUILD"
for name in "${source[@]}"; do cp "$project/$name" "$stage/"; done
cp "$project/PKGBUILD" "$stage/"
cd "$stage"
makepkg --nodeps --noconfirm
if [[ -n ${NIER_PACKAGE_OUTPUT:-} ]]; then mkdir -p "$NIER_PACKAGE_OUTPUT"; cp ./*.pkg.tar.zst "$NIER_PACKAGE_OUTPUT/"; fi
