import QtQuick
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  property bool opened: false
  readonly property var activeWorkspace: Hyprland.focusedWorkspace
  readonly property string activeLabel: Model.label(activeWorkspace)
  readonly property var workspaceEntries: Model.sortedWorkspaces(Hyprland.workspaces.values)
  readonly property int pageSize: 10
  property int pageIndex: 0
  readonly property int pageCount: Math.max(1, Math.ceil(workspaceEntries.length / pageSize))
  readonly property var pageEntries: Model.pageEntries(workspaceEntries, pageIndex, pageSize)

  onPageCountChanged: pageIndex = Math.min(pageIndex, pageCount - 1)

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
    contentHeight: popup.fittedContentHeight(workspaceColumn.implicitHeight + navigation.height, Style.space(420))

    Flickable {
      id: workspaceList
      anchors.top: parent.top
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

          delegate: Rectangle {
            id: row
            required property var modelData
            readonly property bool selected: root.activeWorkspace !== null && root.activeWorkspace.id === modelData.id
            width: workspaceColumn.width
            height: Math.max(Style.space(32), rowLabel.implicitHeight + Style.space(12))
            radius: Math.max(2, Style.cornerRadius)
            color: rowMouse.containsMouse ? Style.hoverFillFor(button.foreground, button.foreground) : "transparent"

            Text {
              id: rowLabel
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.margins: Style.space(8)
              anchors.verticalCenter: parent.verticalCenter
              textFormat: Text.PlainText
              text: "workspace: " + Model.label(row.modelData)
              color: button.foreground
              font.family: button.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: row.selected
              elide: Text.ElideRight
            }

            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
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

        delegate: Rectangle {
          id: pageControl
          required property int index
          required property string modelData
          readonly property bool available: index === 0 ? root.pageIndex > 0 : index === 2 && root.pageIndex < root.pageCount - 1
          width: navigation.width / 3
          height: navigation.height
          radius: Math.max(2, Style.cornerRadius)
          color: pageMouse.containsMouse && available ? Style.hoverFillFor(button.foreground, button.foreground) : "transparent"
          opacity: index === 1 || available ? 1 : 0.4

          Text {
            anchors.centerIn: parent
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
