// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

Button {
    id: control
    font.pixelSize: 13
    leftPadding: 12
    rightPadding: 12
    topPadding: 8
    bottomPadding: 8
    contentItem: Label {
        text: control.text
        font: control.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: control.highlighted ? "#101827" : control.palette.buttonText
        opacity: control.enabled ? 1 : .45
    }
    background: Rectangle {
        implicitWidth: 80
        implicitHeight: 36
        radius: 5
        color: control.highlighted ? backend.accent : control.down ? control.palette.mid : control.hovered ? control.palette.alternateBase : control.palette.button
        opacity: control.enabled ? 1 : .5
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? backend.accent : control.highlighted ? backend.accent : control.palette.mid
    }
}
