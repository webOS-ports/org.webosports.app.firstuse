/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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
import LuneOS.System 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.LuneOS 2.0

BasePage {
    title: "Everything setup!"
    forwardButtonText: "Done!"

    // What to open once first use is over: neither can run while it does.
    // main.qml hands them to LunaAppManager when "Done!" is tapped.
    property alias restoreAfterSetup: restoreBox.checked
    property alias accountsAfterSetup: accountsBox.checked

    AppLauncher {
        id: launcher
        clientName: "org.webosports.app.firstuse"
    }

    // On a short screen (the Q25) the words and the accounts button do not
    // all fit above the page's buttons: they scroll.
    Flickable {
        id: flick
        objectName: "finishedFlick"
        anchors.fill: content
        contentWidth: width
        contentHeight: column.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator { }

        Column {
            id: column
            width: flick.width
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
                    launcher.open(link);
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
                text: "Once you tap Done, open:"
                color: "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            ChoiceBox {
                id: restoreBox
                objectName: "restoreAfterSetup"
                anchors.left: parent.left
                anchors.right: parent.right
                text: "Backup, to restore my data"
            }

            ChoiceBox {
                id: accountsBox
                objectName: "accountsAfterSetup"
                anchors.left: parent.left
                anchors.right: parent.right
                text: "Accounts, to add e-mail, contacts and calendars"
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
                text: "Or you can now start using your device right away and do both later. Enjoy it!"
                color: "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }
        }
    }
}
