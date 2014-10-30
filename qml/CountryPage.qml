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
import "ConfigurationStore.js" as ConfigurationStore

BasePage {
    title: "Select your Country"
    forwardButtonSourceComponent: forwardButton

    property variant currentLocale: null
    property int currentCountryIndex: -1

    LunaService {
        id: getPreference
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "getPreferences"
    }

    LunaService {
        id: setPreferences
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "setPreferences"
    }

    LunaService {
        id: fetchAvailableCountries
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "getPreferenceValues"

        onResponse: function (message) {
            console.log("response: " + message.payload);
            var response = JSON.parse(message.payload);
            languageModel.clear();
            var numCountries = 0;
            if (response.locale && response.locale.length > 0) {
                for (var n = 0; n < response.locale.length; n++) {
                    var locale = response.locale[n];

                    if (locale.languageCode === ConfigurationStore.selectedLanguageCode) {
                        if (locale.countries && locale.countries.length > 0) {
                            for (var m = 0; m < locale.countries.length; m++) {
                                var country = locale.countries[m];

                                if (country.countryCode === currentLocale.countryCode) {
                                    if (currentCountryIndex === -1) {
                                        console.log("Current country is " + country.countryCode);
                                        currentCountryIndex = numCountries;
                                    }
                                }

                                languageModel.append({
                                    countryName: country.countryName,
                                    countryCode: country.countryCode
                                });

                                numCountries++;
                            }
                        }
                    }
                }
            }

            languageList.currentIndex = currentCountryIndex;
            languageList.positionViewAtIndex(currentCountryIndex, ListView.Center);
        }
    }

    Component.onCompleted: {
        getPreference.call(JSON.stringify({keys: ["locale"]}), function (message) {
            var response = JSON.parse(message.payload);

            console.log("response " + message.payload);

            if (response.locale !== undefined) {
                currentLocale = response.locale;
                console.log("Current locale " + JSON.stringify(currentLocale));
            }

            // now we can fetch all possible values and setup our model
            fetchAvailableCountries.call(JSON.stringify({key: "locale"}));
        }, function (message) { });
    }

    function applySelectedLocale() {
        var request = {
            locale: {
                "languageCode": ConfigurationStore.selectedLanguageCode,
                "countryCode": ConfigurationStore.selectedCountryCode,
                "phoneRegion": {
                    "countryCode": ConfigurationStore.selectedCountryCode,
                    "countryName": ConfigurationStore.selectedCountryName
                },
                "region": {
                    "countryCode": ConfigurationStore.selectedCountryCode,
                    "countryName": ConfigurationStore.selectedCountryName
                }
            }
        };

        setPreferences.call(JSON.stringify(request));
    }

    ListModel {
        id: languageModel
        dynamicRoles: true
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        ListView {
            id: languageList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing

            model: languageModel

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
                    text: countryName
                    font.bold: delegate.ListView.isCurrentItem
                }
                onClicked: {
                    languageList.currentIndex = index;
                    ConfigurationStore.selectedCountryCode = countryCode;
                    ConfigurationStore.selectedCountryName = countryName;
                    console.log("selected country is now " + ConfigurationStore.selectedCountryCode);
                    applySelectedLocale();
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
