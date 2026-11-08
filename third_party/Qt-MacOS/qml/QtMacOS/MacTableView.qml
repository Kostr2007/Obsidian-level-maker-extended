pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

FocusScope {
    id: control
    implicitWidth: 620
    implicitHeight: 320
    property var model
    property string selectedId: ""
    property string emptyText: qsTr("No items")
    property var columnTitles: [qsTr("Title"), qsTr("Kind"), qsTr("Details")]
    property var columnWidths: [260, 140, 220]
    property var rowIdProvider: null
    property int sortColumn: -1
    property bool sortAscending: true
    readonly property int rowCount: table.rows
    readonly property int currentRow: state.currentRow
    readonly property int headerHeight: 32
    signal selectionRequested(string itemId)
    signal sortRequested(int column, bool ascending)

    function columnWidth(index) {
        return index < columnWidths.length ? columnWidths[index] : 160;
    }
    function columnOffset(index) {
        let offset = 0;
        for (let i = 0; i < index; ++i) offset += columnWidth(i);
        return offset;
    }
    function resizeColumn(index, width) {
        if (index < 0 || index >= columnTitles.length || !isFinite(width)) return;
        const widths = columnWidths.slice();
        widths[index] = Math.max(72, width);
        columnWidths = widths;
        table.forceLayout();
    }
    function requestSort(column) {
        sortAscending = sortColumn === column ? !sortAscending : true;
        sortColumn = column;
        sortRequested(column, sortAscending);
    }
    function itemIdAt(row) {
        // Callback validated with typeof above; QML has no function-valued property type.
        // qmllint disable use-proper-function
        if (typeof rowIdProvider === "function") return String(rowIdProvider(row));
        // qmllint enable use-proper-function
        if (model && typeof model.itemIdAt === "function") return String(model.itemIdAt(row));
        const cell = table.itemAtCell(Qt.point(0, row));
        return cell ? cell.stableId : "";
    }
    function selectRow(row) {
        if (table.rows === 0) return;
        state.currentRow = Math.max(0, Math.min(table.rows - 1, row));
        table.positionViewAtRow(state.currentRow, TableView.Contain);
        table.forceLayout();
        const id = itemIdAt(state.currentRow);
        if (id !== "") selectionRequested(id);
    }
    function synchronizeSelection() {
        for (let i = 0; i < table.rows; ++i) {
            if (itemIdAt(i) === selectedId) {
                state.currentRow = i;
                return;
            }
        }
        state.currentRow = -1;
    }
    onSelectedIdChanged: synchronizeSelection()
    onColumnWidthsChanged: table.forceLayout()
    Keys.onPressed: event => {
        synchronizeSelection();
        if (event.key === Qt.Key_Down) selectRow(state.currentRow + 1);
        else if (event.key === Qt.Key_Up) selectRow(state.currentRow - 1);
        else if (event.key === Qt.Key_Home) selectRow(0);
        else if (event.key === Qt.Key_End) selectRow(table.rows - 1);
        else return;
        event.accepted = true;
    }
    QtObject { id: state; property int currentRow: -1 }
    Rectangle { anchors.fill: parent; color: Theme.content }
    Item {
        id: header
        objectName: "macTableHeader"
        width: parent.width; height: control.headerHeight
        clip: true
        Rectangle { anchors.fill: parent; color: Theme.toolbar }
        Repeater {
            model: control.columnTitles.length
            delegate: Item {
                id: heading
                required property int index
                x: control.columnOffset(index) - table.contentX
                width: control.columnWidth(index)
                height: header.height
                Basic.AbstractButton {
                    id: headerButton
                    hoverEnabled: true
                    objectName: "macTableHeading" + heading.index
                    anchors.fill: parent
                    text: control.columnTitles[heading.index]
                    Accessible.name: text + (control.sortColumn === heading.index
                                             ? (control.sortAscending ? qsTr(", ascending") : qsTr(", descending")) : "")
                    onClicked: control.requestSort(heading.index)
                    contentItem: Text {
                        leftPadding: 12; rightPadding: 26
                        text: headerButton.text
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        color: Theme.secondary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                    background: Rectangle { color: headerButton.hovered ? Theme.hover : "transparent" }
                }
                Text {
                    anchors.right: parent.right; anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: control.sortColumn === heading.index
                    text: control.sortAscending ? "⌃" : "⌄"
                    color: Theme.secondary; font.pixelSize: 14
                }
                Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }
                MouseArea {
                    anchors.right: parent.right
                    width: 8; height: parent.height
                    cursorShape: Qt.SplitHCursor
                    property real startX
                    property real startWidth
                    onPressed: mouse => {
                        startX = mapToItem(control, mouse.x, mouse.y).x;
                        startWidth = control.columnWidth(heading.index);
                    }
                    onPositionChanged: mouse => {
                        if (pressed) control.resizeColumn(heading.index,
                            startWidth + mapToItem(control, mouse.x, mouse.y).x - startX);
                    }
                }
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }
    TableView {
        id: table
        objectName: "macTableContent"
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        clip: true
        model: control.model
        boundsBehavior: Flickable.StopAtBounds
        columnSpacing: 0
        rowSpacing: 0
        columnWidthProvider: column => control.columnWidth(column)
        rowHeightProvider: () => 36
        onRowsChanged: control.synchronizeSelection()
        Basic.ScrollBar.vertical: MacScrollBar {}
        Basic.ScrollBar.horizontal: MacScrollBar {}
        delegate: Rectangle {
            id: cell
            required property var model
            required property int row
            required property int column
            readonly property string stableId: model.itemId !== undefined ? String(model.itemId)
                                                     : (control.rowIdProvider ? String(control.rowIdProvider(row)) : String(row))
            readonly property bool selected: stableId === control.selectedId
            implicitWidth: control.columnWidth(column)
            implicitHeight: 36
            color: selected ? (control.activeFocus ? Theme.accent : Theme.selection)
                            : (row % 2 ? Theme.hover : Theme.content)
            Accessible.role: Accessible.ListItem
            Accessible.name: String(model.display === undefined ? "" : model.display)
            Accessible.selected: selected
            Accessible.onPressAction: {
                control.forceActiveFocus();
                state.currentRow = row;
                control.selectionRequested(stableId);
            }
            Text {
                anchors.fill: parent
                leftPadding: 12; rightPadding: 12
                text: cell.model.display === undefined ? "" : cell.model.display
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: cell.selected && control.activeFocus ? Theme.accentText
                                                           : (cell.column === 0 ? Theme.text : Theme.secondary)
                font.pixelSize: 13
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    control.forceActiveFocus();
                    state.currentRow = cell.row;
                    control.selectionRequested(cell.stableId);
                }
            }
        }
    }
    Text {
        anchors.centerIn: table
        visible: table.rows === 0
        text: control.emptyText
        color: Theme.secondary; font.pixelSize: 13
    }
}
