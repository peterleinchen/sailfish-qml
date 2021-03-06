/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import org.nemomobile.time 1.0
import org.freedesktop.contextkit 1.0
import "../lockscreen"
import "../main"

Item {
    id: statusArea
    property bool updatesEnabled: true
    property bool recentlyOnDisplay: true
    property bool lockscreenMode
    property string iconSuffix: lipstickSettings.lowPowerMode ? ('?' + Theme.highlightColor) : ''
    property string mobileDataIconSuffix: '?' + (lipstickSettings.lowPowerMode ? Theme.highlightColor : mobileDataIconColor)
    property alias mobileDataIconColor: cellularStatusLoader.mobileDataColor
    property color color: lipstickSettings.lowPowerMode ? Theme.highlightColor : Theme.primaryColor

    onUpdatesEnabledChanged: if (updatesEnabled) recentlyOnDisplay = updatesEnabled
    height: batteryStatusIndicator.totalHeight
    width: parent.width

    Timer {
        interval: 3000
        running: !statusArea.updatesEnabled
        onTriggered: statusArea.recentlyOnDisplay = statusArea.updatesEnabled
    }

    Item {
        id: iconBar
        width: parent.width
        height: batteryStatusIndicator.height

        // Left side status indicators
        Row {
            id: leftIndicators
            height: batteryStatusIndicator.height
            spacing: Theme.paddingSmall
            BatteryStatusIndicator {
                id: batteryStatusIndicator
                color: statusArea.color
            }

            ProfileStatusIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            AlarmStatusIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            //XXX Headset indicator
            //XXX Call forwarding indicator

            Loader {
                active: Desktop.showDualSim
                visible: active
                sourceComponent: floatingIndicators
            }
        }

        // These indicators could be on either side, depending upon dual sim
        Component {
            id: floatingIndicators
            Row {
                spacing: Theme.paddingSmall
                BluetoothStatusIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !lockscreenMode && opacity > 0.0
                }
                LocationStatusIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !lockscreenMode && opacity > 0.0
                    recentlyOnDisplay: statusArea.recentlyOnDisplay
                }
            }
        }

        Item {
            id: centralArea
            anchors {
                top: iconBar.top
                bottom: iconBar.bottom
                left: leftIndicators.right
                leftMargin: Theme.paddingMedium
                right: rightIndicators.left
                rightMargin: Theme.paddingMedium
            }
            Loader {
                // If possible position this item centrally within the iconBar
                x: Math.max((iconBar.width - width)/2 - parent.x, 0)
                y: (parent.height - height)/2
                sourceComponent: lockscreenMode ? (Telephony.multiSimSupported ? null : operatorName) : timeText
            }
        }

        Component {
            id: timeText
            ClockItem {
                id: clock

                width: Math.min(implicitWidth, centralArea.width)
                updatesEnabled: recentlyOnDisplay
                color: Theme.primaryColor
                font { pixelSize: Theme.fontSizeMedium; family: Theme.fontFamilyHeading }

                Connections {
                    target: Lipstick.compositor
                    onDisplayAboutToBeOn: clock.forceUpdate()
                }
            }
        }
        Component {
            id: operatorName
            CellularNetworkNameStatusIndicator {
                maxWidth: centralArea.width
                color: statusArea.color
            }
        }

        // Right side status indicators
        Row {
            id: rightIndicators
            height: parent.height
            spacing: Theme.paddingSmall
            anchors {
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            VpnStatusIndicator {
                id: vpnStatusIndicator
                anchors.verticalCenter: parent.verticalCenter
                updatesEnabled: statusArea.recentlyOnDisplay
            }
            Loader {
                active: !Desktop.showDualSim
                visible: active
                sourceComponent: floatingIndicators
            }
            ConnectionStatusIndicator {
                id: connStatusIndicator
                anchors.verticalCenter: parent.verticalCenter
                updatesEnabled: statusArea.recentlyOnDisplay
            }
            Item {
                width: flightModeStatusIndicator.offline ? flightModeStatusIndicator.width : cellularStatusLoader.width
                height: iconBar.height
                visible: !!capabilityData.value || !!capabilityVoice.value || flightModeStatusIndicator.offline

                ContextProperty {
                    id: capabilityData
                    key: "Cellular.CapabilityData"
                }
                ContextProperty {
                    id: capabilityVoice
                    key: "Cellular.CapabilityVoice"
                }

                FlightModeStatusIndicator {
                    id: flightModeStatusIndicator
                    anchors.right: parent.right
                    updatesEnabled: statusArea.recentlyOnDisplay
                }

                Loader {
                    id: cellularStatusLoader
                    height: parent.height
                    active: Desktop.simManager.availableModemCount > 0
                    readonly property color mobileDataColor: item ? item.mobileDataColor : Theme.primaryColor
                    sourceComponent: Row {
                        property alias mobileDataColor: cellularNetworkTypeStatusIndicator.color
                        height: parent.height
                        opacity: 1.0 - flightModeStatusIndicator.opacity

                        CellularNetworkTypeStatusIndicator {
                            id: cellularNetworkTypeStatusIndicator
                            anchors.verticalCenter: parent.verticalCenter
                            color: Desktop.simManager.indexOfModem(Desktop.simManager.defaultDataModem) === 1 ? cellularStatus2.color : cellularStatus1.color
                        }

                        CellularStatus {
                            id: cellularStatus1
                            visible: Desktop.showDualSim || Desktop.activeSim == 1
                        }

                        CellularStatus {
                            id: cellularStatus2
                            modem: 2
                            visible: Desktop.showDualSim || Desktop.activeSim == 2
                        }
                    }
                }
            }
        }
    }
}
