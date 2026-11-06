// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MenuItem {
    id: entry
    required property var tokens
    implicitHeight: Math.round(32 * tokens.textScale)
    indicator: Item {
        visible: false
        implicitWidth: 0
        implicitHeight: 0
    }
    font: tokens.bodyFont
    leftPadding: 8
    rightPadding: 8
    contentItem: RowLayout {
        spacing: 8
        PreviewIcon {
            name: "check"
            opacity: entry.checked ? 1 : 0
            ink: entry.highlighted ? entry.tokens.accentText : entry.tokens.text
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
        }
        Label {
            text: entry.text.split("  ·  ")[0]
            font: entry.font
            color: entry.highlighted ? entry.tokens.accentText : entry.tokens.text
            opacity: entry.enabled ? 1 : 0.45
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        Label {
            text: entry.text.split("  ·  ")[1] || ""
            font: entry.tokens.captionFont
            color: entry.highlighted ? entry.tokens.accentText : entry.tokens.secondary
            opacity: entry.enabled ? 1 : 0.45
        }
    }
    background: Rectangle {
        radius: 5
        color: entry.highlighted ? entry.tokens.accent : "transparent"
    }
}
