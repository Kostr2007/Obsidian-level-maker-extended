// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

Frame {
    background: Rectangle {
        radius: 6
        color: backend.dark ? "#20252e" : "#ffffff"
        border.color: backend.dark ? "#353d49" : "#d8dee7"
    }
}
