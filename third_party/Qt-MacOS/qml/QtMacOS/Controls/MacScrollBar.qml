import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ScrollBar {
    id: control
    padding: 2
    hoverEnabled: true
    minimumSize: 0.08
    implicitWidth: vertical ? 10 : 48
    implicitHeight: vertical ? 48 : 10
    background: Rectangle { color: "transparent" }
    contentItem: Rectangle {
        visible: control.policy === Basic.ScrollBar.AlwaysOn || control.size < 1
        implicitWidth: 6
        implicitHeight: 6
        radius: Math.min(width, height) / 2
        color: control.pressed ? Theme.accent : Theme.secondary
        opacity: control.enabled ? control.hovered || control.active ? 0.8 : 0.45 : 0.25
    }
}
