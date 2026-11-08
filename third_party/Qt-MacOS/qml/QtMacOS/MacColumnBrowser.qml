pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

// One virtualized list per level, backed by the same hierarchy as MacOutlineView.
Item {
    id: root
    property var source: null
    property string selectedId: ""
    property real columnWidth: 228
    property var columnWidths: ({})
    property bool showBreadcrumbs: true
    signal selectionRequested(string itemId)
    readonly property var selectedPath: {
        const revision = source ? source.revision : 0;
        return source && selectedId.length ? source.pathFor(selectedId) : [];
    }
    readonly property var columns: {
        const revision = source ? source.revision : 0;
        if (!source)
            return [];
        const result = [
            {
                parentId: "",
                items: source.childrenFor(""),
                selectedId: selectedPath.length ? selectedPath[0].itemId : ""
            }
        ];
        for (let i = 0; i < selectedPath.length; ++i) {
            const node = selectedPath[i];
            if (node.hasChildren)
                result.push({
                    parentId: node.itemId,
                    items: source.childrenFor(node.itemId),
                    selectedId: i + 1 < selectedPath.length ? selectedPath[i + 1].itemId : ""
                });
        }
        return result;
    }
    activeFocusOnTab: true
    Keys.onLeftPressed: requestParent()
    Keys.onRightPressed: requestChild()
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    implicitWidth: 690
    implicitHeight: 330

    function columnWidthFor(parentId) {
        const stored = columnWidths ? columnWidths[parentId] : undefined;
        const value = Number(stored === undefined ? columnWidth : stored);
        return Math.max(144, Math.min(500, Number.isFinite(value) ? value : 228));
    }

    function resizeColumn(parentId, width) {
        const value = Number(width);
        if (!Number.isFinite(value))
            return;
        const updated = Object.assign({}, columnWidths || {});
        updated[parentId] = Math.max(144, Math.min(500, value));
        columnWidths = updated;
    }

    function requestParent() {
        if (selectedPath.length > 1)
            selectionRequested(selectedPath[selectedPath.length - 2].itemId);
    }

    function requestChild() {
        if (!source || !selectedId.length)
            return;
        const children = source.childrenFor(selectedId);
        if (children.length)
            selectionRequested(children[0].itemId);
    }

    function moveSelection(step) {
        if (!source)
            return;
        const parentId = selectedPath.length > 1 ? selectedPath[selectedPath.length - 2].itemId : "";
        const siblings = source.childrenFor(parentId);
        let current = -1;
        for (let i = 0; i < siblings.length; ++i) {
            if (siblings[i].itemId === selectedId)
                current = i;
        }
        const next = Math.max(0, Math.min(siblings.length - 1, current + step));
        if (siblings.length)
            selectionRequested(siblings[next].itemId);
    }

    onColumnsChanged: Qt.callLater(function () {
        if (!scroller)
            return;
        scroller.contentX = Math.max(0, scroller.contentWidth - scroller.width);
    })

    Rectangle {
        anchors.fill: parent
        color: Theme.content
    }
    Flickable {
        id: scroller
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: breadcrumbs.top
        }
        clip: true
        contentWidth: columnRow.width
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        Basic.ScrollBar.horizontal: MacScrollBar {}
        Row {
            id: columnRow
            height: scroller.height
            Repeater {
                model: root.columns
                delegate: Item {
                    id: column
                    required property var modelData
                    required property int index
                    width: root.columnWidthFor(modelData.parentId)
                    height: columnRow.height
                    ListView {
                        id: list
                        anchors {
                            fill: parent
                            margins: 6
                            rightMargin: 8
                            bottomMargin: 12
                        }
                        clip: true
                        spacing: 2
                        model: column.modelData.items
                        boundsBehavior: Flickable.StopAtBounds
                        currentIndex: {
                            for (let i = 0; i < column.modelData.items.length; ++i) {
                                if (column.modelData.items[i].itemId === column.modelData.selectedId)
                                    return i;
                            }
                            return -1;
                        }
                        Basic.ScrollBar.vertical: MacScrollBar {}
                        delegate: Basic.ItemDelegate {
                            id: entry
                            required property var modelData
                            required property int index
                            readonly property bool chosen: modelData.itemId === column.modelData.selectedId
                            readonly property bool currentSelection: modelData.itemId === root.selectedId
                            width: list.width
                            height: 30
                            leftPadding: 8
                            rightPadding: 8
                            hoverEnabled: true
                            activeFocusOnTab: false
                            Accessible.name: modelData.title
                            Accessible.role: Accessible.ListItem
                            Accessible.selected: chosen
                            background: Rectangle {
                                radius: 5
                                color: entry.chosen ? entry.currentSelection ? Theme.accent : Theme.selection : entry.hovered ? Theme.hover : "transparent"
                                border.width: entry.activeFocus ? 2 : 0
                                border.color: Theme.accent
                            }
                            contentItem: Row {
                                spacing: 7
                                Item {
                                    width: 18
                                    height: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle {
                                        x: 1
                                        y: 3
                                        width: 8
                                        height: 5
                                        radius: 1
                                        visible: entry.modelData.hasChildren
                                        color: entry.modelData.tint || Theme.accent
                                    }
                                    Rectangle {
                                        x: 1
                                        y: entry.modelData.hasChildren ? 6 : 2
                                        width: entry.modelData.hasChildren ? 17 : 13
                                        height: entry.modelData.hasChildren ? 12 : 17
                                        radius: 2
                                        color: entry.currentSelection ? "#c5e6ff" : entry.modelData.tint || Theme.accent
                                        opacity: entry.modelData.hasChildren ? 1 : 0.65
                                    }
                                }
                                Text {
                                    width: Math.max(0, entry.availableWidth - 42)
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: entry.modelData.title
                                    color: entry.currentSelection ? Theme.accentText : Theme.text
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "›"
                                    font.pixelSize: 20
                                    visible: entry.modelData.hasChildren
                                    color: entry.currentSelection ? Theme.accentText : Theme.secondary
                                }
                            }
                            onClicked: {
                                root.selectionRequested(modelData.itemId);
                                root.forceActiveFocus();
                            }
                        }
                        Text {
                            anchors {
                                centerIn: parent
                            }
                            visible: list.count === 0
                            text: qsTr("No items")
                            font.pixelSize: 12
                            color: Theme.secondary
                        }
                    }
                    MouseArea {
                        id: resizeHandle
                        objectName: "macColumnHandle-" + column.modelData.parentId
                        anchors {
                            right: parent.right
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: 7
                        cursorShape: Qt.SplitHCursor
                        hoverEnabled: true
                        preventStealing: true
                        property real pressRootX: 0
                        property real startingWidth: 0
                        onPressed: function(mouse) {
                            pressRootX = mapToItem(root, mouse.x, mouse.y).x;
                            startingWidth = column.width;
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                const rootX = mapToItem(root, mouse.x, mouse.y).x;
                                root.resizeColumn(column.modelData.parentId, startingWidth + rootX - pressRootX);
                            }
                        }
                        Rectangle {
                            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                            width: resizeHandle.pressed || resizeHandle.containsMouse ? 2 : 1
                            color: resizeHandle.pressed || resizeHandle.containsMouse ? Theme.accent : Theme.border
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        id: breadcrumbs
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: root.showBreadcrumbs ? 32 : 0
        visible: root.showBreadcrumbs
        color: Theme.toolbar
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }
        Flickable {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            contentWidth: pathRow.width
            contentHeight: height
            clip: true
            Row {
                id: pathRow
                height: parent.height
                spacing: 3
                Repeater {
                    model: root.selectedPath
                    delegate: Basic.Button {
                        id: pathButton
                        required property var modelData
                        required property int index
                        height: pathRow.height
                        leftPadding: 4
                        rightPadding: 4
                        text: (index ? "›  " : "") + modelData.title
                        font.pixelSize: 11
                        background: Rectangle {
                            color: pathButton.hovered ? Theme.hover : "transparent"
                            radius: 4
                        }
                        contentItem: Text {
                            text: pathButton.text
                            color: Theme.secondary
                            font: pathButton.font
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: root.selectionRequested(modelData.itemId)
                    }
                }
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
        radius: 5
        z: 10
    }
}
