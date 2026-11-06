// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    required property var tokens
    readonly property real scaleFactor: tokens ? tokens.textScale : 1
    readonly property color textInk: tokens ? tokens.text : palette.text
    readonly property color mutedInk: tokens ? tokens.secondary : palette.placeholderText
    readonly property string longestText: {
        model;
        textRole;
        let longest = "";
        for (let i = 0; i < count; ++i) {
            let value = textAt(i);
            if (value.length > longest.length)
                longest = value;
        }
        return longest;
    }
    implicitHeight: tokens ? tokens.controlHeight : 30
    leftPadding: 10
    rightPadding: 28
    topPadding: 4
    bottomPadding: 4
    font: tokens ? tokens.valueFont : Qt.application.font
    hoverEnabled: true
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: control.textInk
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        opacity: control.enabled ? 1 : .5
    }
    indicator: Canvas {
        id: arrow
        property color ink: control.mutedInk
        x: control.width - width - 10
        y: (control.height - height) / 2
        width: 9
        height: 6
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation {
            NumberAnimation {
                duration: control.tokens && control.tokens.reduceMotion ? 0 : 120
                easing.type: Easing.OutCubic
            }
        }
        opacity: control.enabled ? 1 : .5
        onInkChanged: requestPaint()
        onPaint: {
            let context = getContext("2d");
            context.reset();
            context.strokeStyle = ink;
            context.lineWidth = 1.25;
            context.lineCap = "round";
            context.lineJoin = "round";
            context.beginPath();
            context.moveTo(1, 1);
            context.lineTo(4.5, 4.5);
            context.lineTo(8, 1);
            context.stroke();
        }
    }
    background: Rectangle {
        radius: 6
        color: control.tokens ? (control.hovered ? control.tokens.hover : control.tokens.surface) : control.palette.base
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? (control.tokens ? control.tokens.accent : control.palette.highlight) : (control.tokens ? control.tokens.line : control.palette.mid)
        opacity: control.enabled ? 1 : .55
    }
    TextMetrics {
        id: popupMetrics
        font: control.font
        text: control.longestText
    }
    delegate: ItemDelegate {
        id: optionDelegate
        required property int index
        width: ListView.view ? ListView.view.width : control.width
        implicitHeight: Math.max(30 * control.scaleFactor, label.implicitHeight + 12)
        highlighted: control.highlightedIndex === index
        leftPadding: 10
        rightPadding: 10
        contentItem: Text {
            id: label
            text: control.textAt(index)
            font: control.font
            color: optionDelegate.highlighted ? (control.tokens ? control.tokens.accentText : control.palette.highlightedText) : control.textInk
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
        }
        background: Rectangle {
            radius: 4
            color: optionDelegate.highlighted ? (control.tokens ? control.tokens.accent : control.palette.highlight) : "transparent"
        }
    }
    popup: Popup {
        objectName: control.objectName + "_popup"
        enter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: control.tokens ? control.tokens.popupIn : 170
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 0.97
                    to: 1
                    duration: control.tokens ? control.tokens.popupIn : 170
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
                    duration: control.tokens ? control.tokens.popupOut : 110
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.985
                    duration: control.tokens ? control.tokens.popupOut : 110
                    easing.type: Easing.InCubic
                }
            }
        }

        y: control.height + 4
        padding: 4
        margins: 12
        width: Math.min(Math.max(control.width, popupMetrics.width + 40), Math.max(control.width, (control.Overlay.overlay ? control.Overlay.overlay.width : 800) - 24))
        implicitHeight: Math.min(contentItem.implicitHeight + topPadding + bottomPadding, Math.max(80, Math.min(360 * control.scaleFactor, (control.Overlay.overlay ? control.Overlay.overlay.height : 800) - 48)))
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            radius: 8
            color: control.tokens ? control.tokens.surface : control.palette.base
            border.width: 1
            border.color: control.tokens ? control.tokens.line : control.palette.mid
        }
    }
    PreviewToolTip {
        tokens: control.tokens
        visible: control.hovered && control.contentItem.truncated && !control.popup.visible
        text: control.displayText
    }
}
