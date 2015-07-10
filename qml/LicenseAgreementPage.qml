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
import QtQuick.Controls.Styles 1.0
import QtWebKit 3.0
import LunaNext.Common 0.1
import "."

BasePage {
    title: "License Agreement"
    forwardButtonSourceComponent: forwardButton

    Component.onCompleted: loadFileContent()

    function loadFileContent() {
            var dummyText = "<html>
            <p>
            LuneOS is released for free non-commercial use.
            </p>

            <p>
            It is provided without warranty, even the implied warranty of
            merchantability, satisfaction or fitness for a particular use. See the
            licence includedwith each program for details.
            </p>

            <p>
            Some licences may grant additional rights.
            </p>

            <p>
            This notice shall not limit your rights under each program's licence.
            Licences for each program are available in the /usr/share/licenses
            directory. Source code for LuneOS can be downloaded from
            <a href=\"http://github.com/openwebos\">github.com/openwebos</a> and
            <a href=\"http://github.com/webOS-ports\">github.com/webOS-ports</a>.
            </p>

            <p>
            LuneOS is released for limited use due to the inclusion of binary hardware
            support files.
            </p>

            <p>
            The original components and licenses can be found at
            <a href=\"https://developers.google.com/android/nexus/drivers\">developers.google.com/android/nexus/drivers</a>
            </p>

            </html>";

        var xhr = new XMLHttpRequest
        xhr.open("GET", "/usr/share/luneos-license-agreements/main_en.html");
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                if(xhr.responseText !=="")
                {
                    termsLabel.text = xhr.responseText;
                }
                else
                {
                    termsLabel.text = dummyText;
                }
            }
        }
        xhr.send()
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
                textFormat: TextEdit.RichText
                font.pixelSize: FontUtils.sizeToPixels("medium")
                color: "white"
                onLinkActivated: {
                    console.log("Link activated: " + link);
                    pageStack.push({ item: websiteDisplayPage, properties: { url: link, title: link, titleSize: FontUtils.sizeToPixels("large") }});
                }
            }
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Accept"
            onClicked: {
                pageStack.next();
            }
        }
    }
}
