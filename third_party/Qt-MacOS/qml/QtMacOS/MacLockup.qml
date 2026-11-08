pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

// A single semantic action groups the artwork and its descriptive labels.
Basic.ItemDelegate {
    id: control
    property string itemId: ""
    property string title: ""
    property string subtitle: ""
    property string kind: "folder"
    property color tint: "#52b9ed"
    property bool selected: false
    signal activated()
    signal contextRequested(real x, real y)

    implicitWidth: 160
    implicitHeight: 160
    padding: 10
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    text: title
    Accessible.role: Accessible.ListItem
    Accessible.name: title
    Accessible.description: subtitle
    Accessible.selected: selected
    onClicked: activated()
    Keys.onMenuPressed: contextRequested(width / 2, height / 2)

    background: Rectangle {
        radius: 9
        color: control.selected ? Theme.selection : control.hovered ? Theme.hover : "transparent"
        border.width: control.visualFocus ? 2 : 0
        border.color: Theme.settingsAccent
        opacity: control.enabled ? 1 : 0.45
    }
    contentItem: Column {
        spacing: 4
        opacity: control.enabled ? 1 : 0.45
        Canvas {
            id: artwork
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(112, parent.width)
            height: Math.max(32, control.availableHeight - titleLabel.height - subtitleLabel.height - 8)
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: control
                function onKindChanged() { artwork.requestPaint() }
                function onTintChanged() { artwork.requestPaint() }
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const scale = Math.min(width / 112, height / 88)
                ctx.translate((width - 112 * scale) / 2, (height - 88 * scale) / 2)
                ctx.scale(scale, scale)
                ctx.shadowColor = "#28000000"
                ctx.shadowBlur = 3
                ctx.shadowOffsetY = 2
                const kindName = control.kind.toLowerCase()
                if (kindName.indexOf("folder") !== -1 || kindName.indexOf("project") !== -1) {
                    ctx.fillStyle = Qt.darker(control.tint, 1.18)
                    ctx.beginPath()
                    ctx.moveTo(9, 17); ctx.lineTo(40, 17); ctx.lineTo(49, 25)
                    ctx.lineTo(103, 25); ctx.lineTo(103, 78); ctx.lineTo(9, 78)
                    ctx.closePath(); ctx.fill()
                    const gradient = ctx.createLinearGradient(0, 28, 0, 78)
                    gradient.addColorStop(0, Qt.lighter(control.tint, 1.18))
                    gradient.addColorStop(1, control.tint)
                    ctx.fillStyle = gradient
                    ctx.fillRect(7, 31, 98, 47)
                    ctx.shadowBlur = 0; ctx.shadowOffsetY = 0
                    ctx.strokeStyle = "#60ffffff"; ctx.lineWidth = 1
                    ctx.strokeRect(7.5, 31.5, 97, 46)
                } else {
                    ctx.fillStyle = "#f6f7fa"
                    ctx.beginPath()
                    ctx.moveTo(28, 5); ctx.lineTo(70, 5); ctx.lineTo(86, 21)
                    ctx.lineTo(86, 81); ctx.lineTo(28, 81); ctx.closePath(); ctx.fill()
                    ctx.shadowBlur = 0; ctx.shadowOffsetY = 0
                    ctx.fillStyle = "#d5dbe4"
                    ctx.beginPath(); ctx.moveTo(70, 5); ctx.lineTo(70, 21)
                    ctx.lineTo(86, 21); ctx.closePath(); ctx.fill()
                    if (kindName.indexOf("audio") !== -1) {
                        ctx.strokeStyle = control.tint
                        ctx.lineWidth = 3
                        ctx.lineCap = "round"
                        const levels = [6, 14, 25, 36, 18, 29, 12]
                        for (let i = 0; i < levels.length; ++i) {
                            ctx.beginPath()
                            ctx.moveTo(39 + i * 6, 50 - levels[i] / 2)
                            ctx.lineTo(39 + i * 6, 50 + levels[i] / 2)
                            ctx.stroke()
                        }
                    } else if (kindName.indexOf("scene") !== -1) {
                        ctx.fillStyle = Qt.lighter(control.tint, 1.35)
                        ctx.fillRect(35, 33, 44, 34)
                        ctx.fillStyle = Qt.darker(control.tint, 1.15)
                        ctx.beginPath(); ctx.moveTo(35, 63); ctx.lineTo(48, 39)
                        ctx.lineTo(65, 63); ctx.closePath(); ctx.fill()
                        ctx.fillStyle = "#f6f7fa"
                        ctx.beginPath(); ctx.moveTo(44, 47); ctx.lineTo(48, 39)
                        ctx.lineTo(54, 48); ctx.lineTo(48, 45); ctx.closePath(); ctx.fill()
                        ctx.fillStyle = Qt.darker(control.tint, 1.6)
                        ctx.beginPath(); ctx.moveTo(50, 67); ctx.lineTo(67, 46)
                        ctx.lineTo(79, 59); ctx.lineTo(79, 67); ctx.closePath(); ctx.fill()
                    } else if (kindName.indexOf("texture") !== -1 || kindName.indexOf("image") !== -1) {
                        ctx.fillStyle = control.tint
                        ctx.fillRect(36, 34, 42, 28)
                        ctx.fillStyle = "#b0ffffff"
                        ctx.beginPath(); ctx.arc(67, 42, 4, 0, Math.PI * 2); ctx.fill()
                        ctx.beginPath(); ctx.moveTo(36, 62); ctx.lineTo(50, 45)
                        ctx.lineTo(61, 57); ctx.lineTo(68, 51); ctx.lineTo(78, 62)
                        ctx.closePath(); ctx.fill()
                    } else {
                        ctx.fillStyle = control.tint
                        ctx.fillRect(37, 33, 24, 4)
                        ctx.fillStyle = "#9ba7b6"
                        for (let line = 0; line < 4; ++line)
                            ctx.fillRect(37, 44 + line * 7, line === 3 ? 26 : 39, 2)
                    }
                }
            }
        }
        Text {
            id: titleLabel
            width: parent.width
            text: control.title
            color: Theme.settingsText
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
        Text {
            id: subtitleLabel
            width: parent.width
            text: control.subtitle
            visible: text.length > 0
            height: visible ? implicitHeight : 0
            color: Theme.settingsSecondary
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: (point) => control.contextRequested(point.position.x, point.position.y)
    }
}
