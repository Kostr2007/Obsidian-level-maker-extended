// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Obsidian 1.0

ScrollView {
    id: inspector
    property var option: null
    property string moduleId: ""
    property string moduleTitle: ""
    property bool showPreview: true
    contentWidth: availableWidth
    clip: true
    ScrollBar.vertical.active: true
    onOptionChanged: {
        details.checked = false;
        if (contentItem)
            contentItem.contentY = 0;
    }
    ColumnLayout {
        width: inspector.availableWidth
        spacing: 16
        Label {
            text: "ПОЯСНЕНИЕ ПАРАМЕТРА"
            font.pixelSize: 10
            font.letterSpacing: 1.4
            opacity: .65
            Layout.fillWidth: true
        }
        Label {
            objectName: "inspectorTitle"
            text: inspector.option ? inspector.option.title : "Настраивайте осознанно"
            font.pixelSize: 22
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Label {
            text: inspector.moduleTitle
            visible: text.length > 0
            opacity: .65
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        ParameterDiagram {
            kind: inspector.option ? inspector.option.diagram : ""
            visible: kind.length > 0
        }
        Label {
            text: inspector.option ? (inspector.option.summary || "Подробности этого параметра приведены в справке генератора ниже.") : "Выберите параметр кнопкой «?» или перейдите к его полю с клавиатуры. Здесь появятся объяснение и схема."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            lineHeight: 1.2
        }

        Label {
            text: inspector.option ? inspector.option.related : ""
            visible: text.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: .8
            font.pixelSize: 12
        }
        Surface {
            visible: !!inspector.option
            Layout.fillWidth: true
            padding: 12
            ColumnLayout {
                anchors.fill: parent
                Label {
                    text: "Текущее значение"
                    opacity: .6
                    font.pixelSize: 11
                }
                Label {
                    text: {
                        backend.revision;
                        if (!inspector.option)
                            return "";
                        let value = backend.value(inspector.moduleId, inspector.option.id);
                        let choices = inspector.option.choices || [];
                        for (let i = 0; i < choices.length; i++)
                            if (choices[i].id === value)
                                return choices[i].text;
                        return inspector.option.kind === "boolean" ? (value === "1" ? "Включено" : "Выключено") : value;
                    }
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Label {
                    text: inspector.option ? "По умолчанию: " + inspector.option.default : ""
                    opacity: .65
                    font.pixelSize: 11
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
        ToolButton {
            id: details
            visible: !!inspector.option && inspector.option.tooltip.length > 0
            text: checked ? "−  Справка генератора" : "+  Справка генератора"
            checkable: true
            Layout.fillWidth: true
        }
        Label {
            visible: details.checked
            text: inspector.option ? inspector.option.tooltip : ""
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            font.pixelSize: 12
        }
        Rectangle {
            visible: inspector.showPreview
            Layout.fillWidth: true
            implicitHeight: 1
            color: backend.dark ? "#353d49" : "#d8dee7"
        }
        Label {
            visible: inspector.showPreview
            text: "ПОСЛЕДНИЙ РЕЗУЛЬТАТ"
            font.pixelSize: 10
            font.letterSpacing: 1.3
            opacity: .65
        }
        WadView {
            visible: inspector.showPreview
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            file: backend.previewFile
        }
        Label {
            visible: inspector.showPreview
            text: "Геометрия созданного WAD. Изменение настроек её не обновляет."
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: 11
            opacity: .65
        }
    }
}
