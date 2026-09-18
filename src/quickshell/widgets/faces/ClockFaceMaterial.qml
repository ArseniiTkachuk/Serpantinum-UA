import QtQuick
import "../../"

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 100
    property real minHeight: 100
    property real maxWidth: 900
    property real maxHeight: 900
    property real minAspect: 0.7
    property real maxAspect: 1.3
    property bool isRound: false

    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    readonly property string hoursStr: {
        if (typeof DateTime !== "undefined" && DateTime.hour !== undefined && String(DateTime.hour) !== "") {
            return String(DateTime.hour).padStart(2, "0");
        }
        return String(currentTime.getHours()).padStart(2, "0");
    }

    readonly property string minutesStr: {
        if (typeof DateTime !== "undefined" && DateTime.minute !== undefined && String(DateTime.minute) !== "") {
            return String(DateTime.minute).padStart(2, "0");
        }
        return String(currentTime.getMinutes()).padStart(2, "0");
    }

    Canvas {
        id: clockCanvas
        anchors.centerIn: parent
        width: {
            var availW = root.width * 0.94;
            var availH = root.height * 0.94;
            return (availW / availH > 0.80) ? availH * 0.80 : availW;
        }
        height: width / 0.80
        antialiasing: true

        property string hStr: root.hoursStr
        property string mStr: root.minutesStr
        property color colA: ThemeBackend.onSurface ?? ThemeBackend.text
        property color colB: ThemeBackend.primary ?? ThemeBackend.mauve

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onHStrChanged: requestPaint()
        onMStrChanged: requestPaint()
        onColAChanged: requestPaint()
        onColBChanged: requestPaint()

        function drawRoundRect(ctx, rx, ry, rw, rh, rad) {
            ctx.beginPath();
            ctx.moveTo(rx + rad, ry);
            ctx.lineTo(rx + rw - rad, ry);
            ctx.arcTo(rx + rw, ry, rx + rw, ry + rad, rad);
            ctx.lineTo(rx + rw, ry + rh - rad);
            ctx.arcTo(rx + rw, ry + rh, rx + rw - rad, ry + rh, rad);
            ctx.lineTo(rx + rad, ry + rh);
            ctx.arcTo(rx, ry + rh, rx, ry + rh - rad, rad);
            ctx.lineTo(rx, ry + rad);
            ctx.arcTo(rx, ry, rx + rad, ry, rad);
            ctx.closePath();
        }

        function drawDigit(ctx, ch, x, y, w, h, color) {
            if (ch === '6') {
                ctx.save();
                ctx.translate(x + w / 2, y + h / 2);
                ctx.rotate(Math.PI);
                drawDigit(ctx, '9', -w / 2, -h / 2, w, h, color);
                ctx.restore();
                return;
            }

            ctx.save();

            if (ch === '0') {
                drawRoundRect(ctx, x, y, w, h, w * 0.46);
                ctx.fillStyle = color;
                ctx.fill();

                ctx.globalCompositeOperation = "destination-out";
                drawRoundRect(ctx, x + w * 0.32, y + h * 0.24, w * 0.36, h * 0.52, w * 0.18);
                ctx.fillStyle = "#ffffff";
                ctx.fill();
            } else if (ch === '1') {
                ctx.beginPath();
                ctx.moveTo(x + w * 0.38, y);
                ctx.lineTo(x + w * 0.78, y);
                ctx.lineTo(x + w * 0.78, y + h);
                ctx.lineTo(x + w * 0.38, y + h);
                ctx.lineTo(x + w * 0.38, y + h * 0.32);
                ctx.lineTo(x + w * 0.08, y + h * 0.44);
                ctx.lineTo(x + w * 0.08, y + h * 0.22);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();
            } else if (ch === '2') {
                ctx.beginPath();
                ctx.moveTo(x + w * 0.05, y + h * 0.26);
                ctx.arcTo(x + w * 0.05, y, x + w * 0.5, y, w * 0.42);
                ctx.arcTo(x + w, y, x + w, y + h * 0.35, w * 0.42);
                ctx.lineTo(x + w, y + h * 0.38);
                ctx.lineTo(x + w * 0.38, y + h * 0.76);
                ctx.lineTo(x + w, y + h * 0.76);
                ctx.lineTo(x + w, y + h);
                ctx.lineTo(x, y + h);
                ctx.lineTo(x, y + h * 0.74);
                ctx.lineTo(x + w * 0.52, y + h * 0.28);
                ctx.arcTo(x + w * 0.52, y + h * 0.26, x + w * 0.4, y + h * 0.26, w * 0.12);
                ctx.lineTo(x + w * 0.05, y + h * 0.26);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();
            } else if (ch === '3') {
                ctx.beginPath();
                ctx.moveTo(x, y);
                ctx.lineTo(x + w, y);
                ctx.lineTo(x + w, y + h * 0.42);
                ctx.lineTo(x + w * 0.58, y + h * 0.42);
                ctx.lineTo(x + w * 0.58, y + h * 0.56);
                ctx.lineTo(x + w, y + h * 0.56);
                ctx.lineTo(x + w, y + h * 0.74);
                ctx.arcTo(x + w, y + h, x + w * 0.5, y + h, w * 0.44);
                ctx.lineTo(x, y + h);
                ctx.lineTo(x, y + h * 0.74);
                ctx.lineTo(x + w * 0.54, y + h * 0.74);
                ctx.arcTo(x + w * 0.64, y + h * 0.74, x + w * 0.64, y + h * 0.68, w * 0.1);
                ctx.lineTo(x + w * 0.45, y + h * 0.68);
                ctx.lineTo(x + w * 0.45, y + h * 0.30);
                ctx.lineTo(x, y + h * 0.30);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();
            } else if (ch === '4') {
                ctx.beginPath();
                ctx.moveTo(x + w * 0.64, y);
                ctx.lineTo(x + w * 0.24, y);
                ctx.lineTo(x, y + h * 0.62);
                ctx.lineTo(x, y + h * 0.80);
                ctx.lineTo(x + w * 0.64, y + h * 0.80);
                ctx.lineTo(x + w * 0.64, y + h);
                ctx.lineTo(x + w, y + h);
                ctx.lineTo(x + w, y);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();

                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.moveTo(x + w * 0.64, y + h * 0.22);
                ctx.lineTo(x + w * 0.26, y + h * 0.60);
                ctx.lineTo(x + w * 0.64, y + h * 0.60);
                ctx.closePath();
                ctx.fillStyle = "#ffffff";
                ctx.fill();
            } else if (ch === '5') {
                ctx.beginPath();
                ctx.moveTo(x, y);
                ctx.lineTo(x + w, y);
                ctx.lineTo(x + w, y + h * 0.26);
                ctx.lineTo(x + w * 0.38, y + h * 0.26);
                ctx.lineTo(x + w * 0.38, y + h * 0.48);
                ctx.lineTo(x + w * 0.60, y + h * 0.48);
                ctx.arcTo(x + w, y + h * 0.48, x + w, y + h * 0.74, w * 0.4);
                ctx.arcTo(x + w, y + h, x + w * 0.5, y + h, w * 0.4);
                ctx.lineTo(x, y + h);
                ctx.lineTo(x, y + h * 0.74);
                ctx.lineTo(x + w * 0.52, y + h * 0.74);
                ctx.arcTo(x + w * 0.64, y + h * 0.74, x + w * 0.64, y + h * 0.66, w * 0.1);
                ctx.lineTo(x, y + h * 0.66);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();
            } else if (ch === '7') {
                ctx.beginPath();
                ctx.moveTo(x, y);
                ctx.lineTo(x + w, y);
                ctx.lineTo(x + w, y + h * 0.28);
                ctx.lineTo(x + w * 0.40, y + h);
                ctx.lineTo(x + w * 0.12, y + h * 0.78);
                ctx.lineTo(x + w * 0.52, y + h * 0.28);
                ctx.lineTo(x, y + h * 0.28);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();
            } else if (ch === '8') {
                drawRoundRect(ctx, x, y, w, h, w * 0.46);
                ctx.fillStyle = color;
                ctx.fill();

                ctx.globalCompositeOperation = "destination-out";
                drawRoundRect(ctx, x + w * 0.30, y + h * 0.16, w * 0.40, h * 0.28, w * 0.14);
                ctx.fillStyle = "#ffffff";
                ctx.fill();
                drawRoundRect(ctx, x + w * 0.28, y + h * 0.54, w * 0.44, h * 0.32, w * 0.16);
                ctx.fill();
            } else if (ch === '9') {
                var rOuter = w * 0.48;
                var cx = x + w * 0.50;
                var cy = y + rOuter;

                ctx.beginPath();
                ctx.arc(cx, cy, rOuter, Math.PI, 0, false);
                ctx.lineTo(x + w * 0.40, y + h);
                ctx.lineTo(x + w * 0.14, y + h * 0.78);
                ctx.lineTo(x + w * 0.42, y + h * 0.48);
                ctx.arc(cx, cy, rOuter, Math.PI * 0.65, Math.PI, false);
                ctx.closePath();
                ctx.fillStyle = color;
                ctx.fill();

                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(cx, cy, w * 0.19, 0, Math.PI * 2, false);
                ctx.fillStyle = "#ffffff";
                ctx.fill();
            }

            ctx.restore();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var gapX = width * 0.04;
            var gapY = height * 0.03;
            var digitW = (width - gapX) / 2;
            var digitH = (height - gapY) / 2;

            var d1 = hStr.length > 0 ? hStr[0] : "0";
            var d2 = hStr.length > 1 ? hStr[1] : "0";
            var d3 = mStr.length > 0 ? mStr[0] : "0";
            var d4 = mStr.length > 1 ? mStr[1] : "0";

            drawDigit(ctx, d1, 0, 0, digitW, digitH, colA);
            drawDigit(ctx, d2, digitW + gapX, 0, digitW, digitH, colB);
            drawDigit(ctx, d3, 0, digitH + gapY, digitW, digitH, colB);
            drawDigit(ctx, d4, digitW + gapX, digitH + gapY, digitW, digitH, colA);
        }
    }
}
