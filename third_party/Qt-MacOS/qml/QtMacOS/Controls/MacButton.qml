import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Button {
    id: control
    implicitHeight: Math.max(Theme.rowHeight, contentItem.implicitHeight + topPadding + bottomPadding)
    implicitWidth: Math.max(72, contentItem.implicitWidth + leftPadding + rightPadding)
    padding: 6
    leftPadding: 12
    rightPadding: 12
    spacing: 6
    hoverEnabled: true
    font.pixelSize: 13
    icon.width: 16
    icon.height: 16
    icon.color: highlighted ? Theme.accentText : Theme.text
    palette.buttonText: Theme.text
    palette.windowText: Theme.text
    palette.brightText: highlighted ? Theme.accentText : Theme.text
    palette.highlightedText: Theme.text
    palette.disabled.buttonText: Theme.secondary
    background: Rectangle {
        implicitWidth: 72
        implicitHeight: Theme.rowHeight
        radius: Theme.radius
        color: control.highlighted ? (control.down ? Qt.darker(Theme.accent, 1.15) : Theme.accent)
             : control.down || control.checked ? Theme.selection
             : control.hovered ? Theme.hover : control.flat ? "transparent" : Theme.button
        border.color: control.visualFocus ? Theme.accent : Theme.border
        border.width: control.visualFocus ? 2 : control.flat && !control.checked ? 0 : 1
        opacity: control.enabled ? 1 : 0.45
    }
}
