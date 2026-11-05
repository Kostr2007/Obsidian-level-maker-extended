// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: comparison
    property string example: ""
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
                font.pixelSize: 12
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
                ToolTip.visible: hovered
                ToolTip.text: "Открыть сравнение крупнее"
            }
        }
    }
    ActionButton {
        text: "Сравнить крупнее"
        visible: comparison.supported
        Layout.fillWidth: true
        onClicked: comparison.enlarge()
    }
    Label {
        text: "UZDoom · Freedoom\nТестовая сцена, не прогноз вашей карты."
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        font.pixelSize: 11
        opacity: .65
    }
    Dialog {
        id: enlarged
        objectName: "comparisonDialog"
        title: comparison.example === "lighting" ? "Освещение" : comparison.example === "steepness" ? "Перепады высоты" : "Количество монстров"
        parent: comparison.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(1180, parent ? parent.width - 40 : 900)
        height: Math.min(780, parent ? parent.height - 40 : 600)
        modal: true
        standardButtons: Dialog.Close
        contentItem: ScrollView {
            id: largeScroll
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.active: true
            ColumnLayout {
                width: largeScroll.availableWidth
                spacing: 16
                Label {
                    text: "Одинаковая камера и настройки отображения. Меняется один параметр сцены."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                GridLayout {
                    columns: width >= 900 ? 2 : 1
                    Layout.fillWidth: true
                    columnSpacing: 16
                    rowSpacing: 16
                    Repeater {
                        model: comparison.supported ? 2 : 0
                        ColumnLayout {
                            required property int index
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Label {
                                text: comparison.caption(index)
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Image {
                                source: comparison.imageUrl(index)
                                Layout.fillWidth: true
                                Layout.preferredHeight: width * 9 / 16
                                Layout.minimumWidth: 0
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                            }
                        }
                    }
                }
                Label {
                    text: "Снято в UZDoom 5.0.3 с материалами Freedoom 0.13.0. Это подготовленные вручную примеры принципа. Проходимость и конкретный результат генератора этими снимками не проверяются.\nFreedoom: © 2001–2024 Contributors to the Freedoom project, BSD-3-Clause. Уведомления сохранены в docs/artwork/gameplay/FREEDOOM-COPYRIGHT.txt."
                    font.pixelSize: 11
                    opacity: .7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
