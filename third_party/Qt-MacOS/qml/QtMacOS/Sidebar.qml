pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtMacOS

Rectangle {
    id: root
    property var entries: []
    property int currentIndex: 0
    signal activated(int index)
    color: Theme.sidebar
    implicitWidth: 224
    ColumnLayout {
        anchors { fill: parent; margins: 12; topMargin: 22 }
        spacing: 4
        Label {
            text: qsTr("Favourites")
            color: Theme.secondary
            font { pixelSize: 11; bold: true }
            Layout.leftMargin: 10
            Layout.bottomMargin: 8
        }
        Repeater {
            model: root.entries
            delegate: ItemDelegate {
                id: navigationRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Theme.rowHeight
                text: modelData.title
                icon.source: modelData.icon || ""
                icon.color: Theme.accent
                icon.width: 18; icon.height: 18
                font.pixelSize: 13
                palette.text: Theme.text
                palette.highlightedText: Theme.text
                highlighted: root.currentIndex === index
                background: Rectangle {
                    radius: Theme.radius
                    color: navigationRow.highlighted ? Theme.selection : navigationRow.hovered ? Theme.hover : "transparent"
                    border.width: navigationRow.visualFocus ? 2 : 0
                    border.color: Theme.accent
                }
                onClicked: { root.currentIndex = index; root.activated(index) }
            }
        }
        Item { Layout.fillHeight: true }
        Label {
            text: "Qt-MacOS / 0.1"
            color: Theme.secondary
            font.pixelSize: 11
            Layout.leftMargin: 10
            Layout.bottomMargin: 8
        }
    }
}
