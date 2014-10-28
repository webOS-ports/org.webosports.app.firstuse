/*
 * Copyright (C) 2013 Canonical, Ltd.
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

import QtQuick 2.1
import QtQuick.Controls 1.0
import LunaNext.Common 0.1

Item {
    readonly property real buttonMargin: Units.gu(2)
    readonly property real buttonWidth: (width - buttonMargin * 2) / 2 -
                                        buttonMargin / 2
    readonly property real topMargin: Units.gu(8)
    readonly property real leftMargin: Units.gu(2)
    readonly property real rightMargin: Units.gu(2)

    // If you want to skip a page, mark skipValid false while you figure out
    // whether to skip, then set it to true once you've determined the value
    // of the skip property.
    property bool skipValid: true
    property bool skip: false

    property bool noTitle: false
    property bool hasBackButton: true
    property bool customBack: false
    property alias forwardButtonSourceComponent: forwardButton.sourceComponent
    property alias content: contentHolder

    property string title: ""
    property alias titleSize: titleLabel.font.pixelSize
    property bool needGlow: false

    signal backClicked()

    visible: false

    Image {
        id: background
        source: needGlow ? "images/bg.png" : "images/bg-noglow.png"
        anchors.fill: parent
    }

    // We want larger than even fontSize: "x-large", so we use a Text instead
    // of a Label.
    Text {
        id: titleLabel
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: topMargin
            leftMargin: leftMargin
            rightMargin: rightMargin
        }
        wrapMode: Text.Wrap
        text: title
        color: "white"
        font.pixelSize: Units.gu(4)
        visible: !noTitle
    }

    Item {
        id: contentHolder
        anchors {
            top: !noTitle ? titleLabel.bottom : parent.top
            left: parent.left
            right: parent.right
            bottom: backButton.top
            topMargin: Units.gu(4)
            leftMargin: leftMargin
            rightMargin: rightMargin
            bottomMargin: buttonMargin
        }
    }

    StackButton {
        id: backButton
        width: buttonWidth
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: buttonMargin
            bottomMargin: buttonMargin
        }
        z: 1
        text: "Back"
        visible: pageStack.depth > 1 && hasBackButton
        backArrow: true

        onClicked: customBack ? backClicked() : pageStack.back()
    }

    Loader {
        id: forwardButton
        width: buttonWidth
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: buttonMargin
            bottomMargin: buttonMargin
        }
        z: 1
    }
}
