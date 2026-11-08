pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import QtQuick.Controls.Basic as Basic
import QtMacOS

FocusScope {
    id: control
    property var model
    property string selectedId: ""
    property string emptyText: qsTr("No items")
    readonly property int itemCount: grid.count
    readonly property int columnCount: Math.max(1, Math.floor(width / 160))
    signal selectionRequested(string itemId)
    signal activated(string itemId)
    signal contextRequested(string itemId, real x, real y)

    implicitWidth: 640
    implicitHeight: 400
    activeFocusOnTab: true
    Accessible.role: Accessible.List
    Accessible.name: qsTr("Collection")

    // DelegateModel exposes role data without creating every visual delegate.
    // Selection belongs to the caller, so row insertion and sorting cannot
    // change the selected identity or destroy a selectedId binding.
    function idAt(index) {
        if (index < 0 || index >= items.items.count)
            return ""
        return String(items.items.get(index).model.itemId)
    }
    function selectedIndex() {
        for (let index = 0; index < items.items.count; ++index) {
            if (idAt(index) === selectedId)
                return index
        }
        return -1
    }
    function requestIndex(index) {
        if (itemCount === 0)
            return
        index = Math.max(0, Math.min(itemCount - 1, index))
        grid.positionViewAtIndex(index, GridView.Contain)
        selectionRequested(idAt(index))
    }
    Keys.onPressed: (event) => {
        const current = selectedIndex()
        switch (event.key) {
        case Qt.Key_Left: requestIndex(current < 0 ? 0 : current - 1); break
        case Qt.Key_Right: requestIndex(current < 0 ? 0 : current + 1); break
        case Qt.Key_Up: requestIndex(current < 0 ? 0 : current - columnCount); break
        case Qt.Key_Down: requestIndex(current < 0 ? 0 : current + columnCount); break
        case Qt.Key_Home: requestIndex(0); break
        case Qt.Key_End: requestIndex(itemCount - 1); break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (current >= 0) activated(selectedId)
            break
        case Qt.Key_Space:
            if (current >= 0) selectionRequested(selectedId)
            break
        default: event.accepted = false; return
        }
        event.accepted = true
    }

    DelegateModel {
        id: items
        model: control.model
        delegate: MacLockup {
            id: card
            required property var model
            required property int index
            width: grid.cellWidth - 12
            height: grid.cellHeight - 12
            x: 6
            y: 6
            itemId: String(model.itemId)
            title: String(model.title)
            subtitle: String(model.subtitle ?? "")
            kind: String(model.kind ?? "folder")
            tint: model.tint ?? "#52b9ed"
            selected: control.selectedId === itemId
            focusPolicy: Qt.NoFocus
            onActivated: {
                control.forceActiveFocus(Qt.MouseFocusReason)
                control.selectionRequested(itemId)
            }
            onDoubleClicked: control.activated(itemId)
            onContextRequested: (x, y) => {
                const position = card.mapToItem(control, x, y)
                control.contextRequested(itemId, position.x, position.y)
            }
        }
    }
    GridView {
        objectName: "macCollectionGrid"
        id: grid
        anchors.fill: parent
        clip: true
        model: items
        cellWidth: Math.max(160, width / control.columnCount)
        cellHeight: 160
        currentIndex: -1
        boundsBehavior: Flickable.StopAtBounds
        Basic.ScrollBar.vertical: Basic.ScrollBar { }
    }
    Text {
        objectName: "collectionEmptyLabel"
        anchors.centerIn: parent
        visible: control.itemCount === 0
        text: control.emptyText
        color: Theme.settingsSecondary
        font.pixelSize: 14
    }
    Rectangle {
        anchors.fill: parent
        radius: 9
        color: "transparent"
        border.width: control.activeFocus ? 2 : 0
        border.color: Theme.settingsAccent
    }
}
