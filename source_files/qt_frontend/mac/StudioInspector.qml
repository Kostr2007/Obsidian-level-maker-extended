// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtMacOS
import QtQuick.Layouts
import Obsidian 1.0

ScrollView {
    id: inspector
    objectName: "qtMacOSParameterInspector"
    readonly property bool qtMacOSLayoutPilot: true
    property var option: null
    property string moduleId: ""
    property string moduleTitle: ""
    property bool showPreview: true
    rightPadding: 12
    contentWidth: availableWidth
    clip: true
    ScrollBar.vertical.active: true
    onOptionChanged: {
        details.expanded = false;
        if (contentItem)
            contentItem.contentY = 0;
    }
    ColumnLayout {
        width: inspector.availableWidth
        spacing: 16
        MacLabel {
            text: "ПОЯСНЕНИЕ ПАРАМЕТРА"
            role: MacLabel.Caption
            font.letterSpacing: 1.4
            Layout.fillWidth: true
        }
        MacLabel {
            objectName: "inspectorTitle"
            text: inspector.option ? inspector.option.title : "Настраивайте осознанно"
            role: MacLabel.Title
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        MacLabel {
            text: inspector.moduleTitle
            visible: text.length > 0
            role: MacLabel.Secondary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        AssetPreview {
            optionId: inspector.moduleId === "ui_pickups" && inspector.option ? inspector.option.id : ""
            visible: available
        }
        GameplayComparison {
            example: inspector.option ? inspector.option.comparison : ""
            visible: supported
        }
        MacLabel {
            text: inspector.option ? (inspector.option.summary || "Подробности этого параметра приведены в справке генератора ниже.") : "Выберите параметр кнопкой «?» или перейдите к его полю с клавиатуры. Здесь появятся объяснение и пример."
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            lineHeight: 1.2
        }

        MacLabel {
            text: inspector.option ? inspector.option.related : ""
            visible: text.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            role: MacLabel.Secondary
        }
        MacBox {
            objectName: "inspectorValueGroup"
            visible: !!inspector.option
            Layout.fillWidth: true
            title: "Значение параметра"
            padding: 12
            spacing: 8
            MacLabel {
                width: parent.width
                text: "Текущее значение"
                role: MacLabel.Caption
            }
            MacLabel {
                objectName: "inspectorCurrentValue"
                width: parent.width
                role: MacLabel.Heading
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
            }
            MacLabel {
                width: parent.width
                text: inspector.option ? "По умолчанию: " + inspector.option.default : ""
                role: MacLabel.Caption
            }
        }
        MacDisclosureGroup {
            id: details
            objectName: "inspectorGeneratorHelp"
            visible: !!inspector.option && inspector.option.tooltip.length > 0
            title: "Справка генератора"
            Layout.fillWidth: true
            MacLabel {
                objectName: "inspectorGeneratorHelpText"
                width: parent.width
                text: inspector.option ? inspector.option.tooltip : ""
                role: MacLabel.Secondary
            }
        }
        Rectangle {
            visible: inspector.showPreview
            Layout.fillWidth: true
            implicitHeight: 1
            color: backend.dark ? "#353d49" : "#d8dee7"
        }
        MacLabel {
            visible: inspector.showPreview
            text: "ПОСЛЕДНИЙ РЕЗУЛЬТАТ"
            role: MacLabel.Caption
            font.letterSpacing: 1.3
        }
        WadView {
            visible: inspector.showPreview
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            file: backend.previewFile
        }
        MacLabel {
            visible: inspector.showPreview
            text: "Геометрия созданного WAD. Изменение настроек её не обновляет."
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            role: MacLabel.Caption
        }
    }
}
