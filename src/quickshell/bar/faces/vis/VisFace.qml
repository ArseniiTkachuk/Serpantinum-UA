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
    property int barCount: 16
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

            if (val < 0.04) {
                val = 0.0;
            } else {
                val = Math.pow((val - 0.04) / 0.96, 1.25);
            }
            out.push(val);
        }
        return out;
    }

    property real targetWidth: ((module ? module.moduleActive : true) && innerLayout.implicitWidth > 0) ? (innerLayout.implicitWidth + (barWindow ? barWindow.s(isCompact ? 20 : 24) : (isCompact ? 20 : 24))) : 0

    implicitWidth: targetWidth
    implicitHeight: parent ? parent.height : 0

    Timer {
        running: (module ? module.moduleActive : true) && barWindow && !root.showLayout
        interval: 100
        onTriggered: {
            if (barWindow && barWindow.isStartupReady) {
                root.showLayout = true;
            }
        }
    }

    Row {
        id: innerLayout
        anchors.centerIn: parent
        spacing: barWindow ? barWindow.s(root.isCompact ? 3 : 4) : (root.isCompact ? 3 : 4)

        Repeater {
            model: root.barCount
            delegate: Rectangle {
                width: barWindow ? barWindow.s(root.isCompact ? 4 : 5) : (root.isCompact ? 4 : 5)
                property real level: (root.barLevels && index < root.barLevels.length) ? root.barLevels[index] : 0.0
                property real minH: barWindow ? barWindow.s(root.isCompact ? 3 : 4) : (root.isCompact ? 3 : 4)
                property real maxH: (parent ? parent.height : 30) * 0.65
                height: Math.max(minH, level * maxH)
                radius: width * 0.5
                color: root.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve
                opacity: 0.45 + (level * 0.55)
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
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
