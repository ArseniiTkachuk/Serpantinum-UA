import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../../../reusables"
import "../../../"

Item {
    id: root

    property var module: null
    property var widget: module

    readonly property bool isCompact: module ? module.isCompact : false
    readonly property var barWindow: module ? module.barWindow : null

    property bool showLayout: false
    property int circleSize: barWindow ? barWindow.s(isCompact ? 22 : 28) : (isCompact ? 22 : 28)

    property bool isSysVisible: (!module || module.moduleActive) && showLayout
    property color basePrimary: (ThemeBackend.primary !== undefined && ThemeBackend.primary !== "") ? ThemeBackend.primary : ThemeBackend.mauve

    function updateSubscription() {
        if (isSysVisible) {
            SysData.subscribe();
        } else {
            SysData.unsubscribe();
        }
    }

    Component.onCompleted: updateSubscription()
    Component.onDestruction: SysData.unsubscribe()
    onIsSysVisibleChanged: updateSubscription()

    property real targetWidth: ((!module || module.moduleActive) && sysLayout.implicitWidth > 0) ? (sysLayout.implicitWidth + (barWindow ? barWindow.s(isCompact ? 8 : 10) : (isCompact ? 8 : 10))) : 0
    property bool isFaceVisible: showLayout && targetWidth > 0

    implicitWidth: targetWidth
    implicitHeight: parent ? parent.height : 0

    Timer {
        running: (!module || module.moduleActive) && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: root.showLayout = true
    }

    transform: Translate {
        x: root.showLayout ? 0 : (barWindow ? barWindow.s(60) : 60)
        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    component SysMonCircle: Rectangle {
        id: circleRoot
        property real value: 0
        property string textVal: ""
        property string icon: ""
        property color accentColor: root.basePrimary
        property bool showText: textVal !== ""
        property bool initAnimTrigger: false

        property real animValue: initAnimTrigger ? value : 0
        Behavior on animValue { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        property real fillRatio: Math.max(0.0, Math.min(1.0, isNaN(animValue) ? 0.0 : animValue))

        implicitWidth: root.circleSize
        implicitHeight: root.circleSize
        width: implicitWidth
        height: implicitHeight
        radius: width / 2
        color: "transparent"
        border.width: 0

        Timer {
            running: (!module || module.moduleActive) && root.showLayout && !initAnimTrigger
            interval: 150
            onTriggered: initAnimTrigger = true
        }

        opacity: initAnimTrigger ? 1.0 : 0.0
        transform: Translate {
            y: initAnimTrigger ? 0 : (barWindow ? barWindow.s(15) : 15)
            Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
        }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Canvas {
            id: circleCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var cx = width / 2;
                var cy = height / 2;
                var strokeW = barWindow ? barWindow.s(2.2) : 2.2;
                var amp = barWindow ? barWindow.s(0.9) : 0.9;
                var radius = Math.min(cx, cy) - amp - (strokeW / 2) - (barWindow ? barWindow.s(0.4) : 0.4);
                if (radius <= 0) return;

                ctx.save();

                ctx.beginPath();
                ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
                ctx.strokeStyle = Qt.rgba(circleRoot.accentColor.r, circleRoot.accentColor.g, circleRoot.accentColor.b, 0.22);
                ctx.lineWidth = strokeW;
                ctx.stroke();

                if (circleRoot.fillRatio > 0.001) {
                    var totalP = 2 * Math.PI * radius;
                    var cycles = Math.max(5, Math.round(totalP / 8.5));
                    var freq = (Math.PI * 2 * cycles) / totalP;
                    var startAngle = -Math.PI / 2;
                    var sweepAngle = Math.PI * 2 * circleRoot.fillRatio;
                    var arcLen = totalP * circleRoot.fillRatio;
                    var steps = Math.max(6, Math.ceil(arcLen / 1.2));

                    ctx.beginPath();
                    for (var i = 0; i <= steps; i++) {
                        var t = i / steps;
                        var a = startAngle + sweepAngle * t;
                        var arcDist = (a - startAngle) * radius;
                        var wOff = amp * Math.sin(freq * arcDist);
                        var px = cx + (radius + wOff) * Math.cos(a);
                        var py = cy + (radius + wOff) * Math.sin(a);

                        if (i === 0) {
                            ctx.moveTo(px, py);
                        } else {
                            ctx.lineTo(px, py);
                        }
                    }

                    if (circleRoot.fillRatio >= 0.999) {
                        ctx.closePath();
                    }

                    ctx.strokeStyle = circleRoot.accentColor;
                    ctx.lineWidth = strokeW;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }

                var displayText = circleRoot.showText ? circleRoot.textVal : circleRoot.icon;
                var fontSize = circleRoot.showText
                    ? (barWindow ? barWindow.s(root.isCompact ? 7.5 : 9) : (root.isCompact ? 7.5 : 9))
                    : (barWindow ? barWindow.s(root.isCompact ? 9 : 11) : (root.isCompact ? 9 : 11));

                var fontFam = (ThemeBackend.fontFamily !== undefined && ThemeBackend.fontFamily !== "") ? ThemeBackend.fontFamily : "sans-serif";
                if (circleRoot.showText) {
                    ctx.font = "bold " + Math.round(fontSize) + "px \"" + fontFam + "\", sans-serif";
                } else {
                    ctx.font = "normal " + Math.round(fontSize) + "px \"" + ThemeBackend.iconFont + "\"";
                }

                var baseTextColor = (ThemeBackend.text !== undefined && ThemeBackend.text !== "") ? ThemeBackend.text : "#ffffff";

                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillStyle = baseTextColor;
                ctx.fillText(displayText, cx, cy);

                ctx.restore();
            }

            Component.onCompleted: circleCanvas.requestPaint()
            onWidthChanged: circleCanvas.requestPaint()
            onHeightChanged: circleCanvas.requestPaint()

            Connections {
                target: circleRoot
                enabled: root.isSysVisible
                function onFillRatioChanged() { circleCanvas.requestPaint(); }
                function onAccentColorChanged() { circleCanvas.requestPaint(); }
                function onTextValChanged() { circleCanvas.requestPaint(); }
                function onIconChanged() { circleCanvas.requestPaint(); }
                function onShowTextChanged() { circleCanvas.requestPaint(); }
            }

            Connections {
                target: root
                enabled: root.isSysVisible
                function onBasePrimaryChanged() { circleCanvas.requestPaint(); }
            }

            Connections {
                target: ThemeBackend
                enabled: root.isSysVisible
                function onIconFontChanged() { circleCanvas.requestPaint(); }
            }
        }
    }

    Row {
        id: sysLayout
        anchors.centerIn: parent
        spacing: barWindow ? barWindow.s(root.isCompact ? 5 : 6) : (root.isCompact ? 5 : 6)
        property int circleSize: root.circleSize

        SysMonCircle {
            value: isNaN(SysData.cpu) ? 0 : SysData.cpu / 100.0
            icon: String.fromCodePoint(0xF035B)
            accentColor: Qt.tint(root.basePrimary, Qt.rgba(1.0, 0.22, 0.22, 0.25))
        }

        SysMonCircle {
            value: isNaN(SysData.ramPercent) ? 0 : SysData.ramPercent / 100.0
            icon: String.fromCodePoint(0xF035C)
            accentColor: Qt.lighter(root.basePrimary, 1.15)
        }

        SysMonCircle {
            value: isNaN(SysData.temp) ? 0 : Math.max(0, Math.min(1, SysData.temp / 100.0))
            textVal: isNaN(SysData.temp) ? "0" : Math.round(SysData.temp).toString()
            icon: String.fromCodePoint(0xF050F)
            accentColor: Qt.darker(root.basePrimary, 1.15)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            FloatingController.showSystemUsage(root.barWindow ? root.barWindow.screen : null);
        }
    }
}
