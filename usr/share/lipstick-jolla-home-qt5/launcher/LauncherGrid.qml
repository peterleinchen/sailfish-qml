/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.4
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Policy 1.0
import Sailfish.Lipstick 1.0
import "../main"
import org.nemomobile.configuration 1.0

IconGridViewBase {
    id: gridview

    ConfigurationGroup {
        id: launcherGridSettings
        path: "/apps/lipstick-jolla-home-qt5/launcherGrid"
        property int columns: 4 // Math.floor(launcherPager.width / minimumCellWidth)
        property int rows: 6 // Math.floor(launcherPager.height / minimumCellHeight)
        property int lcolumns: 4
        property int lrows: 4
        property bool editLabelVisible: true
        property bool zoomIcons: false
        property bool zoomFonts: false
        property real zoomValue: 1.0
    }

    property bool isPortrait: launcherPager.height > launcherPager.width

    add: Transition {
        SequentialAnimation {
            NumberAnimation { properties: "z"; to: -1; duration: 1 }
            NumberAnimation { properties: "opacity"; to: 0.0; duration: 1 }
            NumberAnimation { properties: "x,y"; duration: 1 }
            NumberAnimation { properties: "z"; to: 0; duration: 200 }
            NumberAnimation { properties: "opacity"; from: 0.0; to: 1.0; duration: 100 }
        }
    }
    remove: Transition {
        ParallelAnimation {
            NumberAnimation { properties: "z"; to: -1; duration: 1 }
            NumberAnimation { properties: "x"; to: 0; duration: 100 }
            NumberAnimation { properties: "opacity"; to: 0.0; duration: 100 }
        }
    }
    move: Transition {
        NumberAnimation { properties: "x,y"; duration: 200 }
    }
    displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: 200 }
    }

    property bool launcherEditMode: removeApplicationEnabled
    property var launcherModel: model
    property bool rootFolder
    property QtObject folderComponent
    property Dialog openedChildFolder
    rows: isPortrait ? launcherGridSettings.rows : launcherGridSettings.lrows
    columns: isPortrait ? launcherGridSettings.columns : launcherGridSettings.lcolumns
    initialCellWidth: (launcherPager.width - 2*horizontalMargin) / (columns + (isPortrait ? 0 : 1))
    property alias reorderItem: gridManager.reorderItem
    property alias gridManager: gridManager
    signal itemLaunched

    onCellHeightChanged: updateHintHeight()
    Component.onCompleted: updateHintHeight()

    function updateHintHeight() {
        Lipstick.compositor.launcherLayer.hintHeight = cellHeight
    }

    function categoryQsTrIds() {
        //% "AudioVideo"
        QT_TRID_NOOP("lipstick-jolla-home-folder_audiovideo")
        //% "Audio"
        QT_TRID_NOOP("lipstick-jolla-home-folder_audio")
        //% "Video"
        QT_TRID_NOOP("lipstick-jolla-home-folder_video")
        //% "Development"
        QT_TRID_NOOP("lipstick-jolla-home-folder_development")
        //% "Education"
        QT_TRID_NOOP("lipstick-jolla-home-folder_education")
        //% "Game"
        QT_TRID_NOOP("lipstick-jolla-home-folder_game")
        //% "Graphics"
        QT_TRID_NOOP("lipstick-jolla-home-folder_graphics")
        //% "Network"
        QT_TRID_NOOP("lipstick-jolla-home-folder_network")
        //% "Office"
        QT_TRID_NOOP("lipstick-jolla-home-folder_office")
        //% "Science"
        QT_TRID_NOOP("lipstick-jolla-home-folder_science")
        //% "Settings"
        QT_TRID_NOOP("lipstick-jolla-home-folder_settings")
        //% "System"
        QT_TRID_NOOP("lipstick-jolla-home-folder_system")
        //% "Utility"
        QT_TRID_NOOP("lipstick-jolla-home-folder_utility")
    }

    function showFolder(folder) {
        if (openedChildFolder) {
            // should never happen
            openedChildFolder.close()
        }

        openedChildFolder = pageStack.push(Qt.resolvedUrl("LauncherFolder.qml"), { 'model': folder, 'launcherPager': launcherPager })
    }

    function setEditMode(enabled) {
        gridManager.setEditMode(enabled)
        removeApplicationEnabled = enabled
    }

    pageHeight: launcherPager.height

    EditableGridManager {
        id: gridManager
        supportsFolders: rootFolder
        pager: launcherPager
        view: gridview
        contentContainer: gridview.contentItem
        dragContainer: launcherPager
        onFolderIndexChanged: if (folderIndex == -1) newFolderIcon.active = false
    }

    Image {
        id: newFolderIcon
        property bool active
        property Item target
        property bool show: active && rootFolder && gridManager.folderIndex >= 0
        property string iconId: "icon-launcher-folder-01"
        source: "image://theme/" + iconId
        opacity: show ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
        y: target ? target.offsetY + target.iconOffset : -20000
        anchors.horizontalCenter: target ? target.horizontalCenter : gridview.contentItem.horizontalCenter
        scale: 1.3
        parent: gridview.contentItem
        z: -3

        onShowChanged: if (show) {
            var index = Math.floor(Math.min(Math.random() * 16, 15))
            iconId = "icon-launcher-folder-" + (index >= 9 ? (index + 1) : "0" + (index + 1))
        }
    }

    Connections {
        target: Lipstick.compositor
        onDisplayOff: setEditMode(false)
    }
    Connections {
        target: Lipstick.compositor.launcherLayer
        onActiveChanged: if (!Lipstick.compositor.launcherLayer.active) setEditMode(false)
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.ApplicationInstallationEnabled
    }

    delegate: EditableGridDelegate {
        id: wrapper
        property alias iconOffset: launcherIcon.y
        property Item uninstallButton
        property bool isUpdating: model.object.isUpdating
        property Item updatingItem

        width: cellWidth
        height: cellHeight
        manager: gridManager
        isFolder: model.object.type == LauncherModel.Folder
        folderItemCount: isFolder && model.object ? model.object.itemCount : 0
        editMode: gridview.launcherEditMode

        // This compresses the icons toward the center of the screen, leaving extra margin at the top and bottom
        offsetY: y - (((y-gridview.originY+height/2)%launcherPager.height)/launcherPager.height - 0.5) *
                 (largeScreen && rootFolder ? Theme.paddingLarge*4 : Theme._homePageMargin - Theme.paddingLarge)

        onEditModeChanged: {
            if (editMode && !uninstallButton && policy.value) {
                uninstallButton = uninstallButtonComponent.createObject(contentItem)
            }
        }

        onIsUpdatingChanged: {
            if (isUpdating && !updatingItem) {
                updatingItem = updatingComponent.createObject(contentItem)
            }
        }

        Timer {
            interval: 0
            running: object && !!object.isLaunching && !object.isUpdating
            onTriggered: {
                Desktop.instance.switcher.activateWindowFor(object, false)
            }
        }

        Connections {
            target: model.object
            ignoreUnknownSignals: true
            onItemRemoved: {
                var object = model.object
                if (object.itemCount === 1) {
                    // One item remains in folder. Replace folder with item.
                    var parentFolderIndex = object.parentFolder.indexOf(object)
                    object.parentFolder.moveToFolder(object.get(0), object.parentFolder, parentFolderIndex)
                    object.destroyFolder()
                }
            }
        }

        onReorder: {
            if (newFolderIndex >= 0 && newFolderIndex !== index) {
                if (!manager.folderItem.isFolder) {
                    newFolderIcon.target = manager.folderItem
                    newFolderIcon.active = true
                } else {
                    newFolderIcon.active = false
                }
                manager.folderIndex = newFolderIndex
            } else if (newIndex != -1 && newIndex !== index) {
                launcherModel.move(index, newIndex)
            }
        }

        scale: newFolderIcon.show && manager.folderIndex == index && !isFolder ? 0.5 : (reordering || manager.folderIndex == index ? 1.3 : 1)

        onClicked: {
            if (dragged) {
                return
            } else if (isFolder) {
                setEditMode(false)
                showFolder(model.object)
                // Ensure the launcher is visible - could be peeking from bottom due to hint.
                Lipstick.compositor.setCurrentWindow(Lipstick.compositor.launcherLayer.window)
            } else if (launcherEditMode) {
                setEditMode(false)
            } else {
                if (isUpdating) {
                    // Call launchApplication(), which will send a D-Bus signal
                    // for interested parties (non-store client) to pick it up
                    object.launchApplication()
                } else {
                    Desktop.instance.switcher.activateWindowFor(object, !object.isLaunching)
                }
                gridview.itemLaunched()
            }
        }

        onPressAndHold: {
            if (Lipstick.compositor.launcherLayer.active) {
                setEditMode(true)
            }
        }

        onEndReordering: {
            if (manager.folderIndex >= 0) {
                if (launcherModel.get(manager.folderIndex).type == LauncherModel.Application) {
                    //% "Folder"
                    var folder = launcherModel.createFolder(manager.folderIndex, qsTrId("lipstick-jolla-home-folder"))
                    if (folder) {
                        folder.iconId = newFolderIcon.iconId

                        var item1Categories = folder.get(0).desktopCategories
                        var item2Categories = model.object.desktopCategories
                        for (var i = 0; i < item1Categories.length; i++) {
                            if (item2Categories.indexOf(item1Categories[i]) >= 0) {
                                var id = "lipstick-jolla-home-folder_" + item1Categories[i].toLowerCase()
                                var title = qsTrId(id)
                                if (title != id) {
                                    folder.title = title
                                    break
                                }
                            }
                        }
                        launcherModel.moveToFolder(model.object, folder)
                    }
                } else {
                    launcherModel.moveToFolder(model.object, launcherModel.get(manager.folderIndex))
                }
                manager.folderIndex = -1
                newFolderIcon.active = false
            }
        }
        onReleased: {
            if (!rootFolder && gridview.mapFromItem(wrapper.contentItem, 0, 0).y + launcherIcon.size < 0) {
                var parentFolderIndex = launcherModel.parentFolder.indexOf(launcherModel)
                launcherModel.parentFolder.moveToFolder(model.object, launcherModel.parentFolder, parentFolderIndex+1)
            }
        }

        FolderIconLoader {
            id: launcherIcon
            anchors {
                centerIn: parent
                verticalCenterOffset: Math.floor(-launcherText.height/2)
            }
            icon: model.object.iconId
            folder: model.object
            pressed: down
            opacity: isUpdating && folderItemCount == 0 ? Theme.opacityFaint : 1.0
            size: Theme.iconSizeLauncher * (launcherGridSettings.zoomIcons ? launcherGridSettings.zoomValue : 1.0)
            Text {
                font.pixelSize: Theme.fontSizeExtraLarge * (launcherGridSettings.zoomIcons ? launcherGridSettings.zoomValue : 1.0)
                font.family: Theme.fontFamilyHeading
                text: folderItemCount > 0 ? folderItemCount : ""
                color: Theme.lightPrimaryColor
                anchors.centerIn: parent
                visible: launcherIcon.index < 16 && (!launcherEditMode || isFolder || launcherGridSettings.editLabelVisible)
                opacity: reorderItem && folderItemCount >= 99 ? Theme.opacityLow : 1.0
            }
        }

        Text {
            id: launcherText

            anchors {
                top: launcherIcon.bottom
                topMargin: gridview.launcherItemSpacing
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingSmall/2
                rightMargin: Theme.paddingSmall/2
            }
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight

            color: down ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: gridview.launcherLabelFontSize
            text: object.title.replace(/\n|\r/g, " ")
            textFormat: Text.PlainText
            visible: !launcherEditMode || isFolder
        }

        Component {
            id: updatingComponent
            BusyIndicator {
                anchors.centerIn: launcherIcon
                running: model.object.isUpdating
                opacity: running
                Behavior on opacity { FadeAnimation {} }
                Label {
                    anchors.centerIn: parent
                    text: model.object.updatingProgress + '%'
                    visible: model.object.isUpdating && model.object.updatingProgress >= 0 && model.object.updatingProgress <= 100
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        Component {
            id: uninstallButtonComponent
            UninstallButton {
                anchors.verticalCenter: launcherIcon.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: launcherEditMode && policy.value
                opacity: enabled ? 1.0 : 0.0
                visible: launcherEditMode
                            && !isFolder
                            && AppControl.isUninstallable(object.filePath)
                            && !object.isUpdating
                            && object.readValue("X-apkd-apkfile").indexOf("/vendor/app/") != 0
                            && object.readValue("X-apkd-apkfile").indexOf("/home/.android/vendor/app/") != 0
                onClicked: removeApplication(object.filePath, object.title)
            }
        }
    }
}
