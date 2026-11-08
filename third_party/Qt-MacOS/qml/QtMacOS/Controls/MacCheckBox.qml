import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.CheckBox {
    id: control
    implicitHeight: Theme.rowHeight
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    padding: 4
    spacing: 7
    hoverEnabled: true
    font.pixelSize: 13
    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: (control.height - height) / 2
        radius: 4
        color: control.checkState !== Qt.Unchecked ? Theme.accent : control.hovered ? Theme.hover : Theme.field
        border.color: control.visualFocus ? Theme.accent : Theme.border
        border.width: control.visualFocus ? 2 : 1
        opacity: control.enabled ? 1 : 0.45
        Text {
            anchors.centerIn: parent
            text: control.checkState === Qt.PartiallyChecked ? "−" : "✓"
            visible: control.checkState !== Qt.Unchecked
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }
    }
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.enabled ? Theme.text : Theme.secondary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        leftPadding: !control.mirrored ? control.indicator.width + control.spacing : 0
        rightPadding: control.mirrored ? control.indicator.width + control.spacing : 0
    }
}
