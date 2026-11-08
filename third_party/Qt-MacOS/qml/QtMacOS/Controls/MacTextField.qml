import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.TextField {
    id: control
    implicitWidth: 180
    implicitHeight: Math.max(Theme.rowHeight, contentHeight + topPadding + bottomPadding)
    padding: 7
    leftPadding: 10
    rightPadding: 10
    font.pixelSize: 13
    color: enabled ? Theme.text : Theme.secondary
    placeholderTextColor: Theme.secondary
    selectionColor: Theme.accent
    selectedTextColor: "white"
    selectByMouse: true
    background: Rectangle {
        radius: Theme.radius
        color: Theme.field
        border.color: control.activeFocus ? Theme.accent : Theme.border
        border.width: control.activeFocus ? 2 : 1
        opacity: control.enabled ? 1 : 0.45
    }
}
