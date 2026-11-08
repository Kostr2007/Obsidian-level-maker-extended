pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Basic.ComboBox {
    id: control
    implicitWidth: Math.max(150, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: 32
    leftPadding: 6
    rightPadding: 34
    hoverEnabled: true
    font.pixelSize: 17
    palette.window: Theme.dark ? "#3b3b3e" : "#fafafa"
    palette.base: Theme.field
    palette.text: Theme.settingsText
    palette.buttonText: Theme.settingsText
    palette.highlight: Theme.settingsAccent
    palette.highlightedText: "#ffffff"
    delegate: Basic.ItemDelegate {
        id: option
        required property int index
        width: control.popup.width - control.popup.leftPadding - control.popup.rightPadding
        text: control.textAt(index)
        highlighted: control.highlightedIndex === index
        font: control.font
        implicitHeight: 34
        padding: 10
        contentItem: Text {
            text: option.text
            font: option.font
            color: option.highlighted ? "#ffffff" : Theme.settingsText
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 5
            color: option.highlighted ? Theme.settingsAccent : option.hovered ? Theme.hover : "transparent"
        }
    }
    popup: Basic.Popup {
        y: control.height + 4
        width: control.width
        padding: 6
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
        }
        background: Rectangle {
            radius: 9
            color: Theme.settingsGroup
            border.color: Theme.settingsSeparator
        }
    }
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: control.enabled ? Theme.settingsText : Theme.settingsSecondary
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
    indicator: Rectangle {
        x: control.width - width - 3
        y: (control.height - height) / 2
        width: 24
        height: 26
        radius: 7
        color: Theme.dark ? "#49494c" : control.hovered ? "#e5e5e7" : "#eeeef0"
        opacity: control.enabled ? 1 : 0.45
        Canvas {
            anchors.centerIn: parent
            width: 12
            height: 16
            property color strokeColor: Theme.settingsText
            onStrokeColorChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.clearRect(0, 0, width, height);
                c.strokeStyle = strokeColor;
                c.lineWidth = 1.7;
                c.lineCap = "round";
                c.lineJoin = "round";
                c.beginPath();
                c.moveTo(3, 5);
                c.lineTo(6, 2);
                c.lineTo(9, 5);
                c.moveTo(3, 11);
                c.lineTo(6, 14);
                c.lineTo(9, 11);
                c.stroke();
            }
        }
    }
    background: Rectangle {
        radius: 5
        color: "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.accent
    }
}
