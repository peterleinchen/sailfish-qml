import QtQuick 2.0
import MeeGo.Connman 0.2
import Nemo.Notifications 1.0

NetworkService {
    id: root

    property bool timeout

    function setup(path) {
        root.path = path
        if (path == "") {
            //% "Adding network failed"
            errorNotification.previewBody = qsTrId("settings_network-la-adding_network_failed")
            errorNotification.publish()
        } else if (timeout) {
            timer.restart()
        }
    }

    onAvailableChanged: if (available) outOfRangeTimer.stop()
    onConnectedChanged: if (connected) {
        timer.stop()
        outOfRangeTimer.stop()
    }
    onPropertiesReady: {
        if (path != "" && !available) {
            if (hidden) {
                outOfRangeTimer.restart()
                return
            }
            //% "Network out of range"
            errorNotification.previewBody = qsTrId("settings_network-la-network_out_of_range")
            errorNotification.publish()
            timer.stop()
            path = ""
        }
    }
    property Timer timer: Timer {
        interval: 6000
        onTriggered: {
            //% "Connecting to network failed"
            errorNotification.previewBody = qsTrId("settings_network-la-connecting_failed")
            errorNotification.publish()
        }
    }
    property Timer outOfRangeTimer: Timer {
        interval: 5000
        onTriggered: {
            errorNotification.previewBody = qsTrId("settings_network-la-network_out_of_range")
            errorNotification.publish()
            timer.stop()
            path = ""
        }
    }
    property Notification errorNotification: Notification {
        isTransient: true
        urgency: Notification.Critical
        icon: "icon-system-warning"
    }
}
