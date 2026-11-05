// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

Canvas {
    id: icon
    property string name: "geometry"
    property color ink: "#60616a"
    implicitWidth: 18
    implicitHeight: 18
    onNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        let c = getContext("2d");
        c.reset();
        c.scale(width / 24, height / 24);
        c.strokeStyle = ink;
        c.lineWidth = 1.6;
        c.lineCap = "round";
        c.lineJoin = "round";
        function path(points, close) {
            c.beginPath();
            points.forEach(function (p, i) {
                if (i)
                    c.lineTo(p[0], p[1]);
                else
                    c.moveTo(p[0], p[1]);
            });
            if (close)
                c.closePath();
            c.stroke();
        }
        function circle(x, y, r) {
            c.beginPath();
            c.arc(x, y, r, 0, 2 * Math.PI);
            c.stroke();
        }
        if (name === "geometry") {
            path([[4, 7], [12, 3], [20, 7], [20, 17], [12, 21], [4, 17]], true);
            path([[4, 7], [12, 11], [20, 7]], false);
            path([[12, 11], [12, 21]], false);
        } else if (name === "combat") {
            circle(12, 12, 7);
            circle(12, 12, 2);
            path([[12, 2], [12, 6]], false);
            path([[12, 18], [12, 22]], false);
            path([[2, 12], [6, 12]], false);
            path([[18, 12], [22, 12]], false);
        } else if (name === "resources") {
            c.strokeRect(4, 6, 16, 14);
            path([[8, 6], [8, 3], [16, 3], [16, 6]], false);
            path([[9, 13], [15, 13]], false);
            path([[12, 10], [12, 16]], false);
        } else if (name === "appearance") {
            circle(12, 12, 4);
            for (let i = 0; i < 8; i++) {
                let a = i * Math.PI / 4;
                path([[12 + 7 * Math.cos(a), 12 + 7 * Math.sin(a)], [12 + 10 * Math.cos(a), 12 + 10 * Math.sin(a)]], false);
            }
        } else if (name === "results") {
            path([[3, 5], [9, 3], [15, 6], [21, 4], [21, 19], [15, 21], [9, 18], [3, 20]], true);
            path([[9, 3], [9, 18]], false);
            path([[15, 6], [15, 21]], false);
        } else if (name === "sidebar" || name === "inspector") {
            c.strokeRect(3, 4, 18, 16);
            path([[name === "sidebar" ? 9 : 15, 4], [name === "sidebar" ? 9 : 15, 20]], false);
        } else if (name === "search") {
            circle(10, 10, 6);
            path([[15, 15], [21, 21]], false);
        } else if (name === "chevron") {
            path([[8, 9], [12, 13], [16, 9]], false);
        } else if (name === "moon") {
            c.beginPath();
            c.arc(12, 12, 9, .4, 5);
            c.quadraticCurveTo(6, 10, 20, 15);
            c.stroke();
        } else if (name === "close") {
            path([[6, 6], [18, 18]], false);
            path([[18, 6], [6, 18]], false);
        } else {
            path([[4, 7], [20, 7]], false);
            path([[4, 12], [20, 12]], false);
            path([[4, 17], [20, 17]], false);
            circle(8, 7, 2);
            circle(15, 12, 2);
            circle(10, 17, 2);
        }
    }
}
