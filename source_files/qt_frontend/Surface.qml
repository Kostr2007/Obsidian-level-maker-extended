// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls

Frame {
    background: Rectangle {
        radius: 18
        color: backend.dark ? "#202b30" : "#eef4f1"
        border.width: 1
        border.color: backend.dark ? "#34464a" : "#d2dfda"
    }
}
