import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "../windowwrappers"
import "../compositor"

StackLayer {
    id: alarmLayer

    readonly property bool inCall: active && window && window.window.category == "call"

    objectName: "alarmLayer"
    childrenOpaque: window && window.renderBackground

    onQueueWindow: {
        if (window.window.category == "call") {
            contentItem.appendItem(window)
        } else {
            contentItem.prependItem(window)
        }
    }

    onCloseWindow: {
        if (window.window.surface) {
            window.window.surface.destroySurface()
        }
    }

    underlayItem.children: [
        Rectangle {
            width: alarmLayer.width
            height: alarmLayer.height
            color: Theme.highlightDimmerColor
            visible: alarmLayer.renderDialogBackground
            opacity: Theme.opacityLow
        },

        BlurredBackground {
            visible: alarmLayer.renderDialogBackground
            x: alarmLayer.backgroundRect.x
            y: alarmLayer.backgroundRect.y
            width: alarmLayer.backgroundRect.width
            height: alarmLayer.backgroundRect.height
            backgroundItem: Lipstick.compositor.dialogBlurSource
            color: Theme.rgba(Theme.highlightBackgroundColor, Theme.opacityHigh)
            radius: Theme.paddingLarge
        }
    ]
}
