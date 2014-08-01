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
    title: "Everything setup!"
    forwardButtonSourceComponent: forwardButton

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        Label {
            id: label1
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.Wrap
            text: "You can now start using your device. Enjoy it!"
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

    }

    Component {
        id: forwardButton
        StackButton {
            text: "Done!"
            onClicked: {
                FirstUseUtils.markFirstUseDone();
                window.finish();
            }
        }
    }
}
