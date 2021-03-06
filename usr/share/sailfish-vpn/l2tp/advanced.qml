import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

Column {
    property string defaultText

    function setProperties(providerProperties) {
        var getProperty = function(name) {
            if (providerProperties) {
                return providerProperties[name] || ''
            }
            return ''
        }

        var getYesProperty = function(name, default_value) {
            if (getProperty(name) === 'yes') {
                return true
            } else if (getProperty(name) === 'no') {
                return false
            }
            return !!default_value
        }

        l2tpPort.text = getProperty('L2TP.Port')
        l2tpListenAddress.text = getProperty('L2TP.ListenAddr')
        l2tpAuthFile.path = getProperty('L2TP.AuthFile')
        l2tpIPsecSaref.checked = getYesProperty('L2TP.IPsecSaref')
        // By default CHAP is being set in config if value is omitted
        if (getYesProperty('L2TP.RequireCHAP', true)) {
            l2tpReqAuth.setValue('auth-chap-required')
        } else if (getYesProperty('L2TP.RequirePAP')) {
            l2tpReqAuth.setValue('auth-pap-required')
        } else if (getYesProperty('L2TP.ReqAuth')) {
            l2tpReqAuth.setValue('auth-required')
        } else {
            l2tpReqAuth.setValue('no-auth')
        }
        l2tpChallenge.checked = getYesProperty('L2TP.Challenge')
        //l2tpAccessControl.checked = getYesProperty('L2TP.AccessControl')
        l2tpExclusive.checked = getYesProperty('L2TP.Exclusive')
        l2tpDefaultRoute.checked = getYesProperty('L2TP.DefaultRoute')
        l2tpLengthBit.checked = getYesProperty('L2TP.LengthBit')
        l2tpFlowBit.checked = getYesProperty('L2TP.FlowBit')
        l2tpTunnelRWS.text = getProperty('L2TP.TunnelRWS')
        // By default, redial is set if value is omitted, empty yes
        l2tpRedial.checked = getYesProperty('L2TP.Redial', true)
        l2tpRedialTimeout.text = getProperty('L2TP.RedialTimeout') || '10'
        l2tpMaxRedials.text = getProperty('L2TP.MaxRedials')
        l2tpTxBPS.text = getProperty('L2TP.TXBPS')
        l2tpRxBPS.text = getProperty('L2TP.RXBPS')

        pppdOptions.setProperties(providerProperties)
    }

    function updateProperties(providerProperties) {
        var updateProvider = function(name, value) {
            // If the value is empty/default, do not include the property in the configuration
            if (value != '' && value != '_default') {
                providerProperties[name] = value
            }
        }

        updateProvider('L2TP.Port', l2tpPort.text)
        updateProvider('L2TP.ListenAddr', l2tpListenAddress.text)
        updateProvider('L2TP.AuthFile', l2tpAuthFile.path)
        updateProvider('L2TP.IPsecSaref', l2tpIPsecSaref.checked ? 'yes' : 'no')
        updateProvider('L2TP.ReqAuth', l2tpReqAuth.currentIndex === 1 ? 'yes' : 'no')
        updateProvider('L2TP.RequirePAP', l2tpReqAuth.currentIndex === 2 ? 'yes' : 'no')
        updateProvider('L2TP.RequireCHAP', l2tpReqAuth.currentIndex === 3 ? 'yes' : 'no')
        updateProvider('L2TP.Challenge', l2tpChallenge.checked ? 'yes' : 'no')

        /*
        if (l2tpAccessControl.checked) {
            updateProvider('L2TP.AccessControl', 'yes')
        }
        */
        updateProvider('L2TP.Exclusive', l2tpExclusive.checked ? 'yes' : 'no')
        updateProvider('L2TP.DefaultRoute', l2tpDefaultRoute.checked ? 'yes' : 'no')
        updateProvider('L2TP.LengthBit', l2tpLengthBit.checked ? 'yes' : 'no')
        updateProvider('L2TP.FlowBit', l2tpFlowBit.checked ? 'yes' : 'no')
        updateProvider('L2TP.TunnelRWS', l2tpTunnelRWS.text)
        updateProvider('L2TP.Redial', l2tpRedial.checked ? 'yes' : 'no')
        updateProvider('L2TP.RedialTimeout', l2tpRedialTimeout.text)
        updateProvider('L2TP.MaxRedials', l2tpMaxRedials.text)
        updateProvider('L2TP.TXBPS', l2tpTxBPS.text)
        updateProvider('L2TP.RXBPS', l2tpRxBPS.text)

        pppdOptions.updateProperties(providerProperties)
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the authentication procedure
        //% "Authentication"
        text: qsTrId("settings_network-he-vpn_l2tp_authentication")
    }

    ConfigPathField {
        id: l2tpAuthFile

        //% "Authentication file"
        label: qsTrId("settings_network-la-vpn_l2tp_auth_file")
    }

    TextSwitch {
        id: l2tpIPsecSaref

        //% "Use IPsec SA tracking"
        text: qsTrId("settings_network-la-vpn_l2tp_ipsecsaref")
    }

    TextSwitch {
        id: l2tpChallenge

        //% "Use challenge authentication"
        text: qsTrId("settings_network-la-vpn_l2tp_challenge")
    }

    ConfigComboBox {
        id: l2tpReqAuth

        values: [ 'no-auth', 'auth-required', 'auth-pap-required', 'auth-chap-required' ]

        //% "Peer Authentication"
        label: qsTrId("settings_network-la-vpn_l2tp_req_auth")
    }

    /* Not currently implemented, as we need a mechanism to define the acceptable addresses
    TextSwitch {
        id: l2tpAccessControl

        //% "Access Control"
        text: qsTrId("settings_network-la-vpn_l2tp_access_control")
    }
    */

    SectionHeader {
        //: Settings pertaining to the communication channel
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_l2tp_communications")
    }

    TextSwitch {
        id: l2tpLengthBit

        //% "Use length bit"
        text: qsTrId("settings_network-la-vpn_l2tp_length_bit")
    }

    TextSwitch {
        id: l2tpFlowBit

        //% "Use flow bit"
        text: qsTrId("settings_network-la-vpn_l2tp_flow_bit")
    }

    ConfigTextField {
        id: l2tpTunnelRWS

        //% "Window size"
        label: qsTrId("settings_network-la-vpn_l2tp_tunnel_rws")
        inputMethodHints: Qt.ImhDigitsOnly
        nextFocusItem: l2tpTxBPS
    }

    ConfigTextField {
        id: l2tpTxBPS

        //% "Maximum receive bits/second"
        label: qsTrId("settings_network-la-vpn_l2tp_tx_bps")
        inputMethodHints: Qt.ImhDigitsOnly
        nextFocusItem: l2tpRxBPS
    }

    ConfigTextField {
        id: l2tpRxBPS

        //% "Maximum transmit bits/second"
        label: qsTrId("settings_network-la-vpn_l2tp_rx_bps")
        inputMethodHints: Qt.ImhDigitsOnly
        nextFocusItem: l2tpPort
    }

    SectionHeader {
        //: Settings pertaining to the l2tp service on the local device
        //% "L2TP service"
        text: qsTrId("settings_network-he-vpn_l2tp_service")
    }

    ConfigTextField {
        id: l2tpPort

        //% "Listen port"
        label: qsTrId("settings_network-la-vpn_l2tp_port")
        inputMethodHints: Qt.ImhDigitsOnly
        nextFocusItem: l2tpListenAddress
    }

    ConfigPasswordField {
        id: l2tpListenAddress

        //% "Listen address"
        label: qsTrId("settings_network-la-vpn_l2tp_listen_address")
    }

    TextSwitch {
        id: l2tpExclusive

        //% "Ensure exclusive instance"
        text: qsTrId("settings_network-la-vpn_l2tp_exclusive")
    }

    TextSwitch {
        id: l2tpDefaultRoute

        //% "Set as default route"
        text: qsTrId("settings_network-la-vpn_l2tp_default_route")
    }

    SectionHeader {
        //% "Redial"
        text: qsTrId("settings_network-he-vpn_l2tp_redial")
    }

    TextSwitch {
        id: l2tpRedial

        //% "Redial on disconnect"
        text: qsTrId("settings_network-la-vpn_l2tp_redial")
    }

    Column {
        width: parent.width
        enabled: l2tpRedial.checked
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation {}}
        height: opacity * implicitHeight

        ConfigTextField {
            id: l2tpRedialTimeout

            //% "Seconds before redial"
            label: qsTrId("settings_network-la-vpn_l2tp_redial_timeout")
            inputMethodHints: Qt.ImhDigitsOnly
            nextFocusItem: l2tpMaxRedials
        }

        ConfigTextField {
            id: l2tpMaxRedials

            //% "Maximum attempts"
            label: qsTrId("settings_network-la-vpn_l2tp_max_redials")
            inputMethodHints: Qt.ImhDigitsOnly
        }
    }

    PPPD {
        id: pppdOptions
    }
}
