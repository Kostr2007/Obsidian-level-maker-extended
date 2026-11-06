// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

Button {
    id: control
    required property var tokens
    property string symbol: ""
    property bool tooltipEnabled: true
    property bool selected: false
    property bool primary: false
    property bool quiet: false
    font: tokens.bodyFont
    leftPadding: symbol ? 10 : 14
    rightPadding: symbol ? 10 : 14
    topPadding: 5
    bottomPadding: 5
    implicitHeight: Math.max(tokens.controlHeight, contentItem.implicitHeight + 10)
    implicitWidth: Math.max(symbol ? 34 : 70, contentItem.implicitWidth + leftPadding + rightPadding)
    contentItem: Item {
        implicitWidth: control.symbol ? 18 : label.implicitWidth
        implicitHeight: Math.max(18, label.implicitHeight)
        PreviewIcon {
            anchors.centerIn: parent
            visible: !!control.symbol
            name: control.symbol
            ink: control.primary ? control.tokens.accentText : control.selected ? control.tokens.accent : control.tokens.secondary
        }
        Label {
            id: label
            anchors.centerIn: parent
            visible: !control.symbol
            text: control.text
            font: control.font
            color: control.primary ? control.tokens.accentText : control.tokens.text
            opacity: control.enabled ? 1 : .45
        }
    }
    background: Rectangle {
        radius: 6
        color: control.primary ? control.tokens.accent : control.down || control.hovered ? control.tokens.hover : control.selected ? control.tokens.selection : control.quiet ? "transparent" : control.tokens.surface
        opacity: control.enabled ? (control.down ? .75 : 1) : .45
        border.color: control.visualFocus ? control.tokens.accent : control.primary || control.selected ? control.tokens.selection : control.quiet ? "transparent" : control.tokens.line
        border.width: control.visualFocus ? 2 : 1
        Behavior on color {
            ColorAnimation {
                duration: control.tokens.reduceMotion ? 0 : 100
            }
        }
    }
    PreviewToolTip {
        tokens: control.tokens
        visible: control.hovered && !!control.symbol && control.tooltipEnabled
        text: control.Accessible.name
    }
}
