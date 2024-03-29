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

import QtQuick 2.0
import QtQuick.Controls 2.0

import LuneOS.Service 1.0
import LunaNext.Common 0.1

BasePage {
    title: "License Agreement"
    forwardButtonText: "Accept"

    Component.onCompleted: loadFileContent()

    LunaService {
                id: service
                name: "org.webosports.app.firstuse"
                usePrivateBus: true
            }

    function loadFileContent() {
        var xhr = new XMLHttpRequest
        xhr.open("GET", "/usr/share/luneos-license-agreements/main_en.html");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if(xhr.responseText !=="")
                {
                    termsLabel.text = xhr.responseText;
                }
                else
                //Use a dummy file
                {
                    var xhr2 = new XMLHttpRequest
                    xhr2.open("GET", "../test/imports/firstuse/main_en.html");
                    xhr2.onreadystatechange = function() {
                        if (xhr.responseText === "" && xhr2.readyState === XMLHttpRequest.DONE ) {
                            if(xhr2.responseText !=="")
                            {
                                termsLabel.text = xhr2.responseText;
                            }
                        }
                    }
                    xhr2.send()
                }
            }
        }
        xhr.send()

    }


    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Text {
            id: label1
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            font.weight: Font.Bold
            text: "In order to use the device you have to accept the following license terms:"
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        Flickable {
            id: termsArea
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - label1.height - 2 * column.spacing
            contentHeight: termsLabel.height
            clip: true

            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds

            Text {
                id: termsLabel
                width: column.width
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: "white"
                linkColor: "#4db2ff"
                onLinkActivated: {
                    console.log("Link activated: " + link);
                    // Just do a LS2 call to open the link in the browser
                    service.call("luna://com.palm.applicationManager/open", JSON.stringify({"target": link}));
                }
            }
        }
    }
}
