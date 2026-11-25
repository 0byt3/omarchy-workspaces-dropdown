#!/usr/bin/env bash
# Load the real widget without installing it or executing workspace dispatches.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
source_dir=$PWD
omarchy_shell=${OMARCHY_SHELL:-/usr/share/omarchy/shell}
stage=$(mktemp -d)
trap 'find "$stage" -depth -delete' EXIT
ln -s "$omarchy_shell/Commons" "$stage/Commons"
ln -s "$omarchy_shell/Ui" "$stage/Ui"
ln -s "$source_dir" "$stage/plugin"
cat > "$stage/shell.qml" <<'QML'
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import "plugin" as Plugin
import "plugin/Model.js" as Model

ShellRoot {
  QtObject {
    id: mockBar
    property bool vertical: false
    property int barSize: 28
    property string position: "top"
    property string fontFamily: "sans-serif"
    property color barForeground: "white"
    property color urgent: "red"
    property bool foregroundAnimationEnabled: false
    property var activePopout: null
    property string lastCommand: ""
    function registerClickTarget(item) {}
    function unregisterClickTarget(item) {}
    function hideTooltip(item) {}
    function showTooltip(item, text) {}
    function requestPopout(owner) { activePopout = owner }
    function releasePopout(owner) { if (activePopout === owner) activePopout = null }
    function run(command) { lastCommand = command }
  }
  PanelWindow {
    id: testWindow
    screen: Quickshell.screens[0]
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusiveZone: 0
    Plugin.Workspaces { id: widget; bar: mockBar }
  }
  PanelWindow {
    id: otherWindow
    screen: Quickshell.screens[Quickshell.screens.length - 1]
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusiveZone: 0
    Plugin.Workspaces { id: otherWidget; bar: mockBar }
  }
  Timer {
    interval: 600; running: true
    onTriggered: {
      function check(condition, message) {
        if (!condition) throw new Error(message)
      }
      try {
        var fixtures = [
          {id: 12, name: "Renamed positive"}, {id: -1338, name: "Desk10"},
          {id: 2, name: "2"}, {id: -1339, name: "alpha"},
          {id: -1340, name: "Desk2"}, {id: 1, name: "1"},
          {id: -99, name: "special:scratch"}, {id: -1341, name: "Beta"}
        ]
        var sorted = Model.sortedWorkspaces(fixtures)
        var labels = sorted.map(function(workspace) { return Model.label(workspace) }).join(",")
        check(labels === "1,2,12,alpha,Beta,Desk2,Desk10", "natural sorting/filtering: " + labels)
        check(Model.label({id: 2, name: "Development"}) === "2", "numbered labels use IDs")
        check(Model.label({id: -1337, name: "Development"}) === "Development", "named label")
        check(Model.label(null) === "", "no active workspace")
        check(Model.selector({id: -1337, name: "Development"}) === "name:Development", "named selector")
        check(Model.luaQuote('A"B\\C\n') === '"A\\"B\\\\C\\010"', "Lua quoting")
        var monitorA = {name: "DP-1"}, monitorB = {name: "HDMI-A-1"}
        var assigned = [
          {id: 12, name: "12", monitor: monitorB},
          {id: 2, name: "2", monitor: monitorA},
          {id: -10, name: "Desk", monitor: monitorA},
          {id: -99, name: "special:scratch", monitor: monitorA},
          {id: 3, name: "3", monitor: null}
        ]
        check(Model.monitorWorkspaces(assigned, "DP-1").map(function(w) { return w.id }).join(",") === "2,-10", "only this monitor, naturally sorted")
        check(Model.monitorWorkspaces(assigned, "HDMI-A-1")[0].id === 12, "other monitor independent")
        check(Model.monitorWorkspaces(assigned, "").length === 0, "no monitor shows no workspaces")
        assigned[0].monitor = {name: "DP-1"}
        check(Model.monitorWorkspaces(assigned, "DP-1").length === 3, "moved workspace and refreshed monitor object")
        check(Model.monitorWorkspaces(assigned, "HDMI-A-1").length === 0, "empty monitor")
        var screenMonitor = Hyprland.monitorFor(testWindow.screen)
        check(screenMonitor !== null, "test screen has a Hyprland monitor")
        check(widget.monitorName === screenMonitor.name, "widget resolves its containing screen")
        check(widget.activeLabel === Model.label(screenMonitor.activeWorkspace), "monitor-local active workspace binding")
        check(widget.workspaceEntries.every(function(w) { return w.monitor.name === widget.monitorName }), "live entries belong to widget monitor")
        var otherMonitor = Hyprland.monitorFor(otherWindow.screen)
        check(otherWidget.monitorName === otherMonitor.name, "second widget resolves its own screen")
        check(otherWidget.activeLabel === Model.label(otherMonitor.activeWorkspace), "second widget has independent active workspace")
        check(otherWidget.workspaceEntries.every(function(w) { return w.monitor.name === otherMonitor.name }), "second widget filters independently")
        if (screenMonitor.name !== otherMonitor.name) {
          check(widget.workspaceEntries.every(function(w) {
            return !otherWidget.workspaceEntries.some(function(other) { return other.id === w.id })
          }), "different monitors have disjoint workspace lists")
        }
        check(widget.implicitWidth > 0 && widget.implicitHeight > 0, "bar sizing")
        var many = []
        for (var i = 1; i <= 21; i++) many.push({id: i, name: String(i)})
        check(Model.pageEntries([], 0, 10).length === 0, "empty page")
        check(Model.pageEntries(many.slice(0, 10), 0, 10).length === 10, "exactly ten workspaces")
        check(Model.pageEntries(many.slice(0, 11), 1, 10).length === 1, "eleven workspaces")
        check(Model.pageEntries(many, 0, 10)[9].id === 10, "first page boundary")
        check(Model.pageEntries(many, 1, 10)[0].id === 11, "second page boundary")
        check(Model.pageEntries(many, 2, 10).length === 1, "partial final page")
        check(Model.pageEntries(many, 99, 10)[0].id === 21, "page clamped after removal")
        check(Model.pageEntries(many, -1, 10)[0].id === 1, "negative page clamped")
        widget.changePage(-999)
        check(widget.pageIndex === 0, "previous page lower bound")
        widget.changePage(999)
        check(widget.pageIndex === widget.pageCount - 1, "next page upper bound")
        check(widget.pageEntries.length <= 10, "widget page size")
        widget.focusWorkspace(Model.pageEntries(many, 1, 10)[0])
        check(mockBar.lastCommand === "hyprctl dispatch " + Util.shellQuote(Model.focusExpression(many[10])), "selection from second page")
        widget.focusWorkspace({id: -1337, name: 'Dev "tools"; $(false)'})
        check(mockBar.lastCommand === "hyprctl dispatch " + Util.shellQuote(Model.focusExpression({id: -1337, name: 'Dev "tools"; $(false)'})), "named dispatch quoting")
        check(!widget.opened, "selection closes popup")
        widget.focusWorkspace({id: 12, name: "Renamed positive"})
        check(mockBar.lastCommand === "hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "12" })'), "numbered dispatch")
        mockBar.vertical = true
        check(widget.implicitWidth === mockBar.barSize, "vertical sizing")
        console.log("PASS: widget loads, monitor-local active label/filtering, natural sorting, pagination, named/numbered dispatch and quoting")
        Qt.quit()
      } catch (error) {
        console.error("FAIL: " + error.message)
        Qt.quit()
      }
    }
  }
}
QML
status=0
QT_QPA_PLATFORM=wayland timeout 12 quickshell --no-color -p "$stage" > "$stage/log" 2>&1 || status=$?
cat "$stage/log"
(( status == 0 )) || exit "$status"
grep -q 'PASS: widget loads' "$stage/log"
if grep -E 'FAIL:|Failed to load|TypeError|ReferenceError|Cannot assign|is not a type|is not defined' "$stage/log"; then exit 1; fi
