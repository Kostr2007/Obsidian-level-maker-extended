// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

Dialog {
    id: styleDialog
    required property var tokens
    readonly property bool effectiveDark: styleDialog.tokens ? styleDialog.tokens.dark : backend.dark
    readonly property color textInkColor: styleDialog.tokens ? styleDialog.tokens.text : styleDialog.effectiveDark ? "#f0f0f3" : "#202124"
    readonly property color surfaceColor: styleDialog.tokens ? styleDialog.tokens.surface : styleDialog.effectiveDark ? "#2c2c30" : "#ffffff"
    readonly property color lineColor: styleDialog.tokens ? styleDialog.tokens.line : styleDialog.effectiveDark ? "#48484f" : "#d8d8df"
    readonly property color accentColor: styleDialog.tokens ? styleDialog.tokens.accent : styleDialog.effectiveDark ? "#4da3ff" : "#0069d9"
    readonly property color accentInkColor: styleDialog.tokens ? styleDialog.tokens.accentText : styleDialog.effectiveDark ? "#101820" : "#ffffff"
    readonly property color hoverColor: styleDialog.tokens ? styleDialog.tokens.hover : styleDialog.effectiveDark ? "#38383e" : "#e6e6eb"
    readonly property real chromeHeight: topPadding + bottomPadding + (header && header.visible ? header.implicitHeight + spacing : 0) + (footer && footer.visible ? footer.implicitHeight + spacing : 0)
    function standardButton(button) {
        return footerActions.standardButton(button);
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: styleDialog.tokens ? styleDialog.tokens.popupIn : 170
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.97
                to: 1
                duration: styleDialog.tokens ? styleDialog.tokens.popupIn : 170
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
                duration: styleDialog.tokens ? styleDialog.tokens.popupOut : 110
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1
                to: 0.985
                duration: styleDialog.tokens ? styleDialog.tokens.popupOut : 110
                easing.type: Easing.InCubic
            }
        }
    }
    padding: 16
    spacing: 14
    font: styleDialog.tokens ? styleDialog.tokens.bodyFont : Qt.application.font
    background: Rectangle {
        radius: 12
        color: styleDialog.surfaceColor
        border.width: 1
        border.color: styleDialog.lineColor
    }
    header: Label {
        visible: !!styleDialog.title
        text: styleDialog.title
        font: styleDialog.tokens ? styleDialog.tokens.sectionFont : styleDialog.font
        color: styleDialog.textInkColor
        wrapMode: Text.WordWrap
        topPadding: 18
        leftPadding: 18
        rightPadding: 18
        bottomPadding: 2
    }
    footer: DialogButtonBox {
        id: footerActions
        objectName: "dialogFooter"
        visible: count > 0
        spacing: 8
        padding: 16
        topPadding: 4
        standardButtons: styleDialog.standardButtons
        delegate: Button {
            id: footerButton
            objectName: "dialogButton_" + text
            font: styleDialog.tokens ? styleDialog.tokens.bodyFont : styleDialog.font
            implicitHeight: styleDialog.tokens ? styleDialog.tokens.controlHeight : 30
            implicitWidth: Math.max(76, footerButtonLabel.implicitWidth + 28)
            leftPadding: 14
            rightPadding: 14
            readonly property bool affirmative: DialogButtonBox.buttonRole === DialogButtonBox.AcceptRole || DialogButtonBox.buttonRole === DialogButtonBox.YesRole
            contentItem: Text {
                id: footerButtonLabel
                text: footerButton.text
                font: footerButton.font
                color: footerButton.affirmative ? (styleDialog.accentInkColor) : styleDialog.textInkColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 6
                color: footerButton.affirmative ? (styleDialog.accentColor) : footerButton.down || footerButton.hovered ? (styleDialog.hoverColor) : (styleDialog.surfaceColor)
                border.width: footerButton.visualFocus ? 2 : 1
                border.color: footerButton.visualFocus ? (styleDialog.accentColor) : (styleDialog.lineColor)
            }
        }
        background: Item {}
    }
}
