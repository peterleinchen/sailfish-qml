import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Telephony 1.0
import com.jolla.voicecall.settings.translations 1.0
import Nemo.Configuration 1.0
import org.nemomobile.ofono 1.0
import org.nemomobile.systemsettings 1.0
import MeeGo.QOfono 0.2
import MeeGo.Connman 0.2

Page {
    id: mainPage

    property bool clearingCounters
    property bool showRecordingsImmediately
    property bool pageReady: modemManager.ready || mainPage.status == PageStatus.Active
    onPageReadyChanged: if (pageReady) pageReady = true

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
            for (var i = 0; i < simCardSettingsRepeater.count; ++i) {
                simCardSettingsRepeater.itemAt(i).applyVoiceMailSettings()
            }
        } else if (status == PageStatus.Active) {
            if (showRecordingsImmediately) {
                showRecordingsImmediately = false
                callRecording.showRecordingsImmediately()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        enabled: pageReady
        Behavior on opacity { FadeAnimator {} }
        opacity: enabled ? 1.0 : 0.0

        PullDownMenu {
            MenuItem {
                //% "Clear call counters"
                text: qsTrId("settings_voicecall-me-clear_call_counters")
                enabled: AccessPolicy.callStatisticsSettingsEnabled
                onClicked: {
                    var page = mainPage
                    page.clearingCounters = true
                    var remorse = Remorse.popupAction(
                                page,
                                //% "Cleared call counters"
                                qsTrId("settings_voicecall-bt-cleared_call_counters"),
                                function () {
                                    callCounters.resetCounters()
                                    page.clearingCounters = false
                                })
                    remorse.canceled.connect(function () { page.clearingCounters = false } )
                }
            }
            MenuLabel {
                //: %1 is an operating system name without the OS suffix
                //% "Clearing of call counters disabled by %1 Device Manager"
                text: qsTrId("settings_voicecall-la-voicecall_data_clear_mdm_disabled")
                    .arg(aboutSettings.baseOperatingSystemName)
                visible: !AccessPolicy.callStatisticsSettingsEnabled
            }
        }
        Column {
            id: content
            width: parent.width
            PageHeader {
                //: Phone settings page header
                //% "Phone"
                title: qsTrId("settings_voicecall-he-phone")
            }

            ActivateSimCardView {
                id: disableFlightModeAction
                visible: networkFactory.instance.offlineMode
                width: parent.width
                //% "These settings are not available in flight mode"
                explanationText: qsTrId("settings_phone-he-not_available_in_flight_mode")
                //% "Disable flight mode"
                actionText: qsTrId("settings_phone-bt-disable_flightmode")
                onActionClicked: {
                    networkFactory.instance.offlineMode = false   // NOTE: also used to set modem.online=false
                }

                NetworkManagerFactory {
                    id: networkFactory
                }
            }

            Item {
                id: upperSimIndependentSettingsContainer

                width: parent.width
                height: simCardSettingsRepeater.count > 1 ? (simIndependentSettings.height + Theme.paddingLarge) : 0
                visible: height > 0
            }

            ExpandingSectionGroup {
                visible: !disableFlightModeAction.visible
                width: parent.width
                animateToExpandedSection: false
                currentIndex: sailfishSimManager.activeSim >= 0 ? sailfishSimManager.activeSim : 0

                Repeater {
                    id: simCardSettingsRepeater
                    width: parent.width
                    model: modemManager.availableModems
                    property var pendingResponses: []
                    delegate: ExpandingSection {
                        id: section

                        function applyVoiceMailSettings() { if (content.item) content.item.applyVoiceMailSettings() }

                        buttonHeight: (title.length && simCardSettingsRepeater.count > 1) ? Theme.itemSizeMedium : 0 // hide section header if only one simcard.
                        title: sailfishSimManager.ready ? sailfishSimManager.simNames[sailfishSimManager.indexOfModem(modelData)] : ""

                        content.sourceComponent: SimCardCallSettings {
                            width: section.width
                            modemPath: modelData
                            simManager: sailfishSimManager

                            onCallSettingsResponsePendingChanged: {
                                // disallow back navigation if any responses are pending.
                                if (callSettingsResponsePending) {
                                    simCardSettingsRepeater.pendingResponses[index] = true
                                    mainPage.backNavigation = false
                                } else {
                                    simCardSettingsRepeater.pendingResponses[index] = false
                                    for (var i = 0; i < simCardSettingsRepeater.count; ++i) {
                                        if (simCardSettingsRepeater.pendingResponses[index] === true) {
                                            return // some other response is still pending
                                        }
                                    }
                                    mainPage.backNavigation = true // no responses are still pending
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: lowerSimIndependentSettingsContainer

                width: parent.width
                height: simCardSettingsRepeater.count <= 1 ? simIndependentSettings.height : 0
                visible: height > 0
            }

            Column {
                id: simIndependentSettings

                parent: simCardSettingsRepeater.count > 1 ? upperSimIndependentSettingsContainer : lowerSimIndependentSettingsContainer
                width: parent.width
                spacing: Theme.paddingMedium

                CallCounters {
                    id: callCounters
                    clearingCounters: mainPage.clearingCounters
                }

                SectionHeader {
                    //% "Quick message reply"
                    text: qsTrId("settings_phone-he-quick_message_reply")
                }

                BackgroundItem {
                    height: quickMessagesColumn.height + 2 * quickMessagesColumn.y

                    onClicked: {
                        pageStack.animatorPush("QuickMessagesPage.qml")
                    }

                    Column {
                        id: quickMessagesColumn

                        width: parent.width - 2 * Theme.horizontalPageMargin
                        spacing: Theme.paddingSmall
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingMedium

                        Label {
                            width: parent.width
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.fontSizeExtraSmall

                            //: Description of the quick message reply feature
                            //% "You can set up to five quick reply messages that you can send after silencing an incoming call."
                            text: qsTrId("settings_phone-la-quick_message_reply_description")
                        }

                        Row {
                            width: parent.width

                            Label {
                                width: parent.width - editQuickRepliesIcon.width
                                anchors.verticalCenter: parent.verticalCenter
                                wrapMode: Text.Wrap

                                //: Label that user can tap to edit the quick message replies.
                                //% "Change quick replies"
                                text: qsTrId("settings_phone-la-quick_message_reply_edit")
                            }

                            HighlightImage {
                                id: editQuickRepliesIcon
                                source: "image://theme/icon-m-edit"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    SectionHeader {
                        //% "Call history"
                        text: qsTrId("settings_phone-he-call_history")
                    }
                    TextSwitch {
                        id: quickCallSwitch

                        onCheckedChanged: quickCallConfig.value = checked

                        //% "Quick call"
                        text: qsTrId("settings_phone-la-quick_call")
                        //% "Tap on call history list to call immediately"
                        description: qsTrId("settings_phone-la-tap_to_call")
                        width: parent.width
                        checked: quickCallConfig.value
                        ConfigurationValue {
                            id: quickCallConfig
                            key: "/jolla/voicecall/quickcall"
                            defaultValue: true
                        }
                    }
                }

                CallRecording {
                    id: callRecording
                }
            }
        }
    }

    OfonoModemManager { id: modemManager }
    SimManager { id: sailfishSimManager }

    AboutSettings {
        id: aboutSettings
    }
}
