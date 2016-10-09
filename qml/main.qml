/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Herman van Hazendonk <github.com@herrie.org>
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
import LuneOS.Service 1.0
import LuneOS.Application 1.0

LuneOSWindow {
    id: window

    width: Settings.displayWidth
    height: Settings.displayHeight

    property variant pageList: [ "Welcome", "Locale", "Country", "TimeZone", "WiFi", "Feeds", "LicenseAgreement", "Finished" ]
    property int currentPage: 0

    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component.onCompleted: {
        //We only want to show the wifi page on devices that have acually wifi available. So we need to query device info first.
        service.call("luna://com.palm.systemservice/deviceInfo/query",
                     JSON.stringify({}),
                     gotDeviceInfoSuccess, gotDeviceInfoFailure)

        function gotDeviceInfoSuccess(message) {
            var response = JSON.parse(message.payload)
            if(response.device_name==="qemux86" || response.wifi_addr==="not supported"){
                pageList = [ "Welcome", "Locale", "Country", "TimeZone", "Feeds", "LicenseAgreement", "Finished" ];
            }
        }

        function gotDeviceInfoFailure(message) {
            console.log("Failed to get deviceInfo: " + message.payload);
        }

        window.show()
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

        initialItem: Qt.resolvedUrl(buildPagePath(0))
        property var pageItemList: [initialItem]

        function next() {
            if (currentPage < pageList.length - 1)
                currentPage += 1;
            if (currentPage > pageItemList.length - 1) {
                var page = pageStack.push({ item: Qt.resolvedUrl(buildPagePath(currentPage)), destroyOnPop: false });
                pageItemList.push(page);
            }
            else {
                pageStack.push(pageItemList[currentPage]);
            }
        }

        function back() {
            if (currentPage > 0)
                currentPage -= 1;
            pageStack.pop();
        }
    }
}
