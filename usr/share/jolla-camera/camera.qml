import QtQuick 2.1
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import com.jolla.camera 1.0
import "pages"

ApplicationWindow {
    id: window

    property var captureModel: null
    property bool galleryActive
    property bool galleryVisible
    property int galleryIndex

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    cover: Qt.resolvedUrl("cover/CameraCover.qml")

    initialPage: Component {
        MainCameraPage {
            viewfinder: videoOutput
        }
    }

    // viewfinder background
    Rectangle {
        parent: window
        anchors.fill: parent
        z: -1
        color: "black"
        visible: pageStack.depth < 2 && !pageStack.busy
    }

    VideoOutput {
        id: videoOutput

        z: -1
        width: window.width
        height: window.height

        Behavior on y {
            enabled: !galleryVisible
            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
        }
    }

    onApplicationActiveChanged: {
        if (applicationActive)
            Settings.updateLocation()
    }
}
