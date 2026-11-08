pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic

Row {
    id: lights
    property bool dark: true
    property bool windowActive: true
    signal closeRequested
    signal minimizeRequested
    signal zoomRequested

    spacing: 10
    property bool showSymbols: closeButton.hovered || minimizeButton.hovered || zoomButton.hovered

    Basic.ToolButton {
        id: closeButton
        objectName: "windowClose"
        width: 15
        height: 15
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Close window")
        onClicked: lights.closeRequested()
        background: Rectangle {
            radius: width / 2
            color: lights.windowActive || lights.showSymbols ? "#ff5f57" : lights.dark ? "#777779" : "#c5c5c7"
            border.width: 0.5
            border.color: lights.windowActive ? "#e84a43" : "transparent"
        }
        contentItem: Canvas {
            visible: lights.showSymbols || closeButton.visualFocus
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "#7f2520";
                ctx.lineWidth = 1.2;
                ctx.beginPath();
                ctx.moveTo(4, 4);
                ctx.lineTo(10, 10);
                ctx.moveTo(10, 4);
                ctx.lineTo(4, 10);
                ctx.stroke();
            }
        }
    }
    Basic.ToolButton {
        id: minimizeButton
        objectName: "windowMinimize"
        width: 15
        height: 15
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Minimize window")
        onClicked: lights.minimizeRequested()
        background: Rectangle {
            radius: width / 2
            color: lights.windowActive || lights.showSymbols ? "#febc2e" : lights.dark ? "#777779" : "#c5c5c7"
            border.width: 0.5
            border.color: lights.windowActive ? "#e5a41c" : "transparent"
        }
        contentItem: Canvas {
            visible: lights.showSymbols || minimizeButton.visualFocus
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "#8d600c";
                ctx.lineWidth = 1.2;
                ctx.beginPath();
                ctx.moveTo(3.5, 7);
                ctx.lineTo(10.5, 7);
                ctx.stroke();
            }
        }
    }
    Basic.ToolButton {
        id: zoomButton
        objectName: "windowZoom"
        width: 15
        height: 15
        padding: 0
        hoverEnabled: true
        Accessible.name: qsTr("Maximize or restore window")
        onClicked: lights.zoomRequested()
        background: Rectangle {
            radius: width / 2
            color: lights.windowActive || lights.showSymbols ? "#28c840" : lights.dark ? "#777779" : "#c5c5c7"
            border.width: 0.5
            border.color: lights.windowActive ? "#19ac2c" : "transparent"
        }
        contentItem: Canvas {
            visible: lights.showSymbols || zoomButton.visualFocus
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#176c25";
                ctx.beginPath();
                ctx.moveTo(3.5, 8);
                ctx.lineTo(8, 3.5);
                ctx.lineTo(3.5, 3.5);
                ctx.closePath();
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(10.5, 6);
                ctx.lineTo(6, 10.5);
                ctx.lineTo(10.5, 10.5);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}
