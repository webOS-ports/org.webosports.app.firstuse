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
import QtWebKit 3.0
import LunaNext.Common 0.1
import "."

BasePage {
    title: "License Agreement"
    forwardButtonSourceComponent: forwardButton

    Component.onCompleted: loadFileContent()

    function loadFileContent() {
        var xhr = new XMLHttpRequest
        xhr.open("GET", "/usr/share/luneos-license-agreements/main_en.html");
        xhr.onreadystatechange = function() {
            if (xhr.readyState == XMLHttpRequest.DONE) {
                termsLabel.text = xhr.responseText;
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

        Label {
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
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - termsLabel.height - column.spacing - label1.height
            contentHeight: contentItem.childrenRect.height
            clip: true
            focus: true
            boundsBehavior: (contentHeight > height) ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds
            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                id: termsLabel
                wrapMode: Text.Wrap
                color: "white"
                linkColor: "grey"
                anchors.fill: parent
                textFormat: Text.AutoText
                onLinkActivated: {
                    console.log("Link activated: " + link);
                    pageStack.push({ item: websiteDisplayPage, properties: { url: link }});
                }
                font.pixelSize: FontUtils.sizeToPixels("medium")
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
