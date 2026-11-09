/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
 * Copyright (C) 2016 Herman van Hazendonk <github.com@herrie.org>
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

import Eos.Window 0.1

import LunaNext.Common 0.1
import LuneOS.Service 1.0
import firstuse 1.0

WebOSWindow {
    id: window

    width: Settings.displayWidth
    height: Settings.displayHeight

    property variant pageList: [ "Welcome", "Locale", "Country", "TimeZone", "WiFi", "Feeds", "Updates", "LicenseAgreement", "Account", "Finished" ]

    LunaService {
        id: service
        objectName: "firstUseService"
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
            if(response.device_name.substring(0,7)==="qemux86"){
                pageList = [ "Welcome", "Locale", "Country", "TimeZone", "Feeds", "Updates", "LicenseAgreement", "Account", "Finished" ];
            }
        }

        function gotDeviceInfoFailure(message) {
            console.log("Failed to get deviceInfo: " + message.payload);
        }

        // Back from installing a system update (UpdatesPage): setup goes on
        // where it was, rather than from the start.
        service.call("luna://com.palm.systemservice/getPreferences",
                     JSON.stringify({ keys: [ "firstUseResume" ] }),
                     gotResume, function(message) { })

        function gotResume(message) {
            var response = null;
            try {
                response = JSON.parse(message.payload);
            } catch (e) {
                return;
            }
            if (response && response.returnValue === true && response.firstUseResume === "Updates")
                pageStack.resumeAt("Updates");
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

        property var _pageItemList: [] // memorize instances of pages
        property int _currentPage: 0

        Component.onCompleted: {
            pageStack.push(Qt.resolvedUrl(buildPagePath(0)));
            pageStack._pageItemList.push(pageStack.initialItem);
        }

        function next() {
            if (_currentPage < pageList.length - 1)
            {
                _currentPage += 1;
                if (_currentPage > _pageItemList.length - 1) {
                    var pageComp = Qt.createComponent( Qt.resolvedUrl(buildPagePath(_currentPage)) );

                    if (pageComp.status === Component.Error) {
                        // Error Handling
                        console.log("Error loading component:", pageComp.errorString());
                    }
                    var page = pageComp.createObject(pageStack);
                    pageStack.push(page);
                    _pageItemList.push(page);
                }
                else {
                    pageStack.push(_pageItemList[_currentPage]);
                }
            } else {
                // What the last page asked to open afterwards, written before
                // first use is marked done: that is what ends it.
                var last = pageStack.currentItem;
                FirstUseUtils.handOff(last.restoreAfterSetup === true, last.accountsAfterSetup === true);
                FirstUseUtils.markFirstUseDone();
                window.finish();
            }
        }

        // Straight to a page, as First Use starts, with nothing before it to
        // go back to. Only while the first page is all there is.
        function resumeAt(name) {
            var i = pageList.indexOf(name);
            if (i < 1 || _currentPage !== 0 || depth !== 1)
                return;
            var pageComp = Qt.createComponent(Qt.resolvedUrl(buildPagePath(i)));
            if (pageComp.status === Component.Error) {
                console.log("Error loading component:", pageComp.errorString());
                return;
            }
            var page = pageComp.createObject(pageStack, { resumed: true });
            pageStack.replace(page, {}, StackView.Immediate);
            var items = [];
            for (var k = 0; k < i; k++)
                items.push(null);
            items.push(page);
            _pageItemList = items;
            _currentPage = i;
        }

        function back() {
            if (_currentPage > 0)
                _currentPage -= 1;
            pageStack.pop();
        }
    }
}
