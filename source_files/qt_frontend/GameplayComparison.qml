// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "prototype"

ColumnLayout {
    id: comparison
    property string example: ""
    property var tokens: null
    readonly property font captionFont: tokens ? tokens.captionFont : Qt.font({
        family: Qt.application.font.family,
        pixelSize: 12
    })
    readonly property font bodyFont: tokens ? tokens.bodyFont : Qt.application.font
    readonly property font sectionFont: tokens ? tokens.sectionFont : Qt.font({
        family: Qt.application.font.family,
        pixelSize: 13,
        weight: Font.DemiBold
    })
    readonly property var captions: ({
            lighting: ["Темнее", "Светлее"],
            steepness: ["Плавные перепады", "Выраженные перепады"],
            monsters: ["Меньше противников", "Больше противников"]
        })
    readonly property bool supported: ["lighting", "steepness", "monsters"].includes(example)
    objectName: "gameplayComparison"
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 8
    function imageUrl(index) {
        return supported ? "qrc:/gameplay/" + example + (index ? "-high.png" : "-low.png") : "";
    }
    function caption(index) {
        return supported ? captions[example][index] : "";
    }
    function enlarge() {
        if (supported)
            enlarged.open();
    }
    Repeater {
        model: comparison.supported ? 2 : 0
        ColumnLayout {
            required property int index
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 4
            Label {
                text: comparison.caption(index)
                font: comparison.captionFont
                color: comparison.tokens ? comparison.tokens.text : palette.text
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
            Button {
                id: thumbnail
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: width * 9 / 16
                padding: 0
                Accessible.name: "Увеличить: " + comparison.caption(index)
                onClicked: comparison.enlarge()
                contentItem: Image {
                    objectName: "comparisonThumbnail" + index
                    source: comparison.imageUrl(index)
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    cache: true
                }
                PreviewToolTip {
                    tokens: comparison.tokens
                    visible: thumbnail.hovered
                    text: "Открыть сравнение крупнее"
                }
            }
        }
    }
    Button {
        id: enlargeButton
        font: comparison.bodyFont
        implicitHeight: comparison.tokens ? comparison.tokens.controlHeight : 30
        leftPadding: 12
        rightPadding: 12
        contentItem: Text {
            text: enlargeButton.text
            font: enlargeButton.font
            color: comparison.tokens ? comparison.tokens.text : enlargeButton.palette.buttonText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 6
            color: comparison.tokens ? (enlargeButton.hovered ? comparison.tokens.hover : comparison.tokens.surface) : enlargeButton.palette.base
            border.width: enlargeButton.visualFocus ? 2 : 1
            border.color: comparison.tokens ? (enlargeButton.visualFocus ? comparison.tokens.accent : comparison.tokens.line) : enlargeButton.palette.mid
        }
        text: "Сравнить крупнее"
        visible: comparison.supported
        Layout.fillWidth: true
        onClicked: comparison.enlarge()
    }
    Label {
        text: "UZDoom · Freedoom\nТестовая сцена, не прогноз вашей карты."
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font: comparison.captionFont
        color: comparison.tokens ? comparison.tokens.secondary : palette.text
        opacity: comparison.tokens ? 1 : .65
    }
    PreviewDialog {
        id: enlarged
        tokens: comparison.tokens
        objectName: "comparisonDialog"
        title: comparison.example === "lighting" ? "Освещение" : comparison.example === "steepness" ? "Перепады высоты" : "Количество монстров"
        parent: comparison.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(1180, parent ? parent.width - 40 : 900)
        height: Math.min(implicitHeight, parent ? parent.height - 40 : 600)
        modal: true
        standardButtons: Dialog.Close
        contentItem: ScrollView {
            id: largeScroll
            implicitHeight: largeContent.implicitHeight
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.active: true
            ColumnLayout {
                id: largeContent
                width: largeScroll.availableWidth
                spacing: 16
                Label {
                    text: "Одинаковая камера и настройки отображения. Меняется один параметр сцены."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    font: comparison.bodyFont
                    color: comparison.tokens ? comparison.tokens.text : palette.text
                }
                Flow {
                    id: picturePairs
                    objectName: "comparisonPairs"
                    // A stable pair and positioner avoid reentrant GridLayout
                    // column changes when a hidden Popup follows a Qt 6.4 window resize.
                    readonly property int columns: enlarged.availableWidth >= 900 ? 2 : 1
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: childrenRect.height
                    spacing: 16
                    Repeater {
                        model: 2
                        Column {
                            required property int index
                            width: Math.max(0, (picturePairs.width - (picturePairs.columns - 1) * picturePairs.spacing) / picturePairs.columns)
                            spacing: 8
                            Label {
                                text: comparison.caption(index)
                                font: comparison.sectionFont
                                color: comparison.tokens ? comparison.tokens.text : palette.text
                                width: parent.width
                                wrapMode: Text.WordWrap
                            }
                            Image {
                                objectName: "comparisonFullImage" + index
                                source: comparison.imageUrl(index)
                                width: parent.width
                                height: width * 9 / 16
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }
                        }
                    }
                }
                Label {
                    text: "Снято в UZDoom 5.0.3 с материалами Freedoom 0.13.0. Это подготовленные вручную примеры принципа. Проходимость и конкретный результат генератора этими снимками не проверяются.\nFreedoom: © 2001–2024 Contributors to the Freedoom project, BSD-3-Clause. Уведомления сохранены в docs/artwork/gameplay/FREEDOOM-COPYRIGHT.txt."
                    font: comparison.captionFont
                    color: comparison.tokens ? comparison.tokens.secondary : palette.text
                    opacity: comparison.tokens ? 1 : .7
                    Layout.minimumWidth: 0
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
