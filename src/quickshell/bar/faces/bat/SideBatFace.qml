import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Services.UPower
import "../../../reusables"
import "../../../"

Item {
    id: root

    property var module: null
    property var widget: module

    readonly property bool isCompact: module ? module.isCompact : false
    readonly property var barWindow: module ? module.barWindow : null

    property bool showLayout: false
    property alias batPill: batBtn

    property bool isDesktop: UPower.displayDevice.ready ? !UPower.displayDevice.isLaptopBattery : SystemInfo.isDesktop
    readonly property int batCap: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0
    readonly property bool isCharging: UPower.displayDevice.ready && (UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
    readonly property string batIcon: isDesktop ? "󰐥" : (isCharging ? "󰂄" : (batCap > 20 ? "󰁹" : "󰂃"))

    property color batDynamicColor: {
        if (isDesktop) return ThemeBackend.red;
        if (isCharging) return ThemeBackend.green;
        if (batCap <= 15) return ThemeBackend.red;
        if (batCap <= 25) return ThemeBackend.peach;
        return ThemeBackend.teal;
    }

    property real targetHeight: ((!module || module.moduleActive) && batBtn.height > 0) ? (batBtn.height + (barWindow ? barWindow.s(isCompact ? 8 : 10) : (isCompact ? 8 : 10))) : 0
    property bool isFaceVisible: showLayout && targetHeight > 0

    implicitHeight: targetHeight
    implicitWidth: parent ? parent.width : 0

    Timer {
        running: (!module || module.moduleActive) && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: root.showLayout = true
    }

    transform: Translate {
        y: root.showLayout ? 0 : (barWindow ? barWindow.s(60) : 60)
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    Rectangle {
        id: batBtn
        anchors.centerIn: parent
        width: barWindow ? barWindow.s(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
        height: barWindow ? barWindow.s(root.isCompact ? 26 : 28) : (root.isCompact ? 26 : 28)
        radius: Math.max(0, ThemeBackend.borderRadius - (barWindow ? barWindow.s(2) : 2))
        property color baseColor: root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
        color: batMouseArea.pressed ? Qt.darker(baseColor, 1.15) : (batMouseArea.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor)
        Behavior on color { ColorAnimation { duration: 150 } }
        property color baseBorderColor: root.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1
        border.color: batMouseArea.containsMouse ? ThemeBackend.surface2 : baseBorderColor
        Behavior on border.color { ColorAnimation { duration: 150 } }
        border.width: 1
        clip: true

        scale: batMouseArea.pressed ? 0.94 : (batMouseArea.containsMouse ? 1.04 : 1.0)
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        property real value: root.isDesktop ? 0.0 : (UPower.displayDevice.ready ? UPower.displayDevice.percentage : 0.0)
        property color baseAccentColor: root.batDynamicColor
        property color accentColor: batMouseArea.pressed ? Qt.darker(baseAccentColor, 1.15) : (batMouseArea.containsMouse ? Qt.lighter(baseAccentColor, 1.08) : baseAccentColor)
        property bool initAnimTrigger: false

        property real animValue: value
        Behavior on animValue { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        property real fillRatio: Math.max(0.0, Math.min(1.0, isNaN(animValue) ? 0.0 : animValue))
        property real fillY: height * (1.0 - fillRatio)

        Timer {
            running: (!module || module.moduleActive) && root.showLayout && !batBtn.initAnimTrigger
            interval: 150
            onTriggered: batBtn.initAnimTrigger = true
        }

        opacity: initAnimTrigger ? 1.0 : 0.0
        transform: Translate {
            x: batBtn.initAnimTrigger ? 0 : (barWindow ? barWindow.s(15) : 15)
            Behavior on x { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
        }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Canvas {
            id: sideBatCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (batBtn.fillRatio <= 0) return;

                ctx.save();
                var r = Math.max(0, Math.min(batBtn.radius, Math.min(width / 2, height / 2)));
                ctx.beginPath();
                ctx.moveTo(r, 0);
                ctx.lineTo(width - r, 0);
                ctx.quadraticCurveTo(width, 0, width, r);
                ctx.lineTo(width, height - r);
                ctx.quadraticCurveTo(width, height, width - r, height);
                ctx.lineTo(r, height);
                ctx.quadraticCurveTo(0, height, 0, height - r);
                ctx.lineTo(0, r);
                ctx.quadraticCurveTo(0, 0, r, 0);
                ctx.closePath();
                ctx.clip();

                ctx.beginPath();
                ctx.rect(0, batBtn.fillY, width, height - batBtn.fillY);
                ctx.closePath();

                var grad = ctx.createLinearGradient(0, height, 0, batBtn.fillY);
                grad.addColorStop(0, batBtn.accentColor.toString());
                grad.addColorStop(1, Qt.lighter(batBtn.accentColor, 1.25).toString());
                ctx.fillStyle = grad;
                ctx.globalAlpha = 0.95;
                ctx.fill();
                ctx.restore();
            }

            Connections {
                target: batBtn
                enabled: root.showLayout && (!module || module.moduleActive)
                function onRadiusChanged() { sideBatCanvas.requestPaint(); }
                function onFillRatioChanged() { sideBatCanvas.requestPaint(); }
                function onFillYChanged() { sideBatCanvas.requestPaint(); }
                function onAccentColorChanged() { sideBatCanvas.requestPaint(); }
            }
        }

        Item {
            id: sideContentBox
            anchors.centerIn: parent
            width: sideBatIconText.implicitWidth
            height: sideBatIconText.implicitHeight

            Text {
                id: sideBatIconText
                anchors.centerIn: parent
                text: root.batIcon
                font.family: ThemeBackend.fontFamily
                font.pixelSize: root.isDesktop ? (barWindow ? barWindow.s(root.isCompact ? 14 : 15) : (root.isCompact ? 14 : 15)) : (barWindow ? barWindow.s(root.isCompact ? 12 : 13) : (root.isCompact ? 12 : 13))
                color: root.isDesktop ? ThemeBackend.red : (root.isCompact ? ThemeBackend.text : ThemeBackend.subtext0)
            }
        }

        Item {
            id: sideWaveClipBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(parent.height, Math.max(0, parent.height - batBtn.fillY))
            clip: true
            visible: batBtn.fillRatio > 0

            Text {
                x: sideContentBox.x
                y: sideContentBox.y - batBtn.fillY
                text: sideBatIconText.text
                font.family: sideBatIconText.font.family
                font.pixelSize: sideBatIconText.font.pixelSize
                color: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.75)
            }
        }

        MouseArea {
            id: batMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["bash", "-c", Caching.serpantinumDir + "/scripts/qs_manager.sh toggle system"])
        }
    }
}
