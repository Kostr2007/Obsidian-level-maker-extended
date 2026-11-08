pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtMacOS

// Standard SplitView children and SplitView attached sizing properties remain public.
SplitView {
    id: root
    property real defaultMinimumPaneWidth: 120
    property real defaultMinimumPaneHeight: 96
    property var collapsedPanes: ({})
    signal paneCollapsedChanged(int index, bool collapsed)
    implicitWidth: 700
    implicitHeight: 360

    function applyMinimums() {
        for (let i = 0; i < count; ++i) {
            const pane = itemAt(i);
            if (pane.SplitView.minimumWidth === 0)
                pane.SplitView.minimumWidth = defaultMinimumPaneWidth;
            if (pane.SplitView.minimumHeight === 0)
                pane.SplitView.minimumHeight = defaultMinimumPaneHeight;
        }
    }

    function isPaneCollapsed(index) {
        return collapsedPanes[index] === true;
    }

    function setPaneCollapsed(index, collapsed) {
        if (index < 0 || index >= count || isPaneCollapsed(index) === collapsed)
            return;
        const pane = itemAt(index);
        let focusWasInside = false;
        if (collapsed && root.Window.window) {
            let focused = root.Window.window.activeFocusItem;
            while (focused) {
                if (focused === pane) {
                    focusWasInside = true;
                    break;
                }
                focused = focused.parent;
            }
        }
        pane.visible = !collapsed;
        if (focusWasInside) {
            let target = null;
            for (let i = 0; i < count; ++i) {
                if (i !== index && itemAt(i).visible) {
                    target = itemAt(i);
                    break;
                }
            }
            if (target)
                target.forceActiveFocus(Qt.OtherFocusReason);
            else
                root.forceActiveFocus(Qt.OtherFocusReason);
        }
        const updated = Object.assign({}, collapsedPanes);
        updated[index] = collapsed;
        collapsedPanes = updated;
        paneCollapsedChanged(index, collapsed);
    }

    function restorePane(index) {
        setPaneCollapsed(index, false);
    }
    onCountChanged: Qt.callLater(applyMinimums)
    Component.onCompleted: applyMinimums()
    handle: Rectangle {
        implicitWidth: root.orientation === Qt.Horizontal ? 6 : 24
        implicitHeight: root.orientation === Qt.Horizontal ? 24 : 6
        color: SplitHandle.pressed ? Theme.selection : SplitHandle.hovered ? Theme.hover : Theme.content
        Rectangle {
            anchors.centerIn: parent
            width: root.orientation === Qt.Horizontal ? 1 : parent.width
            height: root.orientation === Qt.Horizontal ? parent.height : 1
            color: Theme.border
        }
    }
}
