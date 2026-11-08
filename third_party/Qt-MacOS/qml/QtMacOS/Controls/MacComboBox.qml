import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ComboBox {
    id: control
    implicitHeight: Theme.rowHeight
    implicitWidth: Math.max(140, implicitContentWidth + leftPadding + rightPadding)
    hoverEnabled: true
    font.pixelSize: 13
    palette.buttonText: Theme.text
    palette.text: Theme.text
    palette.base: Theme.field
    palette.button: Theme.button
    palette.window: Theme.content
    palette.windowText: Theme.text
    palette.highlight: Theme.selection
    palette.highlightedText: Theme.text
    palette.mid: Theme.border
    palette.disabled.buttonText: Theme.secondary
    background: Rectangle {
        radius: Theme.radius
        color: control.down ? Theme.selection : control.hovered ? Theme.hover : Theme.button
        border.color: control.visualFocus ? Theme.accent : Theme.border
        border.width: control.visualFocus ? 2 : 1
        opacity: control.enabled ? 1 : 0.45
    }
}
