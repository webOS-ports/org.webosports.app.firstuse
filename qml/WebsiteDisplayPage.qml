/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
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

import LuneOS.Components 1.0
import LunaNext.Common 0.1

BasePage {
    id: page

    property string url: ""

    forwardButtonVisible: false
    customBack: true

    LunaWebEngineView {
        id: webEngineView
        url: page.url
        anchors.fill: content

        ProgressBar {
            id: progressBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Units.gu(0.5)
            from: 0
            to: 100
            value: webEngineView.loadProgress
            visible: webEngineView.loading
            z: 1
        }
    }

    onBackClicked: {
        // go back to page which push us to the stack
        pageStack.pop()
    }
}
