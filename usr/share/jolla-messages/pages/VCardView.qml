import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import Sailfish.Contacts 1.0

Page {
    property alias model: view.model
    property int saveCount

    SilicaListView {
        id: view

        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //% "Save all contacts"
                text: qsTrId("messages-me-save_all_contacts")
                onClicked: {
                    saveCount = 0
                    for (var i = 0; i < model.count; ++i) {
                        if (MessageUtils.peopleModel.savePerson(model.getPerson(i))) {
                            ++saveCount
                        }
                    }
                    var previewBody
                    if (saveCount) {
                        //% "Saved %n contacts"
                        previewBody = qsTrId("messages-la-saved_n_contacts", saveCount)
                    } else {
                        //% "Error saving contacts"
                        previewBody = qsTrId("messages-la-error_saving_contacts")
                    }
                    mainPage.publishNotification(previewBody)
                }
            }
        }

        header: PageHeader {
            //% "Contacts"
            title: qsTrId("messages-he-contacts")
        }

        delegate: ContactItem {
            firstText: primaryName
            secondText: secondaryName
            iconSource: avatar
            onClicked: pageStack.animatorPush("ImportContactPage.qml", { 'contact': person })
        }
    }
}
