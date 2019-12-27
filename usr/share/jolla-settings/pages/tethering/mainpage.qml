import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Policy 1.0
import Nemo.Ssu 1.1 as Ssu
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.settings.system 1.0

Page {
    id: page

    property bool pageReady: wifiTethering.valid || page.status == PageStatus.Active
    onPageReadyChanged: if (pageReady) pageReady = true
    
    function checkIdPassphrase() {
        var ok = true
        if (networkNameInput.text.length < 1 || networkNameInput.length > 32) {
            networkNameInput.text = wifiTethering.identifier
            ok = false
        } else {
            if (wifiTethering.identifier !== networkNameInput.text)
                wifiTethering.identifier = networkNameInput.text
        }

        if (passwordInput.text.length < 8 || passwordInput.text.length > 63) {
            passphraseErrorLabel.visible = true
            ok = false
        } else {
            passphraseErrorLabel.visible = false
            if (wifiTethering.passphrase !== passwordInput.text)
                wifiTethering.passphrase = passwordInput.text
        }

        return ok
    }

    SilicaFlickable {
        id: content
        anchors.fill: parent
        contentHeight: column.height
        enabled: AccessPolicy.internetSharingEnabled && pageReady
        // FadeAnimator, animating in render thread, breaks if started
        // before window ready to render. So, do not use it here.
        // See bug #43341
        Behavior on opacity { FadeAnimation { duration: 400 } }
        opacity: pageReady ? 1.0 : 0.0

        SimActivationPullDownMenu {
            id: pullDownMenu
        }

        SimViewPlaceholder {
            id: mainPlaceholder
            simActivationPullDownMenu: pullDownMenu
        }

        Column {
            id: column

            width: page.width
            enabled: !mainPlaceholder.enabled
            opacity: 1 - mainPlaceholder.opacity
            spacing: Theme.paddingLarge

            PageHeader {
                //% "Share internet"
                title: qsTrId("settings_network-ph-tether")
            }

            DisabledByMdmBanner {
                active: !AccessPolicy.internetSharingEnabled
            }

            // WLAN hotspot #/# users
            ListItem {
                id: hotspotItem
                contentHeight: wlanSwitch.height
                openMenuOnPressAndHold: false
                _backgroundColor: "transparent"

                IconTextSwitch {
                    id: wlanSwitch

                    property string entryPath: "system_settings/connectivity/tethering/wlan_hotspot_switch"

                    //% "WLAN hotspot"
                    text: qsTrId("settings_network-la-wlan-hotspot")
                    //% "Share device's mobile connection through WLAN network others can join"
                    description: qsTrId("settings_network-me-share_mobile_connection")
                    icon.source: "image://theme/icon-m-wlan-hotspot"

                    busy: wifiTethering.busy
                    automaticCheck: false
                    checked: wifiTethering.active
                    highlighted: hotspotItem.highlighted
                    enabled: content.enabled
                             && !wifiTethering.offlineMode && passwordInput.text.length > 0
                             && networkNameInput.text.length > 0 && !wlanSwitch.busy
                             && (wifiTethering.roamingAllowed || wifiTethering.active)
                             && wifiTethering.autoConnect
                    onClicked: {
                        if (wifiTethering.busy) {
                            return
                        }

                        if (wifiTethering.active) {
                            wifiTethering.stopTethering()
                        } else if (page.checkIdPassphrase()) {
                            // work-around Qt not currently committing preedit when editor becomes read-only
                            Qt.inputMethod.commit()
                            wifiTethering.startTethering()
                        }
                    }
                }
            }

            Column {
                width: parent.width
                height: enabled ? implicitHeight : 0
                spacing: Theme.paddingMedium
                enabled: !wifiTethering.autoConnect && page.status == PageStatus.Active
                opacity: enabled ? content.enabled ? 1.0 : Theme.opacityLow : 0.0

                Behavior on opacity { FadeAnimator { } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                InfoLabel {
                    font.pixelSize: Theme.fontSizeLarge
                    //% "Mobile data connection is required"
                    text: qsTrId("settings_network-he-mobile_data_connection_required")
                }

                Button {
                    enabled: parent.enabled
                    anchors.horizontalCenter: parent.horizontalCenter
                    //% "Connect"
                    text: qsTrId("settings_network-me-connect")
                    onClicked: {
                        if (!wifiTethering.requestMobileData()) {
                            pageStack.animatorPush(Qt.resolvedUrl("../mobile/mainpage.qml"))
                        }
                    }
                }
            }

            TextField {
                id: networkNameInput
                width: parent.width
                anchors {
                    topMargin: Theme.paddingLarge
                }
                placeholderText: label
                inputMethodHints: Qt.ImhNoAutoUppercase
                readOnly: !content.enabled || wifiTethering.active || wlanSwitch.busy
                opacity: content.enabled ? 1.0 : Theme.opacityLow
                maximumLength: 32

                text: wifiTethering.identifier.length === 0 ? Ssu.DeviceInfo.displayName(Ssu.DeviceInfo.DeviceModel) : wifiTethering.identifier
                //% "Network name (SSID)"
                label: qsTrId("settings_network-la-tethering_network_name")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: {
                    passwordInput.focus = true
                }
                EnterKey.enabled: text.length > 0
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        page.checkIdPassphrase()
                    }
                }
            }

            SystemPasswordField {
                id: passwordInput
                readOnly: !content.enabled || wifiTethering.active || wlanSwitch.busy
                opacity: content.enabled ? 1.0 : Theme.opacityLow
                showEchoModeToggle: true
                maximumLength: 63
                text: wifiTethering.passphrase.length == 0 ? wifiTethering.generatePassphrase() : wifiTethering.passphrase
                placeholderText: label
                //% "Password (WPA Pre-shared key)"
                label: qsTrId("settings_network-la-hotspot_password")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    parent.focus = true
                }
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        page.checkIdPassphrase()
                    }
                }
            }
            Label {
                id: passphraseErrorLabel
                opacity: content.enabled ? 1.0 : Theme.opacityLow
                wrapMode: Text.Wrap
                anchors {
                    left: parent.left; leftMargin: Theme.horizontalPageMargin
                    right: parent.right; rightMargin: Theme.horizontalPageMargin
                }
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                visible: false
                //: Passphrase length requirement
                //% "Minimum length for passphrase is 8 characters"
                text: qsTrId("settings-la-passphrase-length")
            }
        }
    }

    MobileDataWifiTethering {
        id: wifiTethering
    }
}
