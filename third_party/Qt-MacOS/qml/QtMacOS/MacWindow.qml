pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtMacOS

ApplicationWindow {
    id: window
    default property alias surfaceData: surface.data
    property alias surfaceItem: surface
    property string surfaceObjectName: "windowSurface"
    property int normalRadius: 13
    property int shadowMargin: 24
    property color surfaceColor: Theme.dark ? "#252628" : "#ffffff"
    property color outlineColor: Theme.dark ? "#777779" : "#b0b0b3"
    property bool presentation: Qt.application.arguments.indexOf("--presentation") >= 0
    readonly property bool expanded: visibility === Window.Maximized || visibility === Window.FullScreen
    readonly property int frameMargin: expanded ? 0 : shadowMargin
    readonly property int corner: expanded ? 0 : normalRadius
    width: 1148
    height: 724
    minimumWidth: 950
    minimumHeight: 620
    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    font.family: typeface.status === FontLoader.Ready ? typeface.name : "sans-serif"
    font.pixelSize: 17
    function zoom() {
        if (expanded)
            showNormal();
        else
            showMaximized();
    }
    contentData: [
        Item {
            anchors.fill: parent
            FontLoader {
                id: typeface
                source: "qrc:/qt/qml/QtMacOS/fonts/InterVariable.ttf"
            }
            Rectangle {
                anchors.fill: parent
                visible: window.presentation
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#7085b3"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#93abc5"
                    }
                    GradientStop {
                        position: 1
                        color: "#4a668e"
                    }
                }
            }
            Repeater {
                model: window.expanded ? 0 : 18
                Rectangle {
                    required property int index
                    x: window.frameMargin - index * 1.15
                    y: window.frameMargin + 7 - index * 0.85
                    width: window.width - 2 * window.frameMargin + index * 2.3
                    height: window.height - 2 * window.frameMargin + index * 1.7
                    radius: window.corner + index
                    color: "#08000000"
                }
            }
            Rectangle {
                id: surface
                objectName: window.surfaceObjectName
                anchors {
                    fill: parent
                    margins: window.frameMargin
                }
                radius: window.corner
                color: window.surfaceColor
                Rectangle {
                    anchors.fill: parent
                    z: 1000
                    radius: window.corner
                    color: "transparent"
                    border.width: 1
                    border.color: window.outlineColor
                }
            }
            Repeater {
                model: window.expanded ? [] : [Qt.LeftEdge, Qt.RightEdge, Qt.TopEdge, Qt.BottomEdge, Qt.TopEdge | Qt.LeftEdge, Qt.TopEdge | Qt.RightEdge, Qt.BottomEdge | Qt.LeftEdge, Qt.BottomEdge | Qt.RightEdge]
                MouseArea {
                    required property int modelData
                    readonly property bool leftEdge: (modelData & Qt.LeftEdge) !== 0
                    readonly property bool rightEdge: (modelData & Qt.RightEdge) !== 0
                    readonly property bool topEdge: (modelData & Qt.TopEdge) !== 0
                    readonly property bool bottomEdge: (modelData & Qt.BottomEdge) !== 0
                    x: leftEdge ? window.frameMargin - 4 : rightEdge ? window.width - window.frameMargin - 4 : window.frameMargin + 8
                    y: topEdge ? window.frameMargin - 4 : bottomEdge ? window.height - window.frameMargin - 4 : window.frameMargin + 8
                    width: leftEdge || rightEdge ? 8 : window.width - 2 * window.frameMargin - 16
                    height: topEdge || bottomEdge ? 8 : window.height - 2 * window.frameMargin - 16
                    cursorShape: (leftEdge && topEdge) || (rightEdge && bottomEdge) ? Qt.SizeFDiagCursor : (leftEdge && bottomEdge) || (rightEdge && topEdge) ? Qt.SizeBDiagCursor : leftEdge || rightEdge ? Qt.SizeHorCursor : Qt.SizeVerCursor
                    onPressed: window.startSystemResize(modelData)
                }
            }
        }
    ]
}
