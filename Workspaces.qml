import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  property bool opened: false
  property int hoveredWorkspaceIndex: -1
  readonly property var monitor: {
    var window = root.QsWindow.window
    return window && window.screen ? Hyprland.monitorFor(window.screen) : null
  }
  readonly property string monitorName: monitor ? monitor.name : ""
  readonly property var activeWorkspace: monitor ? monitor.activeWorkspace : null
  readonly property string activeLabel: Model.label(activeWorkspace)
  readonly property var workspaceEntries: Model.monitorWorkspaces(Hyprland.workspaces.values, monitorName)
  readonly property int pageSize: 10
  property int pageIndex: 0
  readonly property int pageCount: Math.max(1, Math.ceil(workspaceEntries.length / pageSize))
  readonly property var pageEntries: Model.pageEntries(workspaceEntries, pageIndex, pageSize)

  onPageCountChanged: pageIndex = Math.min(pageIndex, pageCount - 1)
  onMonitorNameChanged: { root.close(); root.pageIndex = 0 }
  onPageIndexChanged: hoveredWorkspaceIndex = -1

  function changePage(offset) {
    pageIndex = Math.max(0, Math.min(pageIndex + offset, pageCount - 1))
  }

  function open() {
    if (!root.bar) return
    root.pageIndex = 0
    for (var i = 0; i < workspaceEntries.length; i++) {
      if (activeWorkspace && workspaceEntries[i].id === activeWorkspace.id) {
        root.pageIndex = Math.floor(i / pageSize)
        break
      }
    }
    root.opened = true
  }

  function close() {
    root.opened = false
    root.hoveredWorkspaceIndex = -1
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function focusWorkspace(workspace) {
    if (!root.bar || !workspace) return
    var expression = Model.focusExpression(workspace)
    root.close()
    root.bar.run("hyprctl dispatch " + Util.shellQuote(expression))
  }

  onVisibleChanged: if (!visible) root.close()
  onBarChanged: if (!bar) root.close()
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.activeLabel || "—"
    horizontalMargin: 6
    fixedWidth: root.vertical ? root.barSize : -1
    fixedHeight: root.vertical ? Math.max(root.barSize, labelWidth + Style.space(12)) : root.barSize
    textRotation: root.vertical ? -90 : 0
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }

  PopupCard {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: popup.fittedContentWidth(Style.space(280))
    contentHeight: popup.fittedContentHeight(monitorHeader.height + workspaceColumn.implicitHeight + navigation.height, Style.space(420))

    Item {
      id: monitorHeader
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: Math.max(monitorLabel.implicitHeight, monitorIcon.height) + Style.spacing.xl

      Image {
        id: monitorIcon
        objectName: "monitorIcon"
        anchors.left: parent.left
        anchors.leftMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(22)
        height: width
        sourceSize.width: Math.round(width * Screen.devicePixelRatio)
        sourceSize.height: Math.round(height * Screen.devicePixelRatio)
        source: Qt.resolvedUrl("monitor.svg")
        fillMode: Image.PreserveAspectFit
        visible: false
        layer.enabled: true
      }

      Rectangle {
        anchors.fill: monitorIcon
        color: button.foreground
        layer.enabled: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: monitorIcon
          maskThresholdMin: 0.5
          maskSpreadAtMin: 1.0
        }
      }

      Text {
        id: monitorLabel
        anchors.left: monitorIcon.right
        anchors.leftMargin: Style.space(8)
        anchors.right: parent.right
        anchors.rightMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.monitorName
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }
    }

    Flickable {
      id: workspaceList
      anchors.top: monitorHeader.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: navigation.top
      clip: true
      contentWidth: width
      contentHeight: workspaceColumn.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      onContentHeightChanged: contentY = 0
      Connections {
        target: root
        function onPageIndexChanged() { workspaceList.contentY = 0 }
      }

      Column {
        id: workspaceColumn
        width: parent.width
        spacing: Style.space(2)

        Repeater {
          model: root.pageEntries

          delegate: CursorSurface {
            id: row
            required property var modelData
            required property int index
            readonly property bool selected: root.activeWorkspace !== null && root.activeWorkspace.id === modelData.id
            width: workspaceColumn.width
            height: rowLabel.implicitHeight + Style.spacing.xl
            hasCursor: root.hoveredWorkspaceIndex === index
            current: selected
            foreground: button.foreground
            fill: Style.hoverFillFor(button.foreground, Color.accent)
            currentFill: Style.selectedFillFor(button.foreground, Color.accent)

            Text {
              id: rowLabel
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.margins: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: "workspace: " + Model.label(row.modelData)
              color: button.foreground
              font.family: button.fontFamily
              font.pixelSize: Style.font.body
              font.bold: row.selected
              elide: Text.ElideRight
            }

            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.hoveredWorkspaceIndex = row.index
              onExited: if (root.hoveredWorkspaceIndex === row.index) root.hoveredWorkspaceIndex = -1
              onClicked: root.focusWorkspace(row.modelData)
            }
          }
        }
      }
    }

    Row {
      id: navigation
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      visible: root.pageCount > 1
      height: visible ? Style.space(36) : 0

      Repeater {
        model: ["Previous", "Page " + (root.pageIndex + 1) + " / " + root.pageCount, "Next"]

        delegate: CursorSurface {
          id: pageControl
          required property int index
          required property string modelData
          readonly property bool available: index === 0 ? root.pageIndex > 0 : index === 2 && root.pageIndex < root.pageCount - 1
          width: navigation.width / 3
          height: navigation.height
          hasCursor: pageMouse.containsMouse && available
          foreground: button.foreground
          fill: Style.hoverFillFor(button.foreground, Color.accent)
          opacity: index === 1 || available ? 1 : 0.4

          Text {
            anchors.centerIn: parent
            textFormat: Text.PlainText
            text: pageControl.modelData
            color: button.foreground
            font.family: button.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          MouseArea {
            id: pageMouse
            anchors.fill: parent
            enabled: pageControl.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.changePage(pageControl.index === 0 ? -1 : 1)
          }
        }
      }
    }
  }
}
