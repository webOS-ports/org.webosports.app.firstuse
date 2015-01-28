
/*
* Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
* Copyright (C) 2015 Herman van Hazendnk <github.com@herrie.org>
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
import LunaNext.Common 0.1
import firstuse 1.0

BasePage {
    title: "Select your Country"
    forwardButtonSourceComponent: forwardButton

    property variant currentRegion: null
    property string mccCountryCode: ""
    property int currentRegionIndex: -1

    Item {
        id: mapper

        ListModel {
            id: dataModel
        }

        function loadData() {
            var xhr = new XMLHttpRequest
            var jsonSource = ""
            xhr.open("GET", "file:///etc/palm/mccInfo.json")
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE)
                    updateJSONModel(xhr.responseText)
            }
            xhr.send()
        }

        function updateJSONModel(source) {
            dataModel.clear()

            if (source === "") {
                return
            }

            var objectArray = JSON.parse(source)
            for (var key in objectArray) {
                var jo = objectArray[key]
                dataModel.append(jo)
            }

            handleUpdatedModel()
        }

        property variant __currentCall: null

        function handleUpdatedModel() {
            if (__currentCall) {
                __currentCall.cancel()
            } else {
                __currentCall = connectNetwork.subscribe(JSON.stringify({
                                                                            subscribe: true
                                                                        }))
            }
        }
    }

    LunaService {
        id: connectNetwork
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.telephony"
        method: "networkIdQuery"

        onResponse: function (message) {
            var response = JSON.parse(message.payload)
            var mcc = parseInt(response.extended.mccmnc.substring(0, 3))
            for (var n = 0; n < dataModel.count; n++) {
                var entry = dataModel.get(n)
                if (mcc === entry.mcc) {
                    mccCountryCode = entry.CountryCode.toLowerCase()
                    console.log("We found countrycode: "+mccCountryCode+" for MCC: "+response.extended.mccmnc.substring(0, 3))
                }
            }
            getRegions()
        }
    }

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
        id: fetchAvailableRegions
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "getPreferenceValues"

        onResponse: function (message) {
            var response = JSON.parse(message.payload)
            regionModel.clear()
            if (response.region && response.region.length > 0) {
                for (var n = 0; n < response.region.length; n++) {
                    var region = response.region[n]

                    //First try to determine country based on MCC else based on preferences we got
                    if (mccCountryCode !== null
                            && mccCountryCode === region.countryCode) {
                        currentRegionIndex = n
                    } else if (currentRegion !== null
                               && currentRegion.countryCode === region.countryCode
                               && currentRegionIndex == -1) {
                        currentRegionIndex = n
                    }

                    regionModel.append({
                                           countryName: region.countryName,
                                           countryCode: region.countryCode
                                       })
                }
            }

            regionList.currentIndex = currentRegionIndex
            regionList.positionViewAtIndex(currentRegionIndex, ListView.Center)
        }
    }

    Component.onCompleted: {
        getPreference.call(JSON.stringify({
                                              keys: ["region"]
                                          }), getPreferencesSuccess,
                           getPreferencesFailure)
    }

    function getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)
        if (response.region !== undefined) {
            currentRegion = response.region
        }
        //We want to see if we can get the country based on the MCC of our sim card
        mapper.loadData()
    }

    function getPreferencesFailure(message) {
        console.log("Unable to get preferences")
        //No region found, default to US
        currentRegion = '{"countryName":"United States","countryCode":"us"}'
        //We want to see if we can get the country based on the MCC of our sim card
        mapper.loadData()
    }

    function applySelectedRegion(countryCode, countryName) {
        var request = {
            region: {
                countryName: countryName,
                countryCode: countryCode
            }
        }

        setPreferences.call(JSON.stringify(request))
    }

    function getRegions() {
        // now we can fetch all possible values and setup our model
        fetchAvailableRegions.call(JSON.stringify({
                                                      key: "region"
                                                  }))
    }

    ListModel {
        id: regionModel
        dynamicRoles: true
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        ListView {
            id: regionList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing

            model: regionModel

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
                    regionList.currentIndex = index
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
