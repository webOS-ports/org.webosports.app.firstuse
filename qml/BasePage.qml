/*
 * Copyright (C) 2013 Canonical, Ltd.
 * Copyright (C) 2016 Christophe Chapuis <chris.chapuis@gmail.com>
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

import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.LuneOS 2.0
import LunaNext.Common 0.1

Item {
    readonly property real buttonMargin: Units.gu(2)
    readonly property real buttonWidth: (width - buttonMargin * 2) / 2 -
                                        buttonMargin / 2
    readonly property real topMargin: Units.gu(3)
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
    property alias forwardButtonText: forwardButton.text
    property alias forwardButtonVisible: forwardButton.visible
    property alias content: contentHolder

    property string title: ""
    property alias titleSize: titleLabel.font.pixelSize
    property bool needGlow: false

    property Item keyboardFocusItem

    signal backClicked()
    signal forwardClicked()

    visible: false
    enabled: StackView.status === StackView.Active

    MouseArea {
        anchors.fill: parent
        enabled: keyboardFocusItem && keyboardFocusItem.activeFocus === true
        z: 1

        onPressed: {
            var cont = keyboardFocusItem.contains(mapToItem(keyboardFocusItem, mouse.x, mouse.y));
            if (!cont) {
                Qt.inputMethod.hide();
                keyboardFocusItem.focus = false;
            }
            mouse.accepted = false;
        }
    }

    Image {
        id: background
        source: needGlow ? "images/bg.png" : "images/bg-noglow.png"
        anchors.fill: parent
        layer.mipmap: true
    }

    // We want larger than even fontSize: "x-large", so we use a Text instead
    // of a Label.
    Label {
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
        font.pixelSize: Units.gu(3.9)
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

    Button {
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
        LuneOSButton.mainColor: LuneOSButton.grayColor

        onClicked: customBack ? backClicked() : pageStack.back()
    }

    Button {
        id: forwardButton
        width: buttonWidth
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: buttonMargin
            bottomMargin: buttonMargin
        }
        z: 1

        onClicked: {
            forwardClicked();
            pageStack.next();
        }

        LuneOSButton.mainColor: LuneOSButton.blueColor
    }
}
