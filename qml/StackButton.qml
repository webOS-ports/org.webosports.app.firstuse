/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Controls 1.0
import LunaNext.Common 0.1

BorderImage {
    id: stackButton

    property string text

    property bool backArrow: false

    signal clicked()

    height: label.height + Units.gu(4)

    source: backArrow ? "images/buttongrey.png" : "images/button-blue.png"

    border.left: 5
    border.right: 5
    border.top: 5
    border.bottom: 5

    Label {
        id: label
        anchors.centerIn: parent
        color: "white"
        text: {
            if (backArrow) {
                return "%1".arg(stackButton.text)
            } else {
                return "%1".arg(stackButton.text)
            }
        }
        font.pixelSize: FontUtils.sizeToPixels("medium")
        horizontalAlignment: backArrow ? Text.AlignLeft : Text.AlignRight
    }

    MouseArea {
        anchors.fill: parent
        onClicked: stackButton.clicked()
    }
}
