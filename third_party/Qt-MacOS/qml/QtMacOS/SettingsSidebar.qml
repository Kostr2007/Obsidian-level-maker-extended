pragma ComponentBehavior: Bound
import QtQuick
import QtMacOS
import QtQuick.Controls.Basic as Basic

Rectangle {
    id: sidebar
    property bool dark: false
    property string currentKey: "Mouse"
    property string fontFamily: "Inter Variable"
    property alias searchText: search.text
    signal navigate(string key)
    implicitWidth: 300
    radius: 28
    color: dark ? "#30383d" : "#eef8fa"
    gradient: Gradient {
        GradientStop {
            position: 0
            color: sidebar.dark ? "#30383d" : "#eaf8fe"
        }
        GradientStop {
            position: 0.5
            color: sidebar.dark ? "#30363b" : "#f5fbfd"
        }
        GradientStop {
            position: 1
            color: sidebar.dark ? "#303832" : "#eff9f4"
        }
    }
    readonly property color foreground: dark ? "#f0f0f2" : "#242527"
    property var entries: []
    readonly property var visibleEntries: {
        const query = search.text.trim().toLocaleLowerCase();
        return entries.filter(item => !query || item.key.toLocaleLowerCase().includes(query));
    }
    function focusSearch() {
        search.forceActiveFocus();
    }
    function revealCurrent() {
        if (!search.text.length) {
            const index = visibleEntries.findIndex(item => item.key === currentKey);
            if (index >= 0)
                navigation.positionViewAtIndex(index, ListView.Contain);
        }
    }
    onCurrentKeyChanged: Qt.callLater(revealCurrent)
    Component.onCompleted: Qt.callLater(revealCurrent)

    Basic.TextField {
        id: search
        objectName: "settingsSearch"
        x: 22
        y: 88
        width: parent.width - 42
        height: 38
        leftPadding: 36
        rightPadding: 12
        selectByMouse: true
        font {
            family: sidebar.fontFamily
            pixelSize: 16
        }
        color: sidebar.foreground
        placeholderText: qsTr("Search")
        placeholderTextColor: sidebar.dark ? "#aeb5ba" : "#849297"
        Accessible.name: qsTr("Search settings")
        onTextChanged: {
            navigation.contentY = 0;
            if (!text.length)
                Qt.callLater(sidebar.revealCurrent);
        }
        background: Rectangle {
            radius: 19
            color: sidebar.dark ? "#424c52" : "#dfebef"
            border.width: search.activeFocus ? 2 : 0
            border.color: "#55a0ef"
        }
        SettingsIcon {
            x: 11
            anchors.verticalCenter: parent.verticalCenter
            width: 19
            height: 19
            name: "search"
            color: sidebar.dark ? "#aeb5ba" : "#849297"
        }
    }
    ListView {
        id: navigation
        objectName: "settingsNavigation"
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 20
            rightMargin: 15
            topMargin: 132
            bottomMargin: 14
        }
        model: sidebar.visibleEntries
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onHeightChanged: Qt.callLater(sidebar.revealCurrent)
        Basic.ScrollBar.vertical: Basic.ScrollBar {
            id: navScroll
            width: 10
            padding: 0
            background: Item {}
            contentItem: Rectangle {
                radius: 5
                color: sidebar.dark ? "#92989c" : "#888e90"
                implicitWidth: 9
                implicitHeight: 40
                visible: navScroll.size < 1
            }
        }
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            width: navigation.width - 8
            height: 44 + (modelData.gap && !search.text.length ? 20 : 0)
            Basic.ItemDelegate {
                id: button
                objectName: "settingsItem_" + row.modelData.key
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 44
                padding: 8
                hoverEnabled: true
                Accessible.name: row.modelData.key
                highlighted: sidebar.currentKey === row.modelData.key
                onClicked: sidebar.navigate(row.modelData.key)
                background: Rectangle {
                    radius: 10
                    color: button.highlighted ? "#0067d8" : button.hovered ? (sidebar.dark ? "#454f56" : "#e0ebee") : "transparent"
                    border.width: button.visualFocus ? 2 : 0
                    border.color: "#89c5ff"
                }
                contentItem: Item {
                    Rectangle {
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 6
                        color: row.modelData.tint
                        border.width: 0.5
                        border.color: "#12000000"
                        SettingsIcon {
                            anchors.fill: parent
                            name: row.modelData.icon
                        }
                    }
                    Text {
                        x: 38
                        width: parent.width - 40
                        height: parent.height
                        text: row.modelData.key
                        color: button.highlighted ? "white" : sidebar.foreground
                        font {
                            family: sidebar.fontFamily
                            pixelSize: 17
                        }
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
