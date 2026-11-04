// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control
    font.pixelSize: 14
    leftPadding: 18; rightPadding: 18
    topPadding: 10; bottomPadding: 10
    // Keep native Qt button input, focus and accessibility, while avoiding a
    // shader-only shadow: this background also works with the software renderer.
    contentItem: Label {
        text: control.text
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: !control.enabled ? control.Material.hintTextColor : control.highlighted
            ? (control.Material.accentColor.hslLightness > .5 ? "#102322" : "#ffffff") : control.Material.foreground
    }
    background: Rectangle {
        implicitWidth: 80; implicitHeight: 44
        radius: height / 2
        color: !control.enabled ? Qt.rgba(.5,.5,.5,.08) : control.highlighted ? control.Material.accentColor
            : control.down ? Qt.rgba(.5,.5,.5,.23) : control.hovered ? Qt.rgba(.5,.5,.5,.16) : Qt.rgba(.5,.5,.5,.08)
        border.width: control.visualFocus ? 2 : 0
        border.color: control.highlighted ? control.Material.foreground : control.Material.accentColor
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
