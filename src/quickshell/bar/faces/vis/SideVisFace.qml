import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../../reusables"
import "../../../"

Item {
    id: root

    property var module: null
    property var widget: module

    readonly property bool isCompact: module ? module.isCompact : false
    readonly property var barWindow: module ? module.barWindow : null

    property bool showLayout: !barWindow || barWindow.isStartupReady
    property int barCount: 12
    property bool isVisVisible: (module ? module.moduleActive : true) && showLayout
    property bool isFaceVisible: showLayout
    property bool isSubscribed: false
    readonly property bool shouldSubscribe: isVisVisible

    onShouldSubscribeChanged: updateSubscription()

    function updateSubscription() {
        if (shouldSubscribe && !isSubscribed) {
            isSubscribed = true;
            Cava.registerConsumer();
        } else if (!shouldSubscribe && isSubscribed) {
            isSubscribed = false;
            Cava.unregisterConsumer();
        }
    }

    Connections {
        target: barWindow ? barWindow : null
        function onIsStartupReadyChanged() {
            if (barWindow && barWindow.isStartupReady) {
                root.showLayout = true;
            }
        }
    }

    Component.onCompleted: {
        if (!barWindow || barWindow.isStartupReady) {
            root.showLayout = true;
        }
        updateSubscription();
    }

    Component.onDestruction: {
        if (isSubscribed) {
            isSubscribed = false;
            Cava.unregisterConsumer();
        }
    }

    property real targetHeight: ((module ? module.moduleActive : true) && innerCol.implicitHeight > 0) ? (innerCol.implicitHeight + (barWindow ? barWindow.s(isCompact ? 18 : 22) : (isCompact ? 18 : 22))) : 0

    implicitHeight: targetHeight
    implicitWidth: parent ? parent.width : 0

    Timer {
        running: (module ? module.moduleActive : true) && barWindow && !root.showLayout
        interval: 100
        onTriggered: {
            if (barWindow && barWindow.isStartupReady) {
                root.showLayout = true;
            }
        }
    }

    property var barLevels: {
        let source = Cava.barLevels;
        let count = barCount;
        let out = [];
        if (!source || source.length === 0) {
            for (let i = 0; i < count; i++) out.push(0.0);
            return out;
        }
        for (let i = 0; i < count; i++) {
            let norm = count > 1 ? (i / (count - 1)) : 0;
            let srcIdx = Math.min(source.length - 1, Math.floor(Math.pow(norm, 1.4) * (source.length - 1)));
            let val = source[srcIdx] || 0.0;
            out.push(val < 0.04 ? 0.0 : Math.pow((val - 0.04) / 0.96, 1.25));
        }
        return out;
    }

    Column {
        id: innerCol
        anchors.centerIn: parent
        spacing: barWindow ? barWindow.s(root.isCompact ? 3 : 4) : (root.isCompact ? 3 : 4)

        Repeater {
            model: root.barCount
            delegate: Rectangle {
                height: barWindow ? barWindow.s(root.isCompact ? 3 : 4) : (root.isCompact ? 3 : 4)
                property real level: (root.barLevels && index < root.barLevels.length) ? root.barLevels[index] : 0.0
                property real minW: barWindow ? barWindow.s(root.isCompact ? 3 : 4) : (root.isCompact ? 3 : 4)
                property real maxW: (parent ? parent.width : 30) * 0.65
                width: Math.max(minW, level * maxW)
                radius: height * 0.5
                color: root.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve
                opacity: 0.45 + (level * 0.55)
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on width {
                    NumberAnimation {
                        duration: 55
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 55 }
                }
            }
        }
    }
}
