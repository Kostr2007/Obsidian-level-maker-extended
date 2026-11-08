pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

Item {
    id: group
    default property alias content: contents.data
    property string title: ""
    property bool expanded: false
    property bool reducedMotion: false
    property real spacing: 8
    property real indentation: 20
    readonly property alias header: toggle
    readonly property alias contentItem: contents

    implicitWidth: 320
    implicitHeight: toggle.height + body.height
    Accessible.role: Accessible.Grouping
    Accessible.name: title

    onExpandedChanged: {
        // Preserve outside focus. Return focus only when hiding the focused subtree.
        if (!expanded && body.activeFocus)
            toggle.forceActiveFocus(Qt.OtherFocusReason);
    }

    data: [
        Basic.ToolButton {
            id: toggle
            width: group.width
            height: Math.max(30, implicitHeight)
            text: group.title
            checkable: true
            checked: group.expanded
            focusPolicy: Qt.StrongFocus
            hoverEnabled: true
            leftPadding: 4
            rightPadding: 8
            topPadding: 5
            bottomPadding: 5
            onClicked: group.expanded = !group.expanded
            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
            Accessible.name: text
            Accessible.description: group.expanded ? qsTr("Expanded") : qsTr("Collapsed")

            contentItem: Row {
                spacing: 6
                Canvas {
                    width: 12
                    height: caption.height
                    property color glyphColor: Theme.secondary
                    rotation: group.expanded ? 90 : 0
                    onGlyphColorChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.clearRect(0, 0, width, height);
                        const middle = height / 2;
                        ctx.fillStyle = glyphColor;
                        ctx.beginPath();
                        ctx.moveTo(3, middle - 4);
                        ctx.lineTo(9, middle);
                        ctx.lineTo(3, middle + 4);
                        ctx.closePath();
                        ctx.fill();
                    }
                    Behavior on rotation {
                        enabled: !group.reducedMotion
                        NumberAnimation {
                            duration: 100
                        }
                    }
                    Accessible.ignored: true
                }
                MacLabel {
                    id: caption
                    width: Math.max(0, toggle.availableWidth - 18)
                    text: group.title
                    role: MacLabel.Heading
                    Accessible.ignored: true
                }
            }
            background: Rectangle {
                radius: 5
                color: toggle.hovered ? Theme.hover : "transparent"
                border.width: toggle.visualFocus ? 2 : 0
                border.color: Theme.accent
            }
        },
        FocusScope {
            id: body
            x: group.indentation
            y: toggle.height
            width: Math.max(0, group.width - group.indentation)
            height: group.expanded ? contents.implicitHeight + group.spacing : 0
            visible: height > 0
            clip: true
            enabled: group.expanded
            Behavior on height {
                enabled: !group.reducedMotion
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
            Column {
                id: contents
                y: group.spacing
                width: body.width
                spacing: group.spacing
            }
        }
    ]
}
