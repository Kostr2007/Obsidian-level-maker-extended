pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Switch {
    id: control
    implicitWidth: text.length ? 52 + contentItem.implicitWidth + spacing : 52
    implicitHeight: 32
    padding: 4
    spacing: 8
    hoverEnabled: true
    indicator: Rectangle {
        implicitWidth: 44
        implicitHeight: 24
        x: control.text.length ? control.mirrored ? control.width - width - control.rightPadding : control.leftPadding : (control.width - width) / 2
        y: (control.height - height) / 2
        radius: 12
        color: control.checked ? Theme.settingsAccent : Theme.dark ? "#65656b" : "#dedee0"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
        opacity: control.enabled ? 1 : 0.45
        Rectangle {
            x: 3 + control.visualPosition * (parent.width - width - 6)
            y: 3
            width: 18
            height: 18
            radius: 9
            color: "#ffffff"
            border.width: 0.5
            border.color: "#eeeeef"
            Rectangle {
                z: -1
                x: -1
                y: 0
                width: 20
                height: 20
                radius: 10
                color: "#16000000"
            }
            Behavior on x {
                enabled: !control.down
                NumberAnimation {
                    duration: 110
                }
            }
        }
    }
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.enabled ? Theme.settingsText : Theme.settingsSecondary
        verticalAlignment: Text.AlignVCenter
        leftPadding: !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.mirrored ? control.indicator.width + control.spacing : 0
    }
}
