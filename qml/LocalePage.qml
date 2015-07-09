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
import LuneOS.Service 1.0
import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    id: localePage

    title: "Select your Language"
    forwardButtonSourceComponent: forwardButton

    property variant currentLocale: null
    property int currentLocaleIndex: 0

    NetworkIdCountryMapper {
        id: networkIdCountryMapper
    }
	
    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
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

        service.call("luna://com.palm.systemservice/setPreferences", JSON.stringify(request), setPrefsSuccess, setPrefsFailure);

        function setPrefsSuccess (message) {
            console.log("Herrie setPrefsSuccess")
                }

        function setPrefsFailure (message) {
            console.log("Herrie setPrefsFailure")
                }
    }

    Component.onCompleted: {
        networkIdCountryMapper.loadData()
        service.call("luna://com.palm.systemservice/getPreferences", JSON.stringify({keys: ["locale"]}), getPrefsSuccess, getPrefsFailure);

        function getPrefsSuccess(message) {
            console.log("Herrie getPrefsSuccess");
                    var response = JSON.parse(message.payload);

                    if (response.locale !== undefined) {
                        currentLocale = response.locale;
                        console.log("Current locale " + JSON.stringify(currentLocale));
                    }

                    // now we can fetch all possible values and setup our model
                    service.call("luna://com.palm.systemservice/getPreferenceValues", JSON.stringify({key: "locale"}), fetchLocalesSuccess, fetchLocalesFailure);

                    function fetchLocalesSuccess (message) {
                        console.log("Herrie fetchLocalelSuccess");
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
                                filteredLocaleModel.syncWithFilter();
                            }

                    function fetchLocalesFailure (message) {
                        console.log("Herrie unable to fetch locales")
                            }

                }

        function getPrefsFailure(message)
        {
            console.log("Herrie Unable to fetch prefs")
        }
    }

    ListModel {
        id: localeModel
        //dynamicRoles: true
    }

    ListModel {
        id: filteredLocaleModel
        property string filter: filterTextField.text
        onFilterChanged: syncWithFilter();

            function syncWithFilter() {
                filteredLocaleModel.clear()
                for( var i = 0; i < localeModel.count; ++i ) {
                    var localeItem = localeModel.get(i);
                    var filterLowered = filter.toLowerCase();
                    if( filterLowered.length === 0 ||
                        localeItem.languageName.toLowerCase().indexOf(filterLowered) >= 0 )
                    {
                        filteredLocaleModel.append(localeItem);
                    }
                }
                localeList.currentIndex = currentLocaleIndex
                localeList.positionViewAtIndex(currentLocaleIndex, ListView.Center)
            }
        }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)
        //clip: true

        TextField {
            id: filterTextField
            placeholderText: "Filter list..."
            height: Units.gu(4)
            font.pixelSize: Units.gu(36/13.5)
        }

		
        ListView {
            id: localeList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing - filterTextField.height
			clip: true

            model: filteredLocaleModel

            delegate: MouseArea {
                id: delegate
                anchors.right: parent.right
                anchors.left: parent.left
                height: Units.gu(4)
                Text {
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
