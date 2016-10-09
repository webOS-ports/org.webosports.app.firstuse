/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2014-2015 Herman van Hazendonk <github.com@herrie.org>
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
import LuneOS.Service 1.0
import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    id: page

    title: "Connect WiFi network"
    forwardButtonSourceComponent: forwardButton

    property string stackButtonText: "Skip"

    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    function findNetworksSuccess (message) {
        console.log("findNetworksSuccess");
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

    function findNetworksFailure (message) {
        console.log("findNetworksFailure response: " + message.payload);
    }

    Component.onCompleted: {
        // enable WiFi by default
        service.call("luna://com.palm.wifi/setstate", JSON.stringify({"state":"enabled"}), setStateSuccess, setStateFailure);
        service.call("luna://com.palm.wan/set", JSON.stringify({"disablewan":"off"}), setDisableWanSuccess, setDisableWanFailure)
        service.subscribe("luna://com.palm.wifi/findnetworks",'{"subscribe":true}',findNetworksSuccess, findNetworksFailure);

        function setStateSuccess(message)
        {
            console.log("setStateSuccess");
        }

        function setStateFailure(message)
        {
            console.log("setStateFailure");
        }


        function setDisableWanSuccess(message){
                    var response = JSON.parse(message.payload);
                    if (!response.returnValue){
                        console.error("Failed to enable WAN connectivity");
                    }
                    else {
                        console.log("Successfully enabled WAN connectivity");
                    }
        }

        function setDisableWanFailure(message){
                                    console.error("setDisableWanFailure");
                                }


        ;
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

        Text {
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

            header: Text {
                    text: "Searching for networks ..."
                    font.pixelSize: FontUtils.sizeToPixels("medium")
                    color: "white"
                    visible: networksModel.count === 0
                }

            footer: Text {
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
                        service.call("luna://com.palm.wifi/connect", JSON.stringify({
                            profileId: networkInfo.profileId
                        }), connectNetworkSuccess, connectNetworkFailure )

                        function connectNetworkSuccess (message)
                        {
                            console.log("connectNetworkSuccess response: " + message.payload);
                        }

                        function connectNetworkFailure (message)
                        {
                            console.log("connectNetworkFailure");
                        }

                    }
                    else if (networkInfo.availableSecurityTypes.indexOf("psk") !== -1 ||
                             networkInfo.availableSecurityTypes.indexOf("wep") !== -1) {
                        console.log("Connecting with network " + networkInfo.ssid);
                        pageStack.push({ item: networkConnectPage, properties: { ssid: networkInfo.ssid, securityTypes: networkInfo.availableSecurityTypes }});
                    }
                    else if (networkInfo.availableSecurityTypes.indexOf("ieee8021x") !== -1) {
                        console.log("Connecting with enterprise security ... WIP!");
                        pageStack.push({ item: networkConnectPage, properties: { ssid: networkInfo.ssid, securityTypes: networkInfo.availableSecurityTypes }});
                    }
                    else if (networkInfo.availableSecurityTypes.indexOf("wps") !== -1) {
                        console.log("Connecting with WPS ... NOT SUPPORTED YET!");
                        networkList.setErrorMessage("WPS networks are not supported yet");
                    }
                    /* no security types means we have an open network */
                    else if (networkInfo.availableSecurityTypes.length === 0) {
                        // we're connecting to an open network so just connect to it
                        service.call("luna://com.palm.wifi/connect", JSON.stringify({
                            ssid: networkInfo.ssid
                        }), networkConnectSuccess, networkConnectFailure) 
					}

                    function networkConnectSuccess(message) {
                                console.log("networkConnectSuccess response: " + message.payload);
                    }

                    function networkConnectFailure(message) {
                                console.log("networkConnectFailure response: " + message.payload);
                                networkList.setErrorMessage("Unable to connect to: "+networkInfo.ssid+", reason: "+message.payload.errorText);
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
                        layer.mipmap: true
                        visible: (networkInfo.connectState !== undefined && networkInfo.connectState === "ipConfigured")
                    }

                    Text {
                        id: networkStatus
                        text: connectStateToStr(networkInfo.connectState)
                        visible: isConnectingState(networkInfo.connectState)
                        color: "white"
                        font.pixelSize: FontUtils.sizeToPixels("medium")
                    }

                    Image {
                        id: secureImage
                        source: "images/secure-icon.png"
                        layer.mipmap: true
                        visible: networkInfo.availableSecurityTypes !== undefined &&
                                 networkInfo.availableSecurityTypes.length > 0 &&
                                 networkInfo.availableSecurityTypes[0] !== "none"
                    }

                    Image {
                        id: signalImage
                        layer.mipmap: true
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
