// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

QtObject {
    property bool dark: backend.dark
    property bool reduceMotion: false
    property real textScale: 1
    readonly property color canvas: dark ? "#202023" : "#f5f5f7"
    readonly property color sidebar: dark ? "#29292d" : "#ececef"
    readonly property color surface: dark ? "#2c2c30" : "#ffffff"
    readonly property color text: dark ? "#f0f0f3" : "#202124"
    readonly property color secondary: dark ? "#b1b1bb" : "#60616a"
    readonly property color line: dark ? "#48484f" : "#d8d8df"
    readonly property color accent: dark ? "#4da3ff" : "#0069d9"
    readonly property color accentText: dark ? "#101820" : "#ffffff"
    readonly property color selection: dark ? "#25456b" : "#dceafd"
    readonly property color selectionText: dark ? "#d6eaff" : "#004a9f"
    readonly property color hover: dark ? "#38383e" : "#e6e6eb"
    readonly property int bodySize: Math.round(13 * textScale)
    readonly property int smallSize: Math.round(11 * textScale)
}
