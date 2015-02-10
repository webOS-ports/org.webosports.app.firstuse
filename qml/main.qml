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
import QtQuick.Window 2.0
import QtQuick.Controls 1.0
import LunaNext.Common 0.1

Window {
    id: window

    width: Settings.displayWidth
    height: Settings.displayHeight

    property variant pageList: [ "Welcome", "Locale", "Country", "TimeZone", "WiFi", "LicenseAgreement", "Finished" ]
    property int currentPage: 0

    Component.onCompleted: {
        window.visible = true;
    }

    function buildPagePath(index) {
        return pageList[index] + "Page.qml";
    }

    function finish() {
        Qt.quit();
    }

    StackView {
        id: pageStack
        anchors.fill: parent

        initialItem: Qt.resolvedUrl(buildPagePath(currentPage))

        function next() {
            if (currentPage < pageList.length - 1)
                currentPage += 1;
            pageStack.push(Qt.resolvedUrl(buildPagePath(currentPage)));
        }

        function back() {
            if (currentPage > 0)
                currentPage -= 1;
            pageStack.pop();
        }
    }
}
