// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtMacOS

MacButton {
    id: control
    // The Studio's accent preference still owns highlighted actions and focus.
    palette.brightText: highlighted ? "#101827" : Theme.text
    Binding {
        target: control.background
        property: "color"
        when: control.highlighted
        value: control.down ? Qt.darker(backend.accent, 1.15) : backend.accent
    }
    Binding {
        target: control.background
        property: "border.color"
        when: control.visualFocus
        value: backend.accent
    }
}
