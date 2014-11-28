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
import QtQuick.Layouts 1.0
import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    id: localePage

    title: "Select your Language"
    forwardButtonSourceComponent: forwardButton

    property variant currentLocale: null
    property int currentLocaleIndex: 0

    LunaService {
        id: getPreference
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "getPreferences"
    }

    LunaService {
        id: fetchAvailableLocales
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "getPreferenceValues"

        onResponse: function (message) {
            var response = JSON.parse(message.payload);
            localeModel.clear();

            if (response.locale && response.locale.length > 0) {
                var currentIndex = 0;
                for (var n = 0; n < response.locale.length; n++) {
                    var locale = response.locale[n];

                    for (var m = 0; m < locale.countries.length; m++) {
                        var country = locale.countries[m];

                        if (locale.languageCode === currentLocale.languageCode &&
                            country.countryCode === currentLocale.countryCode)
                        {
                            console.log("Current locale is " + locale.languageName + " (" + country.countryName + ")");
                            currentLocaleIndex = currentIndex;
                        }

                        localeModel.append({
                            languageName: locale.languageName,
                            languageCode: locale.languageCode,
                            countryName: country.countryName,
                            countryCode: country.countryCode
                        });

                        currentIndex++;
                    }
                }
            }

            localeList.currentIndex = currentLocaleIndex;
            localeList.positionViewAtIndex(currentLocaleIndex, ListView.Center);
        }
    }

    LunaService {
        id: setPreferences
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "setPreferences"
    }

    function applySelectedLocale(languageCode, countryCode, countryName) {
        var request = {
            locale: {
                "languageCode": languageCode,
                "countryCode": countryCode,
                "phoneRegion": {
                    "countryCode": countryCode,
                    "countryName": countryName
                }
            }
        };

        setPreferences.call(JSON.stringify(request));
    }

    Component.onCompleted: {
        getPreference.call(JSON.stringify({keys: ["locale"]}), function (message) {
            var response = JSON.parse(message.payload);

            if (response.locale !== undefined) {
                currentLocale = response.locale;
                console.log("Current locale " + JSON.stringify(currentLocale));
            }

            // now we can fetch all possible values and setup our model
            fetchAvailableLocales.call(JSON.stringify({key: "locale"}));
        }, function (message) { });
    }

    ListModel {
        id: localeModel
        dynamicRoles: true
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        ListView {
            id: localeList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing

            model: localeModel

            delegate: MouseArea {
                id: delegate
                anchors.right: parent.right
                anchors.left: parent.left
                height: Units.gu(4)
                Label {
                    id: name
                    anchors.fill: parent
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    text: languageName + " (" + countryName + ")"
                    font.bold: delegate.ListView.isCurrentItem
                }
                onClicked: {
                    localeList.currentIndex = index;
                    applySelectedLocale(languageCode, countryCode, countryName);
                }
            }
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Next"
            onClicked: {
                pageStack.next();
            }
        }
    }
}
