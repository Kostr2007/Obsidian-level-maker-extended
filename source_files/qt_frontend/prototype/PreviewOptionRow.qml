// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: row
    required property var tokens
    required property var option
    required property string moduleId
    property int stripeIndex: 0
    property bool uniformSurface: false
    property bool separatorAfter: false
    property bool selected: false
    property string value: {
        backend.revision;
        return backend.value(moduleId, option.id);
    }
    property bool numeric: value !== "" && isFinite(Number(value))
    signal inspect(bool openPanel)
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    objectName: "optionRow_" + moduleId + "_" + option.id
    implicitHeight: rowBody.implicitHeight + 16
    Rectangle {
        objectName: "rowSurface"
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        radius: 5
        z: -1
        color: row.uniformSurface ? row.tokens.surface : row.stripeIndex % 2 ? row.tokens.alternateRow : row.tokens.rowBase
    }
    Rectangle {
        objectName: "rowSeparator"
        visible: row.separatorAfter
        x: 16
        y: parent.height - height
        width: Math.max(0, parent.width - 32)
        height: 1
        color: row.tokens.line
    }
    function choiceIndex(items, value) {
        for (let i = 0; i < items.length; i++)
            if (String(items[i].id) === value)
                return i;
        return -1;
    }
    RowLayout {
        id: rowBody
        x: 16
        y: 8
        width: Math.max(0, row.width - 32)
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 180
            spacing: 4
            Label {
                id: parameterTitle
                text: row.option.title
                Layout.minimumWidth: 0
                Layout.maximumWidth: parent.width - infoButton.width - 4
                wrapMode: Text.WordWrap
                font: row.tokens.bodyFont
                color: row.tokens.text
                PreviewToolTip {
                    tokens: row.tokens
                    visible: titleHover.hovered
                    text: row.option.summary || row.option.tooltip || row.option.title
                }
                HoverHandler {
                    id: titleHover
                }
            }
            ToolButton {
                id: infoButton
                text: "ⓘ"
                implicitWidth: 26
                implicitHeight: 28
                font: row.tokens.bodyFont
                Accessible.name: "Пояснение: " + row.option.title
                onClicked: row.inspect(true)
                contentItem: PreviewIcon {
                    name: "info"
                    ink: row.tokens.secondary
                    implicitWidth: 16
                    implicitHeight: 16
                }
                background: Rectangle {
                    radius: 5
                    color: infoButton.hovered ? row.tokens.hover : "transparent"
                    border.color: row.tokens.accent
                    border.width: infoButton.visualFocus ? 2 : 0
                }
                PreviewToolTip {
                    tokens: row.tokens
                    visible: infoButton.hovered
                    text: "Объяснение параметра"
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
        }
        ColumnLayout {
            Layout.preferredWidth: 250
            Layout.maximumWidth: 280
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 6
            PreviewComboBox {
                tokens: row.tokens
                visible: row.option.kind === "choice"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: row.tokens.controlHeight
                model: row.option.choices
                textRole: "text"
                valueRole: "id"
                currentIndex: row.choiceIndex(row.option.choices, row.value)
                font: row.tokens.bodyFont
                Accessible.name: row.option.title
                onActiveFocusChanged: if (activeFocus)
                    row.inspect(false)
                onActivated: {
                    row.inspect(false);
                    backend.setOption(row.moduleId, row.option.id, currentValue);
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
                    Behavior on color {
                        ColorAnimation {
                            duration: row.tokens.reduceMotion ? 0 : 120
                        }
                    }
                    border.width: toggle.visualFocus ? 2 : 1
                    border.color: toggle.checked || toggle.visualFocus ? row.tokens.accent : row.tokens.secondary
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        x: toggle.checked ? 16 : 2
                        Behavior on x {
                            NumberAnimation {
                                duration: row.tokens.reduceMotion ? 0 : 120
                                easing.type: Easing.OutCubic
                            }
                        }
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
            PreviewComboBox {
                tokens: row.tokens
                visible: row.option.kind === "slider" && row.option.nan.length > 0
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitHeight: row.tokens.controlHeight
                model: ["Числовое значение"].concat(row.option.nan)
                currentIndex: row.numeric ? 0 : row.option.nan.indexOf(row.value) + 1
                Accessible.name: row.option.title + ": режим"
                font: row.tokens.bodyFont
                onActiveFocusChanged: if (activeFocus)
                    row.inspect(false)
                onActivated: {
                    row.inspect(false);
                    backend.setOption(row.moduleId, row.option.id, currentIndex === 0 ? String(row.option.min) : currentText);
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
                PreviewTextField {
                    tokens: row.tokens
                    Layout.preferredWidth: 58
                    implicitHeight: row.tokens.controlHeight
                    text: row.value
                    selectByMouse: true
                    enabled: row.numeric
                    horizontalAlignment: Text.AlignHCenter
                    Accessible.name: row.option.title + ": точное значение"
                    font: row.tokens.bodyFont
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
                }
            }
        }
    }
}
