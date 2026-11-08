// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtMacOS

BaseMain {
    readonly property bool qtMacOSPilot: true
    readonly property bool qtMacOSDark: Theme.dark
    Binding { target: Theme; property: "dark"; value: backend.dark }
}
