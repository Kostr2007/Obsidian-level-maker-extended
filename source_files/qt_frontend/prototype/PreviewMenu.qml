// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

Menu {
    id: menuPanel
    required property var tokens
    objectName: "commandsMenu"
    width: Math.min(Math.round(360 * tokens.textScale), (Overlay.overlay ? Overlay.overlay.width : 800) - 24)
    implicitHeight: Math.min(contentItem.contentHeight + topPadding + bottomPadding, (Overlay.overlay ? Overlay.overlay.height : 800) - 24)
    padding: 6
    margins: 12
    font: tokens.bodyFont
    background: Rectangle {
        radius: 10
        color: menuPanel.tokens.surface
        border.color: menuPanel.tokens.line
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: menuPanel.tokens ? menuPanel.tokens.popupIn : 170
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.97
                to: 1
                duration: menuPanel.tokens ? menuPanel.tokens.popupIn : 170
                easing.type: Easing.OutCubic
            }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: menuPanel.tokens ? menuPanel.tokens.popupOut : 110
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.985
                duration: menuPanel.tokens ? menuPanel.tokens.popupOut : 110
                easing.type: Easing.InCubic
            }
        }
    }
}
