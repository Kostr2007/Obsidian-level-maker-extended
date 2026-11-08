pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Basic
import QtMacOS

Item {
    id: root
    property var tabs: []
    property string currentKey: tabs.length ? tabs[0].key : ""
    // Delegate root may expose `property string pageKey` and `property var tabData`.
    // All pages load once and remain alive while their tab exists.
    property Component pageDelegate
    signal currentKeyRequested(string key)
    readonly property int currentIndex: indexForKey(currentKey)
    implicitWidth: 650
    implicitHeight: 350

    function indexForKey(key) {
        for (let i = 0; i < tabs.length; ++i) {
            if (tabs[i].key === key)
                return i;
        }
        return -1;
    }

    function pageAt(index) {
        const loader = pages.itemAt(index) as Loader;
        return loader ? loader.item : null;
    }

    function ensureTabVisible(index) {
        if (!buttons || !tabScroller)
            return;
        const button = buttons.itemAt(index);
        if (!button)
            return;
        const left = button.x;
        const right = left + button.width;
        if (left < tabScroller.contentX)
            tabScroller.contentX = left;
        else if (right > tabScroller.contentX + tabScroller.width)
            tabScroller.contentX = right - tabScroller.width;
    }

    onCurrentIndexChanged: Qt.callLater(function () {
        if (root)
            root.ensureTabVisible(root.currentIndex);
    })

    function requestAdjacent(index, step) {
        const next = (index + step + tabs.length) % tabs.length;
        if (tabs.length) {
            currentKeyRequested(tabs[next].key);
            const button = buttons.itemAt(next);
            if (button)
                button.forceActiveFocus();
            ensureTabVisible(next);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Math.min(root.width, tabRow.implicitWidth + 4)
            Layout.minimumWidth: 0
            implicitHeight: 30
            radius: 7
            color: Theme.dark ? "#212124" : "#e5e5e7"
            border.width: 1
            border.color: Theme.border
            Flickable {
                id: tabScroller
                anchors {
                    fill: parent
                    margins: 2
                }
                contentWidth: tabRow.width
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                onWidthChanged: Qt.callLater(function () {
                    if (root)
                        root.ensureTabVisible(root.currentIndex);
                })
                Row {
                    id: tabRow
                    Repeater {
                        id: buttons
                        model: root.tabs
                        delegate: Basic.Button {
                            id: tab
                            required property var modelData
                            required property int index
                            objectName: "macTab-" + modelData.key
                            readonly property bool selected: modelData.key === root.currentKey
                            height: 26
                            implicitWidth: Math.min(Math.max(1, root.width - 4), Math.max(90, implicitContentWidth + 28))
                            text: modelData.title
                            font.pixelSize: 13
                            activeFocusOnTab: true
                            onActiveFocusChanged: {
                                if (activeFocus)
                                    root.ensureTabVisible(index);
                            }
                            Accessible.role: Accessible.PageTab
                            Accessible.name: text
                            Accessible.selected: selected
                            background: Rectangle {
                                radius: 5
                                color: tab.selected ? Theme.dark ? "#626266" : "white" : tab.hovered ? Theme.hover : "transparent"
                                border.width: tab.activeFocus ? 2 : tab.selected ? 1 : 0
                                border.color: tab.activeFocus ? Theme.accent : Theme.dark ? "#77777b" : "#d0d0d3"
                            }
                            contentItem: Text {
                                text: tab.text
                                color: Theme.text
                                font: tab.font
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                forceActiveFocus();
                                root.currentKeyRequested(modelData.key);
                            }
                            Keys.onRightPressed: root.requestAdjacent(index, 1)
                            Keys.onLeftPressed: root.requestAdjacent(index, -1)
                            Keys.onPressed: function (event) {
                                if (event.key === Qt.Key_Home && root.tabs.length) {
                                    root.currentKeyRequested(root.tabs[0].key);
                                    const first = buttons.itemAt(0);
                                    if (first)
                                        first.forceActiveFocus();
                                    root.ensureTabVisible(0);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_End && root.tabs.length) {
                                    root.currentKeyRequested(root.tabs[root.tabs.length - 1].key);
                                    const last = buttons.itemAt(root.tabs.length - 1);
                                    if (last)
                                        last.forceActiveFocus();
                                    root.ensureTabVisible(root.tabs.length - 1);
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }
        }
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentIndex
            Repeater {
                id: pages
                model: root.tabs
                delegate: Loader {
                    id: page
                    required property var modelData
                    readonly property string pageKey: modelData.key
                    active: true
                    sourceComponent: root.pageDelegate
                    onLoaded: {
                        if (item && "pageKey" in item)
                            item.pageKey = pageKey;
                        if (item && "tabData" in item)
                            item.tabData = modelData;
                    }
                    onModelDataChanged: {
                        if (item && "pageKey" in item)
                            item.pageKey = pageKey;
                        if (item && "tabData" in item)
                            item.tabData = modelData;
                    }
                }
            }
        }
    }
}
