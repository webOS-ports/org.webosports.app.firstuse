/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2014 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    id: page

    title: "Connect WiFi network"
    forwardButtonSourceComponent: forwardButton

    property string stackButtonText: "Skip"

    LunaService {
        id: setWanProp
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.wan"
        method: "set"

        onResponse: function(message){
            var response = JSON.parse(message.payload);
            if (!response.returnValue){
                console.error("Failed to enable WAN connectivity");
            }
            else {
                console.log("Successfully enabled WAN connectivity");
            }

        }
    }

    LunaService {
        id: setState
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.wifi"
        method: "setstate"
    }

    Timer {
        id: autoscanTimer
        repeat: true
        running: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: {
            findNetworks.call("{}");
        }
    }

    LunaService {
        id: findNetworks
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.wifi"
        method: "findnetworks"

        onResponse: function (message) {
            // console.log("response: " + message.payload);
            var response = JSON.parse(message.payload);
            networksModel.clear();
            if (response.foundNetworks && response.foundNetworks.length > 0) {
                for (var n = 0; n < response.foundNetworks.length; n++) {
                    var network = response.foundNetworks[n];
                    // console.log("Adding network " + network);
                    networksModel.append(network);
                    if (network.networkInfo.connectState !== undefined &&
                        network.networkInfo.connectState === "ipConfigured")
                        stackButtonText = "Next";
                }
            }
        }
    }

    LunaService {
        id: connectNetwork
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.wifi"
        method: "connect"

        onResponse: function (message) {
            console.log("response: " + message.payload);
        }
    }

    Component.onCompleted: {
        // enable WiFi by default
        setState.call(JSON.stringify({"state":"enabled"}));
        setWanProp.call(JSON.stringify({"disablewan":"off"}));
    }

    function connectStateToStr(state) {
        switch (state) {
        case "associating":
        case "associated":
            return "Connecting ...";
        default:
            break;
        }

        return "";
    }

    function isConnectingState(state) {
        switch (state) {
        case "associating":
        case "associated":
            return true;
        default:
            break;
        }

        return false;
    }

    ListModel {
        id: networksModel
        dynamicRoles: true
    }

    ColumnLayout {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Label {
            id: label
            anchors.left: parent.left
            anchors.right: parent.right
            color: "white"
            text: "Select network you want to connect to"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            Layout.fillHeight: false
            Layout.preferredHeight: label.contentHeight
        }

        Component {
            id: networkConnectPage
            NetworkConnectPage { }
        }

        ListView {
            id: networkList

            anchors.left: parent.left
            anchors.right: parent.right
            Layout.fillHeight: true
            clip: true

            model: networksModel

            header: Label {
                    text: "Searching for networks ..."
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    color: "white"
                    visible: networksModel.count === 0
                }

            footer: Label {
                text: ""
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: "red"
            }

            function setErrorMessage(message) {
                footerItem.text = message;
                footerItem.visible = true;
            }

            function clearErrorMessage() {
                footerItem.text = "";
                footerItem.visible = false;
            }

            delegate: MouseArea {
                width: networkList.width
                height: Units.gu(6)

                onClicked: {
                    networkList.clearErrorMessage();

                    // do nothing if we're already connected with the network
                    if (networkInfo.connectState !== undefined &&
                        networkInfo.connectState === "ipConfigured")
                        return;

                    if (networkInfo.profileId !== undefined) {
                        console.log("Connecting with profile id " + networkInfo.profileId);
                        connectNetwork.call(JSON.stringify({
                            profileId: networkInfo.profileId
                        }));
                    }
                    else if (networkInfo.availableSecurityTypes.indexOf("psk") !== -1 ||
                             networkInfo.availableSecurityTypes.indexOf("wep") !== -1) {
                        console.log("Connecting with network " + networkInfo.ssid);
                        pageStack.push({ item: networkConnectPage, properties: { ssid: networkInfo.ssid, securityTypes: networkInfo.availableSecurityTypes }});
                    }
                    else if (networkInfo.availableSecurityTypes.indexOf("ieee8021x") !== -1) {
                        console.log("Connecting with enterprise security ... NOT SUPPORTED YET!");
                        networkList.setErrorMessage("Enterprise security networks are not supported yet");
                    }
                    else if (networkInfo.availableSecurityTypes.indexOf("wps") !== -1) {
                        console.log("Connecting with WPS ... NOT SUPPORTED YET!");
                        networkList.setErrorMessage("WPS networks are not supported yet");
                    }
                    /* no security types means we have an open network */
                    else if (networkInfo.availableSecurityTypes.length === 0) {
                        // we're connecting to an open network so just connect to it
                        connectNetwork.call(JSON.stringify({
                            ssid: networkInfo.ssid
                        }));
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    Text {
                        text: networkInfo.ssid
                        font.pixelSize: FontUtils.sizeToPixels("medium")
                        color: "white"
                        Layout.fillWidth: true
                    }

                    Image {
                        id: connectedImage
                        source: "images/checkmark.png"
                        visible: (networkInfo.connectState !== undefined && networkInfo.connectState === "ipConfigured")
                    }

                    Label {
                        id: networkStatus
                        text: connectStateToStr(networkInfo.connectState)
                        visible: isConnectingState(networkInfo.connectState)
                        color: "white"
                        font.pixelSize: FontUtils.sizeToPixels("medium")
                    }

                    Image {
                        id: secureImage
                        source: "images/secure-icon.png"
                        visible: networkInfo.availableSecurityTypes !== undefined &&
                                 networkInfo.availableSecurityTypes.length > 0 &&
                                 networkInfo.availableSecurityTypes[0] !== "none"
                    }

                    Image {
                        id: signalImage
                        source: determineSignalImage()
                        function determineSignalImage() {
                            switch (networkInfo.signalBars) {
                            case 1:
                                return "images/wifi-icon-low.png";
                            case 2:
                                return "images/wifi-icon-average.png";
                            case 3:
                                return "images/wifi-icon-excellent.png";
                            default:
                                break;
                            }
                            return "images/wifi-icon-none.png";
                        }
                    }
                }
            }
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: stackButtonText
            onClicked: {
                pageStack.next();
            }
        }
    }
}
