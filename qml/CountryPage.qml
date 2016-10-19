/*
* Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
* Copyright (C) 2015 Herman van Hazendonk <github.com@herrie.org>
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
*You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>
*/
import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.4
import LunaNext.Common 0.1
import LuneOS.Service 1.0
import firstuse 1.0
import "js/GlobalState.js" as GlobalState

BasePage {
    title: "Select your Country"
    forwardButtonSourceComponent: forwardButton
    keyboardFocusItem: filterTextField

    property variant currentRegion: null
    property int currentRegionIndex: -1

    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component.onCompleted: {
        service.call("luna://com.palm.systemservice/getPreferences", JSON.stringify({
                                              keys: ["region"]
                                          }), getPreferencesSuccess,
                           getPreferencesFailure)
    }

    function getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)
        if (response.region !== undefined) {
            currentRegion = response.region
        }
        service.call("luna://com.palm.systemservice/getPreferenceValues",JSON.stringify({
                                                      key: "region"
                                                  }), getPreferenceValuesSuccess, getPreferenceValuesFailure)
    }

    function getPreferenceValuesSuccess(message) {
        console.log("Preference values success")
        var response = JSON.parse(message.payload)
        countryModel.clear()
        if (response.region && response.region.length > 0) {
            for (var n = 0; n < response.region.length; n++) {
                var region = response.region[n]

                //First try to determine country based on MCC else based on preferences we got
                if (GlobalState.mccCountryCode !== null
                        && GlobalState.mccCountryCode === region.countryCode) {
                    currentRegionIndex = n
                    //We need to make sure we store the preferences here right away, otherwise they might not get stored due to the fact we don't need to select anything
                    applySelectedRegion(region.countryCode,
                                        region.countryName)
                } else if (currentRegion !== null
                           && currentRegion.countryCode === region.countryCode
                           && currentRegionIndex == -1) {
                    currentRegionIndex = n
                }

                countryModel.append({
                                       countryName: region.countryName,
                                       countryCode: region.countryCode
                                   })
            }
        }
        countryList.currentIndex = currentRegionIndex
        countryList.positionViewAtIndex(currentRegionIndex, ListView.Center)
        filteredCountryModel.syncWithFilter();
    }


    function getPreferenceValuesFailure(message) {
        console.log("Unable to get preference values")
    }

    function getPreferencesFailure(message) {
        //No region found, default to US
        currentRegion = '{"countryName":"United States","countryCode":"us"}'
        //We want to see if we can get the country based on the MCC of our sim card
        networkIdCountryMapper.loadData()
    }

    function applySelectedRegion(countryCode, countryName) {
        var request = {
            region: {
                "countryName": countryName,
                "countryCode": countryCode
            }
        }

        service.call("luna://com.palm.systemservice/setPreferences", JSON.stringify(request), function () {setPreferencesSuccess(request);}, setPreferencesFailure);

        function setPreferencesSuccess (request) {
            console.log("setPreferencesSuccess")
            currentRegion = request.region;
        }

        function setPreferencesFailure (message) {
            console.log("setPreferencesFailure")
                }

    }

    ListModel {
        id: countryModel
    }

    ListModel {
        id: filteredCountryModel

        property string filter: filterTextField.text
        onFilterChanged: syncWithFilter();

        function syncWithFilter() {
            filteredCountryModel.clear()
            var index = -1;
            for( var i = 0; i < countryModel.count; ++i ) {
                var countryItem = countryModel.get(i);
				var filterLowered = filter.toLowerCase();
                if( filterLowered.length === 0 ||
                    countryItem.countryName.toLowerCase().indexOf(filterLowered) >= 0 ||
                    countryItem.countryCode.toLowerCase().indexOf(filterLowered) >= 0 )
                {
                    filteredCountryModel.append(countryItem);
                    if ( (currentRegion.countryName === countryItem.countryName)
                       &&(currentRegion.countryCode === countryItem.countryCode) )
                    {
                        index = filteredCountryModel.count - 1;
                    }
                }
            }
            countryList.currentIndex = index
            countryList.positionViewAtIndex(index, ListView.Center)
        }
    }
	
    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        TextField {
            id: filterTextField
            placeholderText: "Filter list..."
            height: Units.gu(4)
            font.pixelSize: Units.gu(36/13.5)
            width: parent.width * 0.95
            style: TextFieldStyle {
                background: Rectangle {
                    radius: 5
                }
            }
        }

        ListView {
            id: countryList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing - filterTextField.height

			clip: true
			
            model: filteredCountryModel

            delegate: MouseArea {
                id: delegate
                height: Units.gu(4)
                width: countryList.width
                Text {
                    id: name
                    anchors.fill: parent
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    text: countryName
                    font.bold: delegate.ListView.isCurrentItem
                }
                onClicked: {
                    countryList.currentIndex = index
                    applySelectedRegion(countryCode, countryName)
                }
            }
        }
    }

    Component {
        id: forwardButton
        StackButton {
            text: "Next"
            onClicked: {
                pageStack.next()
            }
        }
    }
}
