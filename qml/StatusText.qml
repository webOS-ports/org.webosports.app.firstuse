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
 * What a page has to say about what it is doing: a line of plain text (it
 * can come from a server), red when something failed, and under it in small
 * type the code of the failure, if there is one, to tell it apart and
 * report it.
 */
Column {
    id: root

    property alias text: line.text
    property bool isError: false
    //! The failure's code, "" for none.
    property string code: ""

    spacing: Units.gu(0.25)
    visible: line.text.length > 0

    Text {
        id: line
        objectName: "statusLine"
        width: root.width
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
        color: root.isError ? "#ff8a80" : "white"
        font.pixelSize: FontUtils.sizeToPixels("medium")
    }

    Text {
        objectName: "statusCode"
        width: root.width
        visible: root.isError && root.code !== ""
        textFormat: Text.PlainText
        text: "Error code: " + root.code
        color: "white"
        opacity: 0.6
        font.pixelSize: FontUtils.sizeToPixels("small")
    }
}
