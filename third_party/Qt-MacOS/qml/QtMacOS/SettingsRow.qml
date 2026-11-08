import QtQuick
import QtMacOS

Item {
    id: row
    default property alias controls: controlHost.data
    property string title: ""
    property string description: ""
    property int controlWidth: 300
    property int rowHeight: 64
    property real labelOffset: 0
    property real controlOffset: 0
    property bool separator: true
    property string fontFamily: "sans-serif"
    implicitWidth: 600
    implicitHeight: Math.max(rowHeight, labels.implicitHeight + 20, controlHost.implicitHeight + 12)
    width: parent ? parent.width : implicitWidth
    Column {
        id: labels
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: row.labelOffset
        width: Math.max(0, row.width - row.controlWidth - 16)
        spacing: 4
        Text {
            width: parent.width
            text: row.title
            color: Theme.settingsText
            font {
                family: row.fontFamily
                pixelSize: 17
            }
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            text: row.description
            visible: text.length > 0
            color: Theme.settingsSecondary
            font {
                family: row.fontFamily
                pixelSize: 14
            }
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: controlHost
        x: row.width - width
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: row.controlOffset
        width: Math.min(row.controlWidth, row.width)
        implicitHeight: childrenRect.height
        height: implicitHeight
    }
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: Theme.settingsSeparator
        visible: row.separator
    }
}
