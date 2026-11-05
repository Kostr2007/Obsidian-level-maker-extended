// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: row
    required property var tokens
    required property var option
    required property string moduleId
    property bool selected: false
    property string value: {
        backend.revision;
        return backend.value(moduleId, option.id);
    }
    property bool numeric: value !== "" && isFinite(Number(value))
    signal inspect(bool openPanel)
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 0
    function choiceIndex(items, value) {
        for (let i = 0; i < items.length; i++)
            if (String(items[i].id) === value)
                return i;
        return -1;
    }
    RowLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.margins: 16
        spacing: 16
        Label {
            text: row.option.title
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 160
            wrapMode: Text.WordWrap
            font.pixelSize: row.tokens.bodySize
            color: row.tokens.text
        }
        ColumnLayout {
            Layout.preferredWidth: 250
            Layout.maximumWidth: 280
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 6
            ComboBox {
                visible: row.option.kind === "choice"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: 32
                model: row.option.choices
                textRole: "text"
                valueRole: "id"
                currentIndex: row.choiceIndex(row.option.choices, row.value)
                font.pixelSize: row.tokens.bodySize
                Accessible.name: row.option.title
                onActiveFocusChanged: if (activeFocus)
                    row.inspect(false)
                onActivated: {
                    row.inspect(false);
                    backend.setOption(row.moduleId, row.option.id, currentValue);
                }
                background: Rectangle {
                    radius: 6
                    color: row.tokens.surface
                    border.color: parent.visualFocus ? row.tokens.accent : row.tokens.line
                    border.width: parent.visualFocus ? 2 : 1
                }
            }
            Switch {
                id: toggle
                implicitWidth: 38
                indicator: Rectangle {
                    implicitWidth: 34
                    implicitHeight: 20
                    x: toggle.width - width
                    y: (toggle.height - height) / 2
                    radius: 10
                    color: toggle.checked ? row.tokens.accent : row.tokens.dark ? "#66666e" : "#bdbdc5"
                    border.width: toggle.visualFocus ? 2 : 1
                    border.color: toggle.checked || toggle.visualFocus ? row.tokens.accent : row.tokens.secondary
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        x: toggle.checked ? 16 : 2
                        y: 2
                        color: "#ffffff"
                    }
                }
                visible: row.option.kind === "boolean"
                Layout.alignment: Qt.AlignRight
                checked: row.value === "1"
                Accessible.name: row.option.title
                onActiveFocusChanged: if (activeFocus)
                    row.inspect(false)
                onToggled: {
                    row.inspect(false);
                    backend.setOption(row.moduleId, row.option.id, checked ? "1" : "0");
                }
            }
            ComboBox {
                visible: row.option.kind === "slider" && row.option.nan.length > 0
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: 30
                model: ["Числовое значение"].concat(row.option.nan)
                currentIndex: row.numeric ? 0 : row.option.nan.indexOf(row.value) + 1
                Accessible.name: row.option.title + ": режим"
                font.pixelSize: row.tokens.bodySize
                onActiveFocusChanged: if (activeFocus)
                    row.inspect(false)
                onActivated: {
                    row.inspect(false);
                    backend.setOption(row.moduleId, row.option.id, currentIndex === 0 ? String(row.option.min) : currentText);
                }
                background: Rectangle {
                    radius: 6
                    color: row.tokens.surface
                    border.color: parent.visualFocus ? row.tokens.accent : row.tokens.line
                    border.width: parent.visualFocus ? 2 : 1
                }
            }
            RowLayout {
                visible: row.option.kind === "slider"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 12
                Slider {
                    id: level
                    background: Rectangle {
                        x: level.leftPadding
                        y: level.topPadding + level.availableHeight / 2 - height / 2
                        width: level.availableWidth
                        height: 4
                        radius: 2
                        color: row.tokens.line
                        Rectangle {
                            width: level.visualPosition * parent.width
                            height: parent.height
                            radius: 2
                            color: row.tokens.accent
                        }
                    }
                    handle: Rectangle {
                        x: level.leftPadding + level.visualPosition * (level.availableWidth - width)
                        y: level.topPadding + level.availableHeight / 2 - height / 2
                        implicitWidth: 15
                        implicitHeight: 15
                        radius: 8
                        color: row.tokens.surface
                        border.color: level.visualFocus ? row.tokens.accent : row.tokens.dark ? "#a8a8b0" : "#a3a3ae"
                        border.width: level.visualFocus ? 2 : 1
                    }
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    from: row.option.min || 0
                    to: row.option.max || 1
                    stepSize: row.option.step || 1
                    value: row.numeric ? Number(row.value) : from
                    enabled: row.numeric
                    Accessible.name: row.option.title
                    onActiveFocusChanged: if (activeFocus)
                        row.inspect(false)
                    onMoved: {
                        row.inspect(false);
                        backend.setOption(row.moduleId, row.option.id, String(Number(value.toFixed(6))));
                    }
                }
                TextField {
                    Layout.preferredWidth: 58
                    implicitHeight: 30
                    text: row.value
                    selectByMouse: true
                    enabled: row.numeric
                    horizontalAlignment: Text.AlignHCenter
                    Accessible.name: row.option.title + ": точное значение"
                    font.pixelSize: row.tokens.bodySize
                    validator: DoubleValidator {
                        bottom: row.option.min || 0
                        top: row.option.max || 1
                        locale: "C"
                    }
                    onActiveFocusChanged: if (activeFocus)
                        row.inspect(false)
                    onEditingFinished: {
                        if (acceptableInput)
                            backend.setOption(row.moduleId, row.option.id, text);
                        else
                            text = row.value;
                    }
                    background: Rectangle {
                        radius: 5
                        color: row.tokens.canvas
                        border.color: parent.activeFocus ? row.tokens.accent : row.tokens.line
                        border.width: parent.activeFocus ? 2 : 1
                    }
                }
            }
        }
        ToolButton {
            text: "?"
            implicitWidth: 26
            Accessible.name: "Пояснение: " + row.option.title
            onClicked: row.inspect(true)
            ToolTip.visible: hovered
            ToolTip.text: "Объяснение параметра"
        }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        implicitHeight: 1
        color: row.tokens.line
        opacity: .65
    }
}
