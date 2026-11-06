// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

TextField {
    id: control
    required property var tokens
    readonly property real scaleFactor: tokens ? tokens.textScale : 1
    font: tokens ? tokens.valueFont : Qt.application.font
    implicitHeight: tokens ? tokens.controlHeight : 30
    leftPadding: 10
    rightPadding: 10
    topPadding: 4
    bottomPadding: 4
    color: tokens ? tokens.text : palette.text
    placeholderTextColor: tokens ? tokens.secondary : palette.placeholderText
    selectionColor: tokens ? tokens.accent : palette.highlight
    selectedTextColor: tokens ? tokens.accentText : palette.highlightedText
    selectByMouse: true
    background: Rectangle {
        radius: 6
        color: control.tokens ? control.tokens.surface : control.palette.base
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? (control.tokens ? control.tokens.accent : control.palette.highlight) : (control.tokens ? control.tokens.line : control.palette.mid)
        opacity: control.enabled ? 1 : .55
    }
}
