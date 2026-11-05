// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: editor
    required property var option
    required property string moduleId
    signal explain(bool openPanel)
    property bool writable: true
    property string currentValue: {
        backend.revision;
        return backend.value(moduleId, option.id);
    }
    property bool numeric: currentValue !== "" && isFinite(Number(currentValue))
    Layout.fillWidth: true
    spacing: 4
    objectName: "option_" + moduleId + "_" + option.id
    function selectIndex(items, value) {
        for (let i = 0; i < items.length; ++i)
            if (String(items[i].id) === value)
                return i;
        return -1;
    }
    RowLayout {
        Layout.fillWidth: true
        Label {
            text: editor.option.title
            font.pixelSize: editor.option.kind === "header" ? 18 : 14
            font.weight: editor.option.kind === "header" ? Font.DemiBold : Font.Normal
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        ToolButton {
            visible: editor.option.kind !== "header"
            text: "↺"
            enabled: editor.writable
            implicitWidth: 36
            Accessible.name: "Сбросить: " + editor.option.title
            ToolTip.visible: hovered
            ToolTip.text: "По умолчанию: " + editor.option.default
            onClicked: backend.setOption(editor.moduleId, editor.option.id, editor.option.default)
        }
        ToolButton {
            visible: editor.option.kind !== "header"
            text: "?"
            implicitWidth: 36
            Accessible.name: "Справка: " + editor.option.title
            ToolTip.visible: hovered
            ToolTip.text: "Показать пояснение и пример"
            onClicked: editor.explain(true)
        }
    }
    ComboBox {
        visible: editor.option.kind === "choice"
        enabled: editor.writable
        Layout.preferredHeight: 32
        Layout.fillWidth: true
        model: editor.option.choices
        textRole: "text"
        valueRole: "id"
        currentIndex: editor.selectIndex(editor.option.choices, editor.currentValue)
        Accessible.name: editor.option.title
        onActiveFocusChanged: if (activeFocus)
            editor.explain(false)
        onActivated: backend.setOption(editor.moduleId, editor.option.id, currentValue)
    }
    Switch {
        visible: editor.option.kind === "boolean"
        enabled: editor.writable
        text: checked ? "Включено" : "Выключено"
        checked: editor.currentValue === "1"
        Accessible.name: editor.option.title
        onActiveFocusChanged: if (activeFocus)
            editor.explain(false)
        onToggled: backend.setOption(editor.moduleId, editor.option.id, checked ? "1" : "0")
    }
    ColumnLayout {
        visible: editor.option.kind === "slider"
        Layout.fillWidth: true
        ComboBox {
            visible: editor.option.nan.length > 0
            enabled: editor.writable
            Layout.preferredHeight: 32
            Layout.fillWidth: true
            model: ["Числовое значение"].concat(editor.option.nan)
            currentIndex: editor.numeric ? 0 : editor.option.nan.indexOf(editor.currentValue) + 1
            Accessible.name: editor.option.title + ": режим значения"
            onActiveFocusChanged: if (activeFocus)
                editor.explain(false)
            onActivated: backend.setOption(editor.moduleId, editor.option.id, currentIndex === 0 ? String(editor.option.min) : currentText)
        }
        RowLayout {
            Layout.fillWidth: true
            Slider {
                Layout.fillWidth: true
                from: editor.option.min || 0
                to: editor.option.max || 1
                stepSize: editor.option.step || 1
                value: editor.numeric ? Number(editor.currentValue) : from
                enabled: editor.numeric && editor.writable
                Accessible.name: editor.option.title
                onActiveFocusChanged: if (activeFocus)
                    editor.explain(false)
                onMoved: backend.setOption(editor.moduleId, editor.option.id, String(Number(value.toFixed(6))))
            }
            TextField {
                Layout.preferredWidth: 94
                enabled: editor.numeric && editor.writable
                text: editor.numeric ? editor.currentValue : "—"
                selectByMouse: true
                Accessible.name: editor.option.title + ": точное значение"
                validator: DoubleValidator {
                    bottom: editor.option.min || 0
                    top: editor.option.max || 1
                    locale: "C"
                    notation: DoubleValidator.StandardNotation
                }
                onActiveFocusChanged: if (activeFocus)
                    editor.explain(false)
                onEditingFinished: {
                    if (acceptableInput)
                        backend.setOption(editor.moduleId, editor.option.id, text);
                    else
                        text = editor.currentValue;
                }
            }
            Label {
                text: editor.option.units || ""
                visible: text.length > 0
            }
        }
    }
}
