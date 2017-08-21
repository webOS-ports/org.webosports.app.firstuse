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
import QtQuick.Controls 2.0

import LunaNext.Common 0.1

BasePage {
    noTitle: true
    forwardButtonText: "Continue"

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Image {
            anchors.left: parent.left
            anchors.right: parent.right
            source: "images/logostars.png"
            height: 400
            fillMode: Image.PreserveAspectFit
            layer.mipmap: true
        }

        Label {
            id: label1
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "Welcome to your LuneOS device."
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        Label {
            id: label2
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "Let’s get started."
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        Item { // spacer
            height: Units.gu(2)
            width: Units.gu(1) // needed else it will be ignored
        }
    }
}
