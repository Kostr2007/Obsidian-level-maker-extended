// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

QtObject {
    property bool dark: backend.dark
    property bool reduceMotion: false
    property real textScale: 1
    readonly property color canvas: dark ? "#202023" : "#ffffff"
    readonly property color sidebar: dark ? "#29292d" : "#eeeeef"
    readonly property color surface: dark ? "#2c2c30" : "#ffffff"
    readonly property color toolbar: dark ? "#29292d" : "#f7f7f8"
    readonly property color thumbnail: dark ? "#2c2c31" : "#f5f5f7"
    readonly property color thumbnailSelected: dark ? "#404047" : "#e7e7eb"
    readonly property int navOut: reduceMotion ? 0 : 90
    readonly property int navIn: reduceMotion ? 0 : 220
    readonly property int panelDuration: reduceMotion ? 0 : 240
    readonly property color text: dark ? "#f0f0f3" : "#202124"
    readonly property color secondary: dark ? "#b1b1bb" : "#60616a"
    readonly property color line: dark ? "#48484f" : "#d8d8df"
    readonly property color accent: dark ? "#4da3ff" : "#0069d9"
    readonly property color accentText: dark ? "#101820" : "#ffffff"
    readonly property color selection: dark ? "#45454b" : "#dcdce1"
    readonly property color selectionText: dark ? "#f0f0f3" : "#202124"
    readonly property color hover: dark ? "#38383e" : "#e6e6eb"
    readonly property int bodySize: Math.round(13 * textScale)
    readonly property int smallSize: Math.round(11 * textScale)
}
