import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import org.nemomobile.socialcache 1.0
import com.jolla.gallery.extensions 1.0

UsersPage {
    id: root

    socialNetwork: SocialSync.Dropbox
    dataType: SocialSync.Images
    usersModel: DropboxImageCacheModel {
        id: dropboxUsers
        Component.onCompleted: refresh()
        type: DropboxImageCacheModel.Users
        onCountChanged: {
            if (count === 0) {
                // no users left, return to gallery main level
                pageStack.pop(null)
            }
        }
    }
    userDelegate: UserDelegate {
        id: delegateItem
        serviceIcon: "image://theme/graphic-service-onedrive"
        title: model.title
        slideshowModel: DropboxImageCacheModel {
            Component.onCompleted: refresh()
            type: DropboxImageCacheModel.Images
            nodeIdentifier: delegateItem.userId == "" ? "" : "user-" + delegateItem.userId
            downloader: DropboxImageDownloader
        }
        onClicked: {
            window.pageStack.animatorPush(Qt.resolvedUrl("DropboxAlbumsPage.qml"),
                                          { "userId": delegateItem.userId, "title": root.title })
        }
    }
}
