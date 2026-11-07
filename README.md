# Omarchy Workspaces Dropdown

An Omarchy bar plugin showing only the active workspace, with a clickable
dropdown for selecting another workspace.

## Behavior

- The bar shows the active workspace's numeric ID, or its name for a named
  workspace. Renamed numbered workspaces still display their numeric ID.
- Left-click the label to open or close the dropdown.
- Every row is labeled `workspace: <number or name>`. Existing numbered and
  named workspaces are sorted naturally, ignoring case: `1, 2, 10, alpha,
  Desk2, Desk10`. Numbered workspaces are not restricted to IDs 1–10.
- Click a row to focus that workspace and dismiss the dropdown. Named
  workspaces are selected by name; numbered workspaces by numeric ID.
- Lists longer than 10 workspaces have 10 entries per page, with Previous/Next
  controls and a page indicator. Opening the dropdown shows the active
  workspace's page. Unavailable navigation controls are disabled.
- The active row is bold. Pages can scroll on smaller screens. Clicking outside dismisses the
  popup using Omarchy's shared popup behavior.
- Special overlay workspaces are excluded. The plugin lists workspaces
  exposed by Hyprland, including existing persistent workspaces; it does not
  invent additional empty workspace buttons.

## Files

- Plugin ID: `nier.workspaces-dropdown`.
- `Workspaces.qml`: active-workspace button and Omarchy `PopupCard` dropdown.
- `Model.js`: label selection, natural sorting, and safe Lua selector quoting.
- `manifest.json`: copied manifest with a separate plugin identity and
  `omarchy.clonedFrom` pointing to `omarchy.workspaces`. The QML retains the
  original module name, matching Omarchy's plugin-clone routing convention.

Originally copied from the installed Omarchy files:

```text
/usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml
/usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.manifest.json
```

Deployed and enabled on Omarchy VM 106 (`localadmin@10.0.2.126`) under
`~/.config/omarchy/plugins/nier.workspaces-dropdown/`. It replaces the stock
workspace widget in the left bar section. The previous bar configuration is
saved at `~/.local/state/nier-workspaces-dropdown/shell.before-deploy.json`.

## Validation

```sh
./tests/qml-smoke.sh
```

The test requires a running Hyprland session, Quickshell, and installed Omarchy
UI modules (`OMARCHY_SHELL` overrides `/usr/share/omarchy/shell`). It loads the
real widget in an isolated harness and checks active labels, numeric/named
sorting, special-workspace filtering, pagination, sizing, and escaped selection commands.
Workspace dispatches are captured by a mock bar; tests do not change the live
bar or switch workspaces.

Live testing on VM 106 verified numbered/named selection, natural sorting,
Previous/Next controls, active-page reopening, outside-click dismissal, exactly
10 entries without pagination, and an 11th entry on a second page. Removing
the 11th workspace while that page was open returned the list to page one.
Temporary workspace rules were removed, the original workspace was restored,
and idle behavior was re-enabled. During cleanup, a Hyprland configuration
reload left stale workspace data in Quickshell; `omarchy restart shell`
refreshed it. Live rule addition/removal without a compositor reload worked.

## Pacman package

The Nier repository supplies `nier-workspaces-dropdown`. The package installs
read-only widget files in `/usr/share/nier/plugins/nier.workspaces-dropdown/`.
Installation and upgrades register the plugin for the installing desktop user and
replace `omarchy.workspaces` in `~/.config/omarchy/shell.json`. If the stock
widget is absent, the dropdown is added on the left. Changed preferences are
backed up alongside `shell.json`. Other widgets and settings are preserved.

The hook identifies the sudo/pkexec or login user, falling back to a single
graphical session. User-file changes run as that user. If no user can be
identified (for example in a build container), activation is skipped with a
message. Custom plugin directories/links are preserved with a warning. Future
accounts and unrelated users are not modified. To enable it manually or retry:

```sh
nier-workspaces-dropdown-enable
```

Omarchy hot-reloads the configuration; run `omarchy restart shell` if needed.
Uninstalling does not restore the backup or change user preferences.

Build with `NIER_PACKAGE_OUTPUT=/path/to/output bash tests/package.sh`.
