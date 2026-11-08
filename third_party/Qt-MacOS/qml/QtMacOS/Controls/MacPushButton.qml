import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Button {
    id: control
    implicitWidth: Math.max(76, implicitContentWidth + 28)
    implicitHeight: 32
    hoverEnabled: true
    leftPadding: 14
    rightPadding: 14
    font.pixelSize: 17
    palette.buttonText: Theme.settingsText
    palette.windowText: Theme.settingsText
    palette.brightText: "#ffffff"
    palette.disabled.buttonText: Theme.settingsSecondary
    background: Rectangle {
        radius: 6
        color: control.highlighted ? Theme.settingsAccent : control.down ? (Theme.dark ? "#606064" : "#dedee0") : control.hovered ? (Theme.dark ? "#555559" : "#e7e7e9") : (Theme.dark ? "#49494d" : "#eeeeef")
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
        opacity: control.enabled ? 1 : 0.45
    }
}
