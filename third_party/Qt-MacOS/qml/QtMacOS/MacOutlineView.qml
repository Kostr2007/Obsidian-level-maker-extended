pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import QtQuick.Controls.Basic as Basic
import QtMacOS

// A genuine hierarchical TreeView: expansion lives in the view, identity in the model.
Item {
    id: root
    property var model: null
    property string selectedId: ""
    signal selectionRequested(string itemId)
    implicitWidth: 500
    implicitHeight: 350
    readonly property alias view: tree
    property var _expandedBeforeReset: []
    property bool _restorePending: false

    function idForIndex(index) {
        if (!index.valid || !model || typeof model.itemIdForIndex !== "function")
            return "";
        return model.itemIdForIndex(index);
    }

    function selectIndex(index) {
        if (!index.valid)
            return;
        const id = idForIndex(index);
        if (id.length)
            selectionRequested(id);
        selection.setCurrentIndex(index, ItemSelectionModel.NoUpdate);
        tree.forceActiveFocus();
    }

    function selectRow(row) {
        if (row >= 0 && row < tree.rows) {
            selectIndex(root.indexAt(row, 0));
            tree.positionViewAtRow(row, TableView.Contain);
        }
    }

    function indexAt(row, column) {
        // index() is the current API; retain a fallback for older Qt 6 versions.
        return typeof tree.index === "function" ? tree.index(row, column) : tree.modelIndex(row, column);
    }
    function scrollSelectionIntoView() {
        if (!tree || !model || !selectedId.length || typeof model.indexForId !== "function")
            return;
        const current = model.indexForId(selectedId);
        if (!current.valid)
            return;
        const cell = tree.cellAtIndex(current);
        if (cell.y >= 0)
            tree.positionViewAtRow(cell.y, TableView.Contain);
    }
    function syncSelection() {
        if (!tree || !model || !selectedId.length || typeof model.indexForId !== "function")
            return;
        const current = model.indexForId(selectedId);
        if (!current.valid)
            return;
        tree.expandToIndex(current);
        selection.setCurrentIndex(current, ItemSelectionModel.NoUpdate);
        // Resolve a fresh index when this runs; resets invalidate QModelIndex values.
        Qt.callLater(scrollSelectionIntoView);
    }

    function captureExpansion() {
        // IDs survive model resets; row numbers and QModelIndex values do not.
        // Merge pending snapshots when several mutations happen in one event turn.
        const ids = _restorePending ? _expandedBeforeReset.slice() : [];
        for (let row = 0; row < tree.rows; ++row) {
            if (!tree.isExpanded(row))
                continue;
            const id = idForIndex(root.indexAt(row, 0));
            if (id.length && ids.indexOf(id) < 0)
                ids.push(id);
        }
        _expandedBeforeReset = ids;
        _restorePending = true;
    }

    function restoreExpansion() {
        if (_restorePending && model && typeof model.indexForId === "function") {
            // Snapshot order is the visible preorder, so parents precede children.
            for (let i = 0; i < _expandedBeforeReset.length; ++i) {
                const index = model.indexForId(_expandedBeforeReset[i]);
                if (!index.valid)
                    continue;
                tree.expandToIndex(index);
                const cell = tree.cellAtIndex(index);
                if (cell.y >= 0)
                    tree.expand(cell.y);
            }
        }
        _expandedBeforeReset = [];
        _restorePending = false;
        syncSelection();
    }

    function collapseRow(row) {
        if (row < 0 || row >= tree.rows)
            return;
        const index = root.indexAt(row, 0);
        // If the selected item is being hidden, move selection and keyboard focus
        // to the collapsing ancestor before removing the descendant delegates.
        if (model && selectedId.length && typeof model.indexForId === "function") {
            let ancestor = model.indexForId(selectedId).parent;
            while (ancestor.valid) {
                if (idForIndex(ancestor) === idForIndex(index)) {
                    selectIndex(index);
                    break;
                }
                ancestor = ancestor.parent;
            }
        }
        tree.collapse(row);
        tree.forceActiveFocus();
    }

    function expandAll() {
        tree.expandRecursively();
    }
    function collapseAll() {
        if (selection.currentIndex.valid) {
            let ancestor = selection.currentIndex;
            while (ancestor.parent.valid)
                ancestor = ancestor.parent;
            selectIndex(ancestor);
        }
        tree.collapseRecursively();
    }

    onSelectedIdChanged: Qt.callLater(syncSelection)
    onModelChanged: {
        _expandedBeforeReset = [];
        _restorePending = false;
        Qt.callLater(syncSelection);
    }
    Component.onCompleted: Qt.callLater(syncSelection)
    Connections {
        target: root.model
        ignoreUnknownSignals: true
        function onModelAboutToBeReset() {
            root.captureExpansion();
        }
        function onModelReset() {
            Qt.callLater(root.restoreExpansion);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.content
    }
    ItemSelectionModel {
        id: selection
        model: root.model
    }
    TreeView {
        id: tree
        anchors {
            fill: parent
            margins: 6
        }
        clip: true
        model: root.model
        selectionModel: selection
        reuseItems: true
        keyNavigationEnabled: false
        activeFocusOnTab: true
        columnWidthProvider: function (column) {
            return column === 0 ? tree.width : 0;
        }
        rowHeightProvider: function (row) {
            return 32;
        }
        Basic.ScrollBar.vertical: MacScrollBar {}
        Keys.onUpPressed: root.selectRow(Math.max(0, currentRow - 1))
        Keys.onDownPressed: root.selectRow(Math.min(rows - 1, currentRow + 1))
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Home) {
                root.selectRow(0);
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                root.selectRow(tree.rows - 1);
                event.accepted = true;
            }
        }
        Keys.onLeftPressed: {
            if (currentRow < 0)
                return;
            if (isExpanded(currentRow))
                root.collapseRow(currentRow);
            else
                root.selectIndex(root.indexAt(currentRow, 0).parent);
        }
        Keys.onRightPressed: {
            if (currentRow < 0)
                root.selectRow(0);
            else if (!isExpanded(currentRow))
                expand(currentRow);
            else if (currentRow + 1 < rows && depth(currentRow + 1) > depth(currentRow))
                root.selectRow(currentRow + 1);
        }
        delegate: Basic.ItemDelegate {
            id: entry
            required property int row
            required property int column
            required property int depth
            required property bool expanded
            required property bool hasChildren
            required property string itemId
            required property string title
            required property string subtitle
            required property string kind
            required property color tint
            readonly property bool chosen: itemId === root.selectedId
            implicitWidth: tree.width
            implicitHeight: 32
            leftPadding: 8 + depth * 20
            rightPadding: 10
            hoverEnabled: true
            activeFocusOnTab: false
            Accessible.name: title
            Accessible.role: Accessible.TreeItem
            Accessible.selected: chosen
            Accessible.description: hasChildren ? (expanded ? qsTr("Expanded") : qsTr("Collapsed")) : subtitle
            background: Rectangle {
                anchors {
                    fill: parent
                    topMargin: 1
                    bottomMargin: 1
                }
                radius: 5
                color: entry.chosen ? Theme.accent : entry.hovered ? Theme.hover : entry.row % 2 ? Theme.dark ? "#ffffff05" : "#00000003" : "transparent"
                border.width: entry.chosen && tree.activeFocus ? 1 : 0
                border.color: Qt.lighter(Theme.accent, 1.3)
            }
            contentItem: Row {
                spacing: 6
                Basic.ToolButton {
                    id: disclosure
                    width: 18
                    height: 24
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: entry.hasChildren
                    opacity: entry.hasChildren ? 1 : 0
                    activeFocusOnTab: false
                    Accessible.name: entry.expanded ? qsTr("Collapse %1").arg(entry.title) : qsTr("Expand %1").arg(entry.title)
                    background: Rectangle {
                        radius: 4
                        color: disclosure.hovered ? Theme.hover : "transparent"
                    }
                    contentItem: Text {
                        text: "›"
                        rotation: entry.expanded ? 90 : 0
                        font.pixelSize: 21
                        color: entry.chosen ? Theme.accentText : Theme.secondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (entry.expanded)
                            root.collapseRow(entry.row);
                        else
                            tree.expand(entry.row);
                    }
                }
                Item {
                    width: 19
                    height: 22
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        x: 0
                        y: 3
                        width: 8
                        height: 5
                        radius: 1
                        visible: entry.hasChildren
                        color: entry.chosen ? "#c5e6ff" : entry.tint
                    }
                    Rectangle {
                        x: 0
                        y: entry.hasChildren ? 6 : 2
                        width: entry.hasChildren ? 18 : 14
                        height: entry.hasChildren ? 13 : 18
                        radius: 2
                        color: entry.chosen ? "#c5e6ff" : entry.tint
                        opacity: entry.hasChildren ? 1 : 0.65
                    }
                }
                Text {
                    width: Math.max(0, entry.availableWidth - 210)
                    height: parent.height
                    text: entry.title
                    font.pixelSize: 13
                    color: entry.chosen ? Theme.accentText : Theme.text
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                Text {
                    width: 154
                    height: parent.height
                    text: entry.subtitle
                    font.pixelSize: 11
                    color: entry.chosen ? Theme.accentText : Theme.secondary
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
            onClicked: {
                root.selectionRequested(itemId);
                selection.setCurrentIndex(root.indexAt(row, 0), ItemSelectionModel.NoUpdate);
                tree.forceActiveFocus();
            }
            onDoubleClicked: {
                if (hasChildren) {
                    if (expanded)
                        root.collapseRow(row);
                    else
                        tree.expand(row);
                }
            }
        }
    }
    Rectangle {
        anchors.fill: tree
        color: "transparent"
        border.width: tree.activeFocus ? 2 : 0
        border.color: Theme.accent
        radius: 5
        z: 10
    }
}
