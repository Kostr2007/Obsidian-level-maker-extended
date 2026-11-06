// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

QtObject {
    objectName: "designTokens"
    readonly property FontLoader regularFace: FontLoader {
        source: "qrc:/fonts/Inter-Regular.ttf"
    }
    readonly property FontLoader mediumFace: FontLoader {
        source: "qrc:/fonts/Inter-Medium.ttf"
    }
    readonly property FontLoader semiboldFace: FontLoader {
        source: "qrc:/fonts/Inter-SemiBold.ttf"
    }
    readonly property FontLoader displayFace: FontLoader {
        source: "qrc:/fonts/InterDisplay-SemiBold.ttf"
    }
    readonly property bool fontsReady: regularFace.status === FontLoader.Ready && mediumFace.status === FontLoader.Ready && semiboldFace.status === FontLoader.Ready && displayFace.status === FontLoader.Ready
    readonly property font bodyFont: Qt.font({
        family: regularFace.name,
        pixelSize: bodySize,
        weight: Font.Normal
    })
    readonly property font valueFont: bodyFont
    readonly property font captionFont: Qt.font({
        family: regularFace.name,
        pixelSize: smallSize,
        weight: Font.Normal
    })
    readonly property font navigationFont: Qt.font({
        family: mediumFace.name,
        pixelSize: bodySize,
        weight: Font.Medium
    })
    readonly property font sectionFont: Qt.font({
        family: semiboldFace.name,
        pixelSize: bodySize,
        weight: Font.DemiBold
    })
    readonly property font titleFont: Qt.font({
        family: displayFace.name,
        pixelSize: Math.round(26 * textScale),
        weight: Font.DemiBold
    })
    readonly property font brandFont: Qt.font({
        family: displayFace.name,
        pixelSize: Math.round(18 * textScale),
        weight: Font.DemiBold
    })
    readonly property font detailFont: Qt.font({
        family: semiboldFace.name,
        pixelSize: Math.round(18 * textScale),
        weight: Font.DemiBold
    })
    readonly property font monoFont: Qt.font({
        family: "monospace",
        pixelSize: smallSize,
        weight: Font.Normal
    })
    readonly property int controlHeight: Math.max(30, Math.round(30 * textScale))

    property bool dark: backend.dark
    property bool reduceMotion: false
    property real textScale: 1
    readonly property color canvas: dark ? "#202023" : "#ffffff"
    readonly property color sidebar: dark ? "#29292d" : "#eeeeef"
    readonly property color surface: dark ? "#2c2c30" : "#ffffff"
    readonly property color toolbar: dark ? "#29292d" : "#f7f7f8"
    readonly property color thumbnail: dark ? "#2c2c31" : "#f5f5f7"
    readonly property color thumbnailSelected: dark ? "#404047" : "#e7e7eb"
    readonly property color alternateRow: dark ? "#333338" : "#f2f2f5"
    readonly property color rowBase: dark ? "#2a2a2e" : "#ffffff"
    readonly property int popupIn: reduceMotion ? 0 : 170
    readonly property int popupOut: reduceMotion ? 0 : 110
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
    readonly property int smallSize: Math.round(12 * textScale)
}
