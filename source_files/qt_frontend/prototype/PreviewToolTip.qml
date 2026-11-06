// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

ToolTip {
    id: hint
    required property var tokens
    objectName: "previewToolTip"
    readonly property bool darkTheme: hint.tokens ? hint.tokens.dark : backend.dark
    delay: 450
    timeout: 6000
    padding: 9
    margins: 12
    font: hint.tokens ? hint.tokens.captionFont : Qt.font({
        pixelSize: 12
    })
    implicitWidth: Math.min(380, tipLabel.implicitWidth + leftPadding + rightPadding)
    contentItem: Text {
        id: tipLabel
        text: hint.text
        font: hint.font
        color: hint.tokens ? hint.tokens.text : hint.darkTheme ? "#f0f0f3" : "#202124"
        wrapMode: Text.WordWrap
    }
    background: Rectangle {
        radius: 7
        color: hint.tokens ? hint.tokens.surface : hint.darkTheme ? "#2c2c30" : "#ffffff"
        border.color: hint.tokens ? hint.tokens.line : hint.darkTheme ? "#48484f" : "#d8d8df"
    }
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: hint.tokens && hint.tokens.reduceMotion ? 0 : 100
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: hint.tokens && hint.tokens.reduceMotion ? 0 : 70
        }
    }
}
