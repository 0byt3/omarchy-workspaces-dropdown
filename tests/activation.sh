#!/usr/bin/env bash
# Exercise package activation against disposable HOME and packaged assets.
set -euo pipefail
project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
(( EUID != 0 )) || { echo 'Run this fixture test as an unprivileged user.' >&2; exit 1; }
stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT
mkdir -p "$stage/assets/nier.workspaces-dropdown" "$stage/assets/nier.onedrive" "$stage/bin"
touch "$stage/assets/nier.workspaces-dropdown/manifest.json" "$stage/assets/nier.onedrive/manifest.json"
printf '%s\n' '{"bar":{"layout":{"left":["omarchy.menu","omarchy.workspaces"],"right":["omarchy.clock"]}},"other":true}' > "$stage/default.json"
sed -e "s|source_dir=/usr/share/nier/plugins/|source_dir=$stage/assets/|" \
    -e "s|input=/usr/share/omarchy/config/omarchy/shell.json|input=$stage/default.json|" \
    "$project/nier-workspaces-dropdown-enable" > "$stage/bin/nier-workspaces-dropdown-enable"
cp "$stage/bin/nier-workspaces-dropdown-enable" "$stage/bin/nier-onedrive-enable"
export HOME=$stage/home
config=$HOME/.config/omarchy/shell.json
run() { bash "$stage/bin/$1" >/dev/null; }
run nier-workspaces-dropdown-enable
run nier-onedrive-enable
jq -e '.other and .bar.layout.left == ["omarchy.menu","nier.workspaces-dropdown"] and .bar.layout.right == ["omarchy.clock","nier.onedrive"]' "$config" >/dev/null
[[ $(readlink "$HOME/.config/omarchy/plugins/nier.onedrive") == "$stage/assets/nier.onedrive" ]]
cp "$config" "$stage/applied"
backups=$(find "$HOME" -name '*.before-*' | wc -l)
run nier-onedrive-enable
run nier-workspaces-dropdown-enable
cmp "$config" "$stage/applied"
[[ $(find "$HOME" -name '*.before-*' | wc -l) == "$backups" ]]
# Account widgets, object-form workspace settings and custom sections survive.
cat > "$config" <<'JSON'
{"bar":{"layout":{"left":[{"id":"omarchy.workspaces","label":"keep"}],"centerEnd":[{"id":"nier.onedrive","account":"personal"},{"id":"nier.onedrive","account":"work"}]}},"disabledPlugins":["nier.onedrive","nier.workspaces-dropdown","other"],"idle":{"lock":900}}
JSON
run nier-workspaces-dropdown-enable
run nier-onedrive-enable
jq -e '.bar.layout.left[0] == {"id":"nier.workspaces-dropdown","label":"keep"} and (.bar.layout | has("right") | not) and (.bar.layout.centerEnd | length) == 2 and .disabledPlugins == ["other"] and .idle.lock == 900' "$config" >/dev/null
# Invalid preferences and collisions must leave config and links untouched.
printf '%s\n' '{broken' > "$config"
cp "$config" "$stage/broken"
rm "$HOME/.config/omarchy/plugins/nier.onedrive"
if run nier-onedrive-enable 2>/dev/null; then exit 1; fi
cmp "$config" "$stage/broken"
[[ ! -e $HOME/.config/omarchy/plugins/nier.onedrive ]]
cp "$stage/default.json" "$config"
mkdir "$HOME/.config/omarchy/plugins/nier.onedrive"
if run nier-onedrive-enable 2>/dev/null; then exit 1; fi
cmp "$config" "$stage/default.json"
rmdir "$HOME/.config/omarchy/plugins/nier.onedrive"
# Keep a user's shell.json symlink, back up its target and preserve file mode.
mv "$config" "$stage/linked.json"
chmod 640 "$stage/linked.json"
ln -s "$stage/linked.json" "$config"
run nier-onedrive-enable
[[ -L $config && $(stat -c %a "$stage/linked.json") == 640 ]]
# Both concurrent package activations must be retained.
rm "$config"
cp "$stage/default.json" "$config"
run nier-workspaces-dropdown-enable &
first=$!
run nier-onedrive-enable &
second=$!
wait "$first"
wait "$second"
jq -e '.bar.layout.left[1] == "nier.workspaces-dropdown" and .bar.layout.right[1] == "nier.onedrive"' "$config" >/dev/null
printf '%s\n' 'PASS: activation, defaults, backups, idempotence, account settings, invalid JSON, collisions, symlinks, permissions and concurrent installs'
