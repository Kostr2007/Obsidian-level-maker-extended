// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ResourceAssets.js" as Resources

ColumnLayout {
    id: assets
    property string optionId: ""
    property real textScale: 1
    readonly property string game: {
        backend.revision;
        backend.schema;
        return backend.value("", "game");
    }
    property bool compatible: {
        backend.revision;
        backend.schema;
        return Resources.compatible(backend.value("", "game"));
    }
    readonly property var examples: compatible ? Resources.forOption(optionId, game) : []
    readonly property bool available: examples.length > 0
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    spacing: 12
    Label {
        text: "В игре это выглядит так"
        font.weight: Font.DemiBold
        font.pixelSize: Math.round(13 * assets.textScale)
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        wrapMode: Text.WordWrap
    }
    GridLayout {
        // A stable two-column inspector avoids width/implicitHeight feedback on Qt 6.4.
        columns: 2
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        columnSpacing: 8
        rowSpacing: 12
        Repeater {
            model: assets.examples
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 5
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    radius: 8
                    color: backend.dark ? "#37373d" : "#f1f1f4"
                    Image {
                        objectName: "freedoomSprite_" + modelData.id
                        anchors.fill: parent
                        anchors.margins: 10
                        source: Resources.image(modelData.file)
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                        mipmap: false
                        Accessible.name: modelData.caption
                    }
                }
                Label {
                    text: modelData.caption
                    font.pixelSize: Math.round(11 * assets.textScale)
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
    Label {
        text: "Оригинальные спрайты Freedoom Phase 2.\nПоказан вид предметов, а не гарантированный состав вашей карты."
        font.pixelSize: Math.round(11 * assets.textScale)
        opacity: .65
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        wrapMode: Text.WordWrap
    }
}
