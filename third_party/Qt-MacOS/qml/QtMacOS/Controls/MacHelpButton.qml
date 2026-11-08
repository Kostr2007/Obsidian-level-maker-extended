import QtQuick
import QtMacOS

MacPushButton {
    id: control
    text: "?"
    implicitWidth: 32
    Accessible.name: qsTr("Help")
    background: Rectangle {
        radius: height / 2
        color: control.down ? Theme.settingsSeparator : Theme.dark ? "#49494d" : "#eeeeef"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.settingsAccent
        opacity: control.enabled ? 1 : 0.45
    }
}
