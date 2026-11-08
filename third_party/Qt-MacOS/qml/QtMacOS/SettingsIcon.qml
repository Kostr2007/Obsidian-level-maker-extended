import QtQuick

// Original small symbols for the Settings tiles, drawn without Apple assets.
Canvas {
    id: glyph
    property string name: "mouse"
    property color color: "white"
    implicitWidth: 28
    implicitHeight: 28
    renderTarget: Canvas.Image
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.clearRect(0, 0, width, height);
        c.scale(width / 28, height / 28);
        c.strokeStyle = color;
        c.fillStyle = color;
        c.lineWidth = 1.9;
        c.lineCap = "round";
        c.lineJoin = "round";
        function line(points, close) {
            c.beginPath();
            c.moveTo(points[0][0], points[0][1]);
            for (let i = 1; i < points.length; ++i)
                c.lineTo(points[i][0], points[i][1]);
            if (close)
                c.closePath();
            c.stroke();
        }
        function circle(x, y, r, fill) {
            c.beginPath();
            c.arc(x, y, r, 0, 2 * Math.PI);
            if (fill)
                c.fill();
            else
                c.stroke();
        }
        function box(x, y, w, h, r, fill) {
            c.beginPath();
            c.roundedRect(x, y, w, h, r, r);
            if (fill)
                c.fill();
            else
                c.stroke();
        }
        switch (name) {
        case "search":
            circle(11, 11, 7);
            line([[16, 16], [23, 23]]);
            break;
        case "notification":
            c.beginPath();
            c.moveTo(7, 19);
            c.lineTo(9, 16);
            c.lineTo(9, 11);
            c.bezierCurveTo(9, 4, 19, 4, 19, 11);
            c.lineTo(19, 16);
            c.lineTo(21, 19);
            c.closePath();
            c.fill();
            circle(14, 22, 1.6, true);
            circle(21, 6, 3, true);
            break;
        case "sound":
            line([[6, 11], [10, 11], [15, 7], [15, 21], [10, 17], [6, 17], [6, 11]], true);
            c.beginPath();
            c.arc(14, 14, 6, -.85, .85);
            c.stroke();
            c.beginPath();
            c.arc(14, 14, 10, -.85, .85);
            c.stroke();
            break;
        case "focus":
            circle(13, 14, 9, true);
            c.globalCompositeOperation = "destination-out";
            circle(18, 10, 8, true);
            c.globalCompositeOperation = "source-over";
            break;
        case "screentime":
            line([[8, 5], [20, 5], [20, 8], [15, 14], [20, 20], [20, 23], [8, 23], [8, 20], [13, 14], [8, 8], [8, 5]], true);
            line([[10, 8], [18, 8]]);
            line([[10, 21], [18, 21]]);
            break;
        case "lock":
        case "password":
            c.beginPath();
            c.arc(14, 11, 5, Math.PI, 2 * Math.PI);
            c.stroke();
            box(7, 11, 14, 12, 2.5, true);
            c.globalCompositeOperation = "destination-out";
            circle(14, 16, 1.5, true);
            box(13.4, 16, 1.2, 4, .4, true);
            c.globalCompositeOperation = "source-over";
            break;
        case "privacy":
            // A hand/shield suggests privacy without copying a platform asset.
            line([[8, 16], [8, 9], [11, 9], [11, 6], [14, 6], [14, 5], [17, 5], [17, 8], [20, 8], [20, 17], [17, 23], [11, 23], [6, 18], [5, 14], [7, 13], [10, 17]], false);
            break;
        case "users":
            circle(14, 8, 3.4, true);
            circle(6.5, 11, 2.5, true);
            circle(21.5, 11, 2.5, true);
            box(9, 14, 10, 9, 3.5, true);
            box(2.5, 16, 5, 6, 2, true);
            box(20.5, 16, 5, 6, 2, true);
            break;
        case "internet":
            c.font = "bold 24px sans-serif";
            c.textAlign = "center";
            c.textBaseline = "middle";
            c.fillText("@", 14, 14);
            break;
        case "game":
            c.fillStyle = "#f6b42d";
            circle(10, 10, 5, true);
            c.fillStyle = "#ef4c7b";
            circle(18, 10, 5, true);
            c.fillStyle = "#6b7ee8";
            circle(18, 18, 5, true);
            c.fillStyle = "#38cba0";
            circle(10, 18, 5, true);
            break;
        case "cloud":
            c.beginPath();
            c.moveTo(7, 21);
            c.bezierCurveTo(1, 21, 2, 12, 8, 12);
            c.bezierCurveTo(9, 3, 22, 4, 22, 13);
            c.bezierCurveTo(29, 15, 25, 22, 21, 21);
            c.closePath();
            c.fill();
            break;
        case "wallet":
            box(4, 5, 20, 18, 3, true);
            c.fillStyle = "#f3b540";
            box(6, 8, 16, 4, 1, true);
            c.fillStyle = "#71c6a4";
            box(6, 11, 16, 4, 1, true);
            c.fillStyle = "#e76f75";
            box(6, 14, 16, 4, 1, true);
            break;
        case "keyboard":
            box(3.5, 7, 21, 14, 2, false);
            c.lineWidth = 1.5;
            for (let x = 7; x < 23; x += 4) {
                line([[x, 11], [x + 1, 11]]);
                line([[x, 15], [x + 1, 15]]);
            }
            line([[9, 18], [19, 18]]);
            break;
        case "printer":
            box(8, 3, 12, 8, 1, false);
            box(4, 10, 20, 12, 2, false);
            c.fillStyle = color;
            circle(20, 13, 1, true);
            box(8, 17, 12, 8, .5, true);
            c.globalCompositeOperation = "destination-out";
            line([[11, 20], [17, 20]]);
            line([[11, 23], [17, 23]]);
            c.globalCompositeOperation = "source-over";
            break;
        case "mouse":
        default:
            box(8, 3, 12, 22, 6, true);
            c.globalCompositeOperation = "destination-out";
            box(13.2, 7, 1.6, 5, .8, true);
            c.globalCompositeOperation = "source-over";
            break;
        }
    }
}
