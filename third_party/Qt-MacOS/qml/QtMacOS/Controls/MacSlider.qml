pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.Slider {
    id: control
    property string minimumText: qsTr("Slow")
    property string maximumText: qsTr("Fast")
    property int tickCount: 11
    readonly property bool hasCaptions: horizontal && (minimumText.length > 0 || maximumText.length > 0)
    implicitWidth: horizontal ? 300 : 36
    implicitHeight: horizontal ? (hasCaptions ? 54 : 32) : 180
    padding: 0
    bottomPadding: hasCaptions ? 22 : 0
    hoverEnabled: true
    Accessible.name: qsTr("Value")
    background: Item {
        x: control.leftPadding
        y: control.topPadding
        implicitWidth: control.horizontal ? 300 : 36
        implicitHeight: control.horizontal ? 34 : 180
        width: control.availableWidth
        height: control.availableHeight
        opacity: control.enabled ? 1 : 0.45
        Rectangle {
            id: track
            x: control.horizontal ? 0 : (parent.width - width) / 2
            y: control.horizontal ? (parent.height - height) / 2 : 0
            width: control.horizontal ? parent.width : 7
            height: control.horizontal ? 7 : parent.height
            radius: 3.5
            color: Theme.dark ? "#57575b" : "#e2e2e4"
            scale: control.horizontal && control.mirrored ? -1 : 1
            Rectangle {
                width: control.horizontal ? 12 + control.position * (parent.width - 24) : parent.width
                height: control.horizontal ? parent.height : 12 + control.position * (parent.height - 24)
                anchors.bottom: control.horizontal ? undefined : parent.bottom
                radius: parent.radius
                color: Theme.settingsAccent
            }
        }
        Repeater {
            model: control.horizontal ? Math.max(0, control.tickCount) : 0
            Rectangle {
                required property int index
                x: 12 + index * (control.availableWidth - 24) / Math.max(1, control.tickCount - 1) - 1
                y: control.availableHeight / 2 + 9
                width: 2
                height: 2
                radius: 1
                color: Theme.dark ? "#77777b" : "#c4c4c8"
            }
        }
        Text {
            y: parent.height + 1
            visible: control.hasCaptions
            text: control.minimumText
            font {
                family: control.font.family
                pixelSize: 13
            }
            color: Theme.settingsSecondary
        }
        Text {
            anchors.right: parent.right
            y: parent.height + 1
            visible: control.hasCaptions
            text: control.maximumText
            font {
                family: control.font.family
                pixelSize: 13
            }
            color: Theme.settingsSecondary
        }
    }
    handle: Rectangle {
        x: control.leftPadding + (control.horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
        implicitWidth: 24
        implicitHeight: 24
        radius: 12
        color: control.pressed ? "#f8f8f8" : "#ffffff"
        border.width: control.visualFocus ? 2 : 0.5
        border.color: control.visualFocus ? Theme.accent : "#e9e9eb"
        opacity: control.enabled ? 1 : 0.55
        Rectangle {
            z: -1
            x: -1
            y: 1
            width: parent.width + 2
            height: parent.height + 2
            radius: width / 2
            color: "#10000000"
        }
    }
}
