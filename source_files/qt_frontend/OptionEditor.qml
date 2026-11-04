// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ColumnLayout {
    id: editor
    required property var option
    required property string moduleId
    property string currentValue: { backend.revision; return backend.value(moduleId, option.id) }
    property bool numeric: currentValue !== "" && isFinite(Number(currentValue))
    Layout.fillWidth: true
    spacing: 2
    function selectIndex(items, value) {
        for (let i = 0; i < items.length; ++i) if (String(items[i].id) === value) return i
        return -1
    }
    RowLayout {
        Layout.fillWidth: true
        Label {
            text: editor.option.text
            font.pixelSize: editor.option.kind === "header" ? 18 : 14
            font.weight: editor.option.kind === "header" ? Font.DemiBold : Font.Normal
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        ToolButton {
            visible: editor.option.kind !== "header"
            text: "↺"
            implicitWidth: 36
            Accessible.name: "Сбросить: " + editor.option.text
            ToolTip.visible: hovered
            ToolTip.text: "По умолчанию: " + editor.option.default
            onClicked: backend.setOption(editor.moduleId, editor.option.id, editor.option.default)
        }
        ToolButton {
            visible: editor.option.tooltip.length > 0
            text: "?"
            implicitWidth: 36
            Accessible.name: "Справка: " + editor.option.text
            ToolTip.visible: hovered
            ToolTip.text: editor.option.tooltip
            onClicked: help.open()
        }
    }
    ComboBox {
        visible: editor.option.kind === "choice"
        Layout.fillWidth: true
        model: editor.option.choices
        textRole: "text"
        valueRole: "id"
        currentIndex: editor.selectIndex(editor.option.choices, editor.currentValue)
        Accessible.name: editor.option.text
        onActivated: backend.setOption(editor.moduleId, editor.option.id, currentValue)
    }
    Switch {
        visible: editor.option.kind === "boolean"
        text: checked ? "Включено" : "Выключено"
        checked: editor.currentValue === "1"
        Accessible.name: editor.option.text
        onToggled: backend.setOption(editor.moduleId, editor.option.id, checked ? "1" : "0")
    }
    ColumnLayout {
        visible: editor.option.kind === "slider"
        Layout.fillWidth: true
        ComboBox {
            visible: editor.option.nan.length > 0
            Layout.fillWidth: true
            model: ["Числовое значение"].concat(editor.option.nan)
            currentIndex: editor.numeric ? 0 : editor.option.nan.indexOf(editor.currentValue) + 1
            Accessible.name: editor.option.text + ": режим значения"
            onActivated: backend.setOption(editor.moduleId, editor.option.id,
                currentIndex === 0 ? String(editor.option.min) : currentText)
        }
        RowLayout {
            Layout.fillWidth: true
            Slider {
                Layout.fillWidth: true
                from: editor.option.min || 0
                to: editor.option.max || 1
                stepSize: editor.option.step || 1
                value: editor.numeric ? Number(editor.currentValue) : from
                enabled: editor.numeric
                Accessible.name: editor.option.text
                onMoved: backend.setOption(editor.moduleId, editor.option.id, String(Number(value.toFixed(6))))
            }
            TextField {
                Layout.preferredWidth: 94
                enabled: editor.numeric
                text: editor.numeric ? editor.currentValue : "—"
                selectByMouse: true
                Accessible.name: editor.option.text + ": точное значение"
                validator: DoubleValidator {
                    bottom: editor.option.min || 0
                    top: editor.option.max || 1
                    locale: "C"
                    notation: DoubleValidator.StandardNotation
                }
                onEditingFinished: {
                    if (acceptableInput) backend.setOption(editor.moduleId, editor.option.id, text)
                    else text = editor.currentValue
                }
            }
            Label { text: editor.option.units || ""; visible: text.length > 0 }
        }
    }
    Dialog {
        id: help
        title: editor.option.text
        modal: true
        Overlay.modal: Rectangle { color: "#99000000" }
        anchors.centerIn: Overlay.overlay
        width: Math.min(560, Overlay.overlay.width - 40)
        height: Math.min(460, Overlay.overlay.height - 48)
        standardButtons: Dialog.Ok
        background: Rectangle { radius: 18; color: backend.dark ? "#253238" : "#eef4f1" }
        contentItem: ScrollView {
            id: helpScroll
            implicitHeight: 320
            contentWidth: availableWidth
            clip: true
            Label {
                id: helpText
                width: helpScroll.availableWidth
                text: editor.option.tooltip
                wrapMode: Text.WordWrap
                padding: 16
            }
        }
    }
}
