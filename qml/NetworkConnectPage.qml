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

import QtQuick 2.6
import QtQuick.Controls 2.0

import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    id: page

    property string ssid: ""
    property var securityTypes: []

    title: "Connect to " + ssid
    customBack: true
    customForward: true
    forwardButtonText: "Connect"

    // Carried out by the Wi-Fi page, which stays around for the answer: this
    // page is gone by the time a wrong passphrase is refused.
    signal connectRequested(var args)

    Item {
        anchors.fill: content

        MouseArea {
            anchors.fill: parent
            onPressed: {
                mouse.accepted = false;
                var selectedItem = column.childAt(mouse.x, mouse.y);
                if (!selectedItem)
                    selectedItem = column;
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
                objectName: "passphrase"

                height: Units.gu(4)

                anchors.left: parent.left
                anchors.right: parent.right

                font.pixelSize: FontUtils.sizeToPixels("medium")
                echoMode: showPassphrase.checked ? TextInput.Normal : TextInput.Password
                placeholderText: "Enter passphrase ..."
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
            page.connectRequested({
                ssid: page.ssid,
                security: {
                    securityType: "psk",
                    enterpriseSecurity: {
                        identityEAP: username.text,
                        passKey: passphrase.text
                   }
                }
            });
        }
        else
        {
            page.connectRequested({
                ssid: page.ssid,
                security: {
                    securityType: "psk",
                    simpleSecurity: {
                        passKey: passphrase.text
                   }
                }
            });
        }

        pageStack.pop();
    }

    onBackClicked: {
        // go back to page which push us to the stack
        pageStack.pop();
    }

    onForwardClicked: {
        page.connectNetwork();
    }
}
