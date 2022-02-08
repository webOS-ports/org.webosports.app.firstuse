/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

import LunaNext.Common 0.1
import LuneOS.Service 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.LuneOS 2.0

BasePage {
    title: "Everything setup!"
    forwardButtonText: "Done!"

    signal accountsButtonClicked()

    LunaService {
                id: service
                name: "org.webosports.app.firstuse"
                usePrivateBus: true
            }

    Component {
        id: websiteDisplayPage
        WebsiteDisplayPage { }
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "Your device is now fully configured and ready to be used."
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "If you find any bugs please report them on <a href=\"https://github.com/webos-ports/luneos-testing/issues\">https://github.com/webos-ports/luneos-testing/issues</a> or if you want to support the development of LuneOS have a look at our Wiki <a href=\"http://webos-ports.org\">webos-ports.org</a>."
            color: "white"
            linkColor: "#4db2ff"
            font.pixelSize: FontUtils.sizeToPixels("medium")
            onLinkActivated: {
                console.log("Link activated: " + link);
                pageStack.push(websiteDisplayPage, { url: link, title: link, titleSize: FontUtils.sizeToPixels("large") });
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: Units.gu(2)
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "You can add (email/im/contacts) accounts right away"
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        Button {
            id: accountsButton
            width: buttonWidth
            text: "Add accounts"
            onClicked: accountsButtonClicked()
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: Units.gu(5)
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "Or you can now start using your device right away and add accounts later. Enjoy it!"
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }
    }

    onAccountsButtonClicked: {
            console.log("Launching Accounts app");
            service.call("luna://com.palm.applicationManager/launch",
                JSON.stringify({"id": "com.palm.app.accounts", "params":""}), successCB, handleLaunchAppError);
        }

    function handleLaunchAppError(message) {
            console.log("Could not start application com.palm.app.accounts: " + message);
    }

    function successCB(message) {
            console.log("Successfully started application com.palm.app.accounts: " + message);
    }

}
