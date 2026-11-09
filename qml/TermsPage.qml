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
import QtQuick.Controls 2.0

import LunaNext.Common 0.1

/*
 * The account server's terms of service, read before making a Community
 * Account (opened from CreateAccountPage). They are the server's words, so
 * they are shown as plain text: nothing in them is fetched or followed.
 * "I agree" ticks the box on the page before and goes back to it; Back goes
 * back without.
 */
BasePage {
    id: page

    title: "Terms of Service"
    customBack: true
    customForward: true
    forwardButtonText: "I agree"

    property string terms: ""

    signal agreedToTerms()

    onBackClicked: pageStack.pop()
    onForwardClicked: {
        agreedToTerms();
        pageStack.pop();
    }

    Flickable {
        id: flick
        objectName: "termsFlick"
        anchors.fill: content
        contentWidth: width
        contentHeight: termsText.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator { }

        Text {
            id: termsText
            objectName: "termsText"
            width: flick.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: page.terms
            color: "white"
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }
    }
}
