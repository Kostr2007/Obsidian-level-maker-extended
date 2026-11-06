// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../ResourceAssets.js" as Resources

ColumnLayout {
    id: gallery
    required property var tokens
    required property var entries
    property string selectedId: "ammo"
    property string viewMode: "grid"
    property bool compatible: true
    property string selectedModule: "ui_pickups"
    signal select(string id, bool openPanel)
    signal revealItem(var item)
    readonly property int columns: viewMode === "list" ? 1 : Math.max(2, Math.floor(width / 190))
    objectName: "resourceGallery"
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 20
    function focusSelection() {
        for (let i = 0; i < cards.count; i++) {
            let item = cards.itemAt(i);
            if (item && item.modelData.id === selectedId) {
                item.forceActiveFocus();
                revealItem(item);
                return;
            }
        }
    }
    function navigate(index, delta) {
        let i = Math.max(0, Math.min(entries.length - 1, index + delta));
        if (entries[i]) {
            select(entries[i].id, false);
            Qt.callLater(focusSelection);
        }
    }
    GridLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        columns: gallery.columns
        columnSpacing: 16
        rowSpacing: gallery.viewMode === "list" ? 4 : 20
        Repeater {
            id: cards
            model: gallery.entries
            Button {
                id: card
                required property var modelData
                required property int index
                readonly property bool chosen: gallery.selectedId === modelData.id
                readonly property var examples: gallery.compatible ? Resources.forOption(modelData.id) : []
                property string hero: ({
                        ammo: "ammo_box.png",
                        health: "medikit.png",
                        items: "blue_armor.png",
                        weapons: "shotgun.png",
                        secrets_bonus: "soul_bonus.png"
                    })[modelData.id] || ""
                objectName: "resourceCard_" + modelData.id
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: gallery.viewMode === "list" ? Math.round(64 * gallery.tokens.textScale) : Math.round(184 * gallery.tokens.textScale)
                padding: 8
                hoverEnabled: true
                Accessible.name: modelData.title
                Accessible.description: (chosen ? "Выбрана. " : "") + "Выбрать категорию и показать её настройку"
                onActiveFocusChanged: if (activeFocus)
                    gallery.revealItem(card)
                onClicked: gallery.select(modelData.id, false)
                Keys.onRightPressed: gallery.navigate(index, 1)
                Keys.onLeftPressed: gallery.navigate(index, -1)
                Keys.onDownPressed: gallery.navigate(index, gallery.columns)
                Keys.onUpPressed: gallery.navigate(index, -gallery.columns)
                Keys.onReturnPressed: gallery.select(modelData.id, true)
                Keys.onEnterPressed: gallery.select(modelData.id, true)
                scale: down ? .97 : hovered ? 1.025 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: gallery.tokens.reduceMotion ? 0 : 150
                        easing.type: Easing.OutCubic
                    }
                }
                background: Rectangle {
                    radius: 10
                    color: card.chosen ? gallery.tokens.thumbnailSelected : card.hovered ? gallery.tokens.hover : "transparent"
                    border.width: card.visualFocus ? 2 : 0
                    border.color: gallery.tokens.accent
                    Behavior on color {
                        ColorAnimation {
                            duration: gallery.tokens.reduceMotion ? 0 : 130
                        }
                    }
                }
                contentItem: Item {
                    Rectangle {
                        id: thumbnail
                        width: gallery.viewMode === "list" ? 80 : parent.width
                        height: gallery.viewMode === "list" ? Math.round(48 * gallery.tokens.textScale) : 112
                        anchors.top: parent.top
                        radius: 8
                        color: gallery.tokens.thumbnail
                        Image {
                            objectName: "resourceThumbnail_" + card.modelData.id
                            visible: card.examples.length > 0 && !!card.hero
                            anchors.centerIn: parent
                            width: Math.min(parent.width - 20, 96)
                            height: parent.height - 18
                            source: visible ? Resources.image(card.hero) : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                        PreviewIcon {
                            visible: !card.examples.length
                            anchors.centerIn: parent
                            name: "folder"
                            ink: "#46a6ee"
                            width: gallery.viewMode === "list" ? 44 : 64
                            height: gallery.viewMode === "list" ? 40 : 56
                        }
                    }
                    ColumnLayout {
                        anchors.left: gallery.viewMode === "list" ? thumbnail.right : parent.left
                        anchors.right: parent.right
                        anchors.top: gallery.viewMode === "list" ? parent.top : thumbnail.bottom
                        anchors.leftMargin: gallery.viewMode === "list" ? 16 : 0
                        anchors.topMargin: gallery.viewMode === "list" ? 8 : 8
                        spacing: 4
                        Label {
                            text: card.modelData.title
                            Layout.alignment: gallery.viewMode === "list" ? Qt.AlignLeft : Qt.AlignHCenter
                            Layout.maximumWidth: parent.width
                            color: card.chosen ? gallery.tokens.accentText : gallery.tokens.text
                            font: gallery.tokens.bodyFont
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            leftPadding: 6
                            rightPadding: 6
                            topPadding: 3
                            bottomPadding: 3
                            background: Rectangle {
                                radius: 4
                                color: card.chosen ? gallery.tokens.accent : "transparent"
                            }
                        }
                        Label {
                            text: {
                                backend.revision;
                                let value = backend.value(gallery.selectedModule, card.modelData.id);
                                for (let c of card.modelData.choices || [])
                                    if (c.id === value)
                                        return c.text;
                                return value;
                            }
                            Layout.fillWidth: true
                            horizontalAlignment: gallery.viewMode === "list" ? Text.AlignLeft : Text.AlignHCenter
                            font: gallery.tokens.captionFont
                            color: gallery.tokens.secondary
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
    Label {
        visible: !gallery.compatible
        text: "Игровые миниатюры Freedoom доступны для семейства Doom. Параметры выбранной игры остаются доступны ниже."
        font: gallery.tokens.captionFont
        color: gallery.tokens.secondary
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
