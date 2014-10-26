/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
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
        id: connectNetwork
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.wifi"
        method: "connect"

        onResponse: function (message) {
            console.log("response: " + message.payload);
        }
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Label {
            text: "Enter passphrase"
            color: "white"
        }

        Rectangle {
            color: "white"
            anchors.left: parent.left
            anchors.right: parent.right
            height: Units.gu(4)
            TextInput {
                id: passphrase
                anchors.fill: parent
                anchors.leftMargin: Units.gu(1)
                anchors.topMargin: Units.gu(1)
                anchors.bottomMargin: Units.gu(1)
                anchors.rightMargin: Units.gu(1)
                echoMode: TextInput.Password
                color: "black"
                focus: true
                clip: true
                font.pixelSize: FontUtils.sizeToPixels("medium")

                onActiveFocusChanged: {
                    Qt.inputMethod.show();
                }
            }
        }

        Label {
            id: passphraseHint
            visible: false
            color: "red"
            text: "Please enter a passphrase!"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Connect"
            onClicked: {
                if (passphrase.length === 0) {
                    passphraseHint.visible = true;
                    return;
                }

                passphraseHint.visible = false;

                connectNetwork.call(JSON.stringify({
                    ssid: page.ssid,
                    security: {
                        simpleSecurity: {
                            passphrase: passphrase.text
                       }
                    }
                }));

                pageStack.pop();
            }
        }
    }

    onBackClicked: {
        // go back to page which push us to the stack
        pageStack.pop()
    }
}
