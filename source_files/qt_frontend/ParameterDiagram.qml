// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: diagram
    property string kind: ""
    Layout.fillWidth: true
    spacing: 8
    // Schematic comparisons, independent of the selected value and actual WAD.
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: 2
            ColumnLayout {
                required property int index
                Layout.fillWidth: true
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 126
                    radius: 5
                    color: backend.dark ? "#151a22" : "#edf2f8"
                    border.color: backend.dark ? "#353d49" : "#d8dee7"
                    Canvas {
                        id: canvas
                        anchors.fill: parent
                        anchors.margins: 9
                        property bool more: index === 1
                        property string kind: diagram.kind
                        property bool dark: backend.dark
                        property string accent: backend.accent
                        onKindChanged: requestPaint()
                        onDarkChanged: requestPaint()
                        onAccentChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onPaint: {
                            let c = getContext("2d");
                            c.reset();
                            c.scale(width / 120, height / 100);
                            let ink = dark ? "#c8d2e2" : "#42516a";
                            let fill = dark ? "#2c3748" : "#d5e0ee";
                            let hot = dark ? "#f0b975" : "#a05615";
                            c.lineWidth = 2;
                            c.strokeStyle = ink;
                            function box(x, y, w, h, color) {
                                c.fillStyle = color || fill;
                                c.fillRect(x, y, w, h);
                                c.strokeRect(x, y, w, h);
                            }
                            function line(x, y, u, v) {
                                c.beginPath();
                                c.moveTo(x, y);
                                c.lineTo(u, v);
                                c.stroke();
                            }
                            function dot(x, y, r, color) {
                                c.fillStyle = color;
                                c.beginPath();
                                c.arc(x, y, r, 0, Math.PI * 2);
                                c.fill();
                            }
                            function triangle(x, y, r, color) {
                                c.fillStyle = color;
                                c.beginPath();
                                c.moveTo(x, y - r);
                                c.lineTo(x - r, y + r);
                                c.lineTo(x + r, y + r);
                                c.closePath();
                                c.fill();
                            }
                            let n = more ? 8 : 3;
                            if (kind === "height" || kind === "vertical") {
                                let ceil = more ? 10 : 47;
                                if (kind === "height") {
                                    box(5, ceil, 110, 80 - ceil);
                                    line(5, 80, 115, 80);
                                } else {
                                    let step = more ? 15 : 4;
                                    for (let i = 0; i < 4; i++)
                                        box(5 + i * 27, 80 - i * step, 27, 10 + i * step);
                                }
                                dot(24, 63, 4, hot);
                                c.strokeStyle = hot;
                                line(24, 68, 24, 79);
                                line(18, 72, 30, 72);
                            } else if (kind === "size" || kind === "rooms" || kind === "linear" || kind === "corridors") {
                                c.strokeStyle = accent;
                                c.lineWidth = 5;
                                line(24, 70, 60, 70);
                                line(60, 70, 60, 28);
                                if (more && kind !== "linear") {
                                    line(60, 28, 96, 28);
                                    line(96, 28, 96, 70);
                                }
                                if (kind === "linear" && !more) {
                                    line(24, 70, 24, 28);
                                    line(24, 28, 96, 28);
                                }
                                c.strokeStyle = ink;
                                c.lineWidth = 2;
                                let w = kind === "rooms" && more ? 36 : 24;
                                box(10, 58, w, 25);
                                box(46, 15, w, 25);
                                if (more && kind !== "linear")
                                    box(82, 58, 28, 25);
                                triangle(20, 72, 4, accent);
                            } else if (kind === "caves") {
                                c.fillStyle = fill;
                                c.beginPath();
                                let points = more ? [[8, 30], [30, 10], [55, 24], [79, 8], [110, 27], [100, 50], [113, 75], [80, 90], [55, 76], [25, 90], [8, 65]] : [[15, 20], [105, 20], [105, 80], [15, 80]];
                                points.forEach(function (p, i) {
                                    if (i === 0)
                                        c.moveTo(p[0], p[1]);
                                    else
                                        c.lineTo(p[0], p[1]);
                                });
                                c.closePath();
                                c.fill();
                                c.stroke();
                            } else {
                                box(8, 12, 104, 76, kind === "lighting" ? (more ? "#bccde2" : "#303b4c") : fill);
                                if (kind === "liquids" || kind === "outdoors") {
                                    c.fillStyle = kind === "liquids" ? "#508cb8" : "#77977b";
                                    c.fillRect(13, 17, more ? 94 : 28, 66);
                                } else if (kind === "lighting") {
                                    c.strokeStyle = more ? "#54647c" : "#8293ad";
                                    line(28, 30, 90, 30);
                                    line(28, 50, 75, 50);
                                    line(28, 70, 95, 70);
                                } else if (kind === "secrets") {
                                    for (let i = 0; i < (more ? 3 : 1); i++) {
                                        c.setLineDash([3, 3]);
                                        box(15 + i * 31, 23, 22, 25);
                                        c.setLineDash([]);
                                        c.fillStyle = hot;
                                        c.font = "16px sans-serif";
                                        c.fillText("?", 21 + i * 31, 42);
                                    }
                                } else if (kind === "teleports") {
                                    c.strokeStyle = accent;
                                    c.lineWidth = 3;
                                    for (let i = 0; i < (more ? 4 : 2); i++) {
                                        c.beginPath();
                                        c.arc(30 + (i % 2) * 57, 34 + Math.floor(i / 2) * 34, 10, 0, Math.PI * 2);
                                        c.stroke();
                                    }
                                } else if (kind === "traps") {
                                    for (let i = 0; i < (more ? 6 : 2); i++)
                                        triangle(22 + (i % 3) * 36, 30 + Math.floor(i / 3) * 35, 5, hot);
                                    c.setLineDash([4, 3]);
                                    line(14, 50, 105, 50);
                                    c.setLineDash([]);
                                } else {
                                    if (kind === "strength" || kind === "variety")
                                        n = 4;
                                    for (let i = 0; i < n; i++) {
                                        let x = 24 + (i % 4) * 24, y = 32 + Math.floor(i / 4) * 33;
                                        if (kind === "health") {
                                            c.fillStyle = "#6aab8a";
                                            c.fillRect(x - 3, y - 8, 6, 16);
                                            c.fillRect(x - 8, y - 3, 16, 6);
                                        } else if (["ammo", "items", "weapons"].includes(kind))
                                            box(x - 6, y - 5, 12, 10, accent);
                                        else
                                            triangle(x, y, kind === "strength" && more ? 9 : 5, kind === "variety" && more ? [hot, accent, "#a690cd", "#75ac91"][i] : hot);
                                    }
                                }
                            }
                        }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 12
                    text: diagram.kind === "height" ? (index ? "Выше" : "Ниже") : diagram.kind === "vertical" ? (index ? "Сильнее" : "Плавнее") : diagram.kind === "linear" ? (index ? "Линейнее" : "Больше ветвей") : diagram.kind === "strength" ? (index ? "Сильнее" : "Слабее") : (index ? "Больше" : "Меньше")
                }
            }
        }
    }
    Label {
        text: "Схема принципа, не прогноз карты."
        font.pixelSize: 11
        opacity: .65
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }
}
