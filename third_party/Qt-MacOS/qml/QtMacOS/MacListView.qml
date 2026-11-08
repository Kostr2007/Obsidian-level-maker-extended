pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

FocusScope {
    id: control
    implicitWidth: 320
    implicitHeight: 320
    property var model
    property string selectedId: ""
    property string emptyText: qsTr("No items")
    property var rowIdProvider: null
    readonly property int count: list.count
    readonly property int currentIndex: list.currentIndex
    signal selectionRequested(string itemId)

    function itemIdAt(index) {
        if (typeof rowIdProvider === "function")
        // Callback validated with typeof above; QML has no function-valued property type.
        // qmllint disable use-proper-function
            return String(rowIdProvider(index));
        // qmllint enable use-proper-function
        if (model && typeof model.itemIdAt === "function")
            return String(model.itemIdAt(index));
        if (model && typeof model.get === "function") {
            const entry = model.get(index);
            return entry && entry.itemId !== undefined ? String(entry.itemId) : "";
        }
        const item = list.itemAtIndex(index);
        return item ? item.stableId : "";
    }
    function selectIndex(index) {
        if (count === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(count - 1, index));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
        list.forceLayout();
        const id = itemIdAt(list.currentIndex);
        if (id !== "")
            selectionRequested(id);
    }
    function synchronizeSelection() {
        for (let i = 0; i < count; ++i) {
            if (itemIdAt(i) === selectedId) {
                list.currentIndex = i;
                return;
            }
        }
        list.currentIndex = -1;
    }
    onSelectedIdChanged: synchronizeSelection()
    Keys.onPressed: event => {
        synchronizeSelection();
        if (event.key === Qt.Key_Down) selectIndex(list.currentIndex + 1);
        else if (event.key === Qt.Key_Up) selectIndex(list.currentIndex - 1);
        else if (event.key === Qt.Key_Home) selectIndex(0);
        else if (event.key === Qt.Key_End) selectIndex(count - 1);
        else return;
        event.accepted = true;
    }

    Rectangle { anchors.fill: parent; color: Theme.content }
    ListView {
        id: list
        objectName: "macListContent"
        anchors.fill: parent
        anchors.margins: 6
        clip: true
        model: control.model
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        onCountChanged: control.synchronizeSelection()
        Basic.ScrollBar.vertical: MacScrollBar {}
        delegate: Rectangle {
            id: row
            required property var model
            required property int index
            readonly property string stableId: String(model.itemId)
            readonly property bool selected: stableId === control.selectedId
            width: list.width
            height: 50
            radius: 5
            color: selected ? (control.activeFocus ? Theme.accent : Theme.selection)
                            : (hover.hovered ? Theme.hover : "transparent")
            Accessible.role: Accessible.ListItem
            Accessible.name: String(model.title)
            Accessible.selected: selected
            Accessible.onPressAction: {
                control.forceActiveFocus();
                list.currentIndex = index;
                control.selectionRequested(stableId);
            }
            HoverHandler { id: hover }
            Rectangle {
                x: 10; anchors.verticalCenter: parent.verticalCenter
                width: 26; height: 29; radius: 4
                color: row.model.tint || Theme.accent
                opacity: 0.85
                Text { anchors.centerIn: parent; text: "▤"; color: "white"; font.pixelSize: 18 }
            }
            Column {
                x: 47; anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - 61)
                spacing: 2
                Text {
                    width: parent.width; text: row.model.title
                    color: row.selected && control.activeFocus ? Theme.accentText : Theme.text
                    font.pixelSize: 13; elide: Text.ElideRight
                }
                Text {
                    width: parent.width; text: row.model.subtitle || row.model.kind || ""
                    color: row.selected && control.activeFocus ? Theme.accentText : Theme.secondary
                    font.pixelSize: 11; elide: Text.ElideRight
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    control.forceActiveFocus();
                    list.currentIndex = row.index;
                    control.selectionRequested(row.stableId);
                }
            }
        }
    }
    Text {
        anchors.centerIn: parent
        visible: list.count === 0
        text: control.emptyText
        color: Theme.secondary; font.pixelSize: 13
    }
}
