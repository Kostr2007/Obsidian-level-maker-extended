pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtMacOS

// Semantic, read-only interface text. Inherits Control's application font.
Basic.Label {
    id: label
    enum Role {
        Title,
        Heading,
        Body,
        Secondary,
        Caption
    }
    property int role: MacLabel.Body

    color: role === MacLabel.Secondary || role === MacLabel.Caption ? Theme.secondary : Theme.text
    font.pixelSize: role === MacLabel.Title ? 22 : role === MacLabel.Heading ? 15 : role === MacLabel.Caption ? 11 : 13
    font.weight: role === MacLabel.Title || role === MacLabel.Heading ? Font.DemiBold : Font.Normal
    wrapMode: Text.Wrap
    textFormat: Text.PlainText
    verticalAlignment: Text.AlignVCenter
    activeFocusOnTab: false
    Accessible.role: Accessible.StaticText
    Accessible.name: text
    opacity: enabled ? 1 : 0.5
}
