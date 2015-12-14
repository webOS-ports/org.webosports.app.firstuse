/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
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
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import LuneOS.Service 1.0
import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    id: page

    property string ssid: ""
    property var securityTypes: []

    title: "Connect to " + ssid
    customBack: true
    forwardButtonSourceComponent: forwardButton

    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Item {
        anchors.fill: content

        MouseArea {
            anchors.fill: parent
            onPressed: {
                mouse.accepted = false;
                var selectedItem = root.childAt(mouse.x, mouse.y);
                if (!selectedItem)
                    selectedItem = root;
                selectedItem.focus = true;
            }
        }

        Column {
            id: column
            anchors.fill: parent
            spacing: Units.gu(1)

            TextField {
                id: username

                height: Units.gu(4)

                anchors.left: parent.left
                anchors.right: parent.right

                font.pixelSize: FontUtils.sizeToPixels("medium")
                echoMode: TextInput.Normal
                placeholderText: "Enter username ..."
                visible: securityTypes.indexOf("ieee8021x") !== -1

                onActiveFocusChanged: {
                    if (username.focus)
                        Qt.inputMethod.show();
                    else
                        Qt.inputMethod.hide();
                }
            }
            Text {
                id: usernameHint
                visible: false
                color: "red"
                text: "Please enter a username!"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            TextField {
                id: passphrase

                height: Units.gu(4)

                anchors.left: parent.left
                anchors.right: parent.right

                font.pixelSize: FontUtils.sizeToPixels("medium")
                echoMode: showPassphrase.checked ? TextInput.Normal : TextInput.Password
                placeholderText: "Enter passphrase ..."
                //Only becomes available in QT 5.5 with QtQuick.Controls.Styles 1.4
                //passwordCharacter: "\u2022"
                passwordCharacter: "•"
                onActiveFocusChanged: {
                    if (passphrase.focus)
                        Qt.inputMethod.show();
                    else
                        Qt.inputMethod.hide();
                }
            }

            Text {
                id: passphraseHint
                visible: false
                color: "red"
                text: "Please enter a passphrase!"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            CheckBox {
                id: showPassphrase
                checked: false
                text: "Show passphrase"
                style: CheckBoxStyle {
                    spacing: Units.gu(0.5)
                    label: Text {
                        color: "white"
                        font.pixelSize: FontUtils.sizeToPixels("medium")
                        text: control.text
                    }
                }
            }
        }
    }

    function connectNetwork() {
        usernameHint.visible = false;
        passphraseHint.visible = false;

        if(securityTypes.indexOf("ieee8021x") !== -1)
        {
            if (username.length === 0 || passphrase.length === 0) {
                if(username.length === 0)
                {
                    usernameHint.visible = true;
                }
                if(passphrase.length === 0)
                {
                    passphraseHint.visible = true;
                }
                return;
            }
        }

        if (passphrase.length === 0) {
            passphraseHint.visible = true;
            return;
        }

        if(securityTypes.indexOf("ieee8021x") !== -1)
        {
            service.call("luna://com.palm.wifi/connect",JSON.stringify({
                ssid: page.ssid,
                security: {
                    enterpriseSecurity: {
                        identityEAP: username.text,
                        passKey: passphrase.text
                   }
                }
            }), networkConnectSuccess, networkConnectFailure)
        }
        else
        {
            service.call("luna://com.palm.wifi/connect",JSON.stringify({
                ssid: page.ssid,
                security: {
                    simpleSecurity: {
                        passKey: passphrase.text
                   }
                }
            }), networkConnectSuccess, networkConnectFailure)
        }

        function networkConnectSuccess(message) {
                    console.log("networkConnectSuccess response: " + message.payload);
        }
        function networkConnectFailure(message) {
                    console.log("networkConnectFailure response: " + message.payload);
        }
        ;

        pageStack.pop();
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Connect"
            onClicked: page.connectNetwork()
        }
    }

    onBackClicked: {
        // go back to page which push us to the stack
        pageStack.pop()
    }
}
