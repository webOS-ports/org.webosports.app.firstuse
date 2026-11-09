/*
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

/*
 * A link on First Use's dark pages: light blue, underlined, and tall enough
 * for a finger, that opens something within First Use.
 */
Text {
    id: root

    signal clicked()

    wrapMode: Text.Wrap
    textFormat: Text.PlainText
    color: enabled ? "#4db2ff" : "#7f7f7f"
    font.underline: true
    font.pixelSize: FontUtils.sizeToPixels("medium")
    height: Math.max(implicitHeight, Units.gu(4))
    verticalAlignment: Text.AlignVCenter

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && root.visible
        onClicked: root.clicked()
    }
}
