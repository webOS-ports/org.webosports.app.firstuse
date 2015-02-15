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
import LunaNext.Common 0.1
import LuneOS.Service 1.0
import firstuse 1.0
import "js/GlobalState.js" as GlobalState


BasePage {
    title: "Select your Timezone"
    forwardButtonSourceComponent: forwardButton

    property variant currentTimezone: null
    property string currentRegion: ""
    property int currentTimezoneIndex: -1
    property int currentDifference: -1
    property int currentTimezoneIndexPreferredTemp: -1
    property int currentTimezoneIndexPreferred: -1
    property int currentTimezoneIndexPreferredOffset: -1

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
        id: fetchAvailableTimezones
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
        service: "luna://com.palm.systemservice"
        method: "getPreferenceValues"

        onResponse: function (message) {
            var response = JSON.parse(message.payload)
            timezoneModel.clear()
            if (response.timeZone && response.timeZone.length > 0) {
                for (var n = 0; n < response.timeZone.length; n++) {
                    var timezone = response.timeZone[n]
                    if (currentRegion === timezone.CountryCode) {
                        currentTimezoneIndex = n
                        //For countries with multiple timezones, we need to have the preferred one
                        if(timezone.preferred) {
                            //Sometimes we have multiple preferred timezones per country, we need to make sure to pick the one with the right offset based on mcc
                            if(timezone.offsetFromUTC === GlobalState.mccOffsetFromUTC) {
                                currentTimezoneIndexPreferredOffset = n
                            }
                            //Otherwise just use the zone with the shortest offset compared to current MCC
                            else {
                                //Check if we already calculated a difference between a timezone and offset based on mcc
                                if(currentDifference == -1){
                                    currentDifference = Math.abs(timezone.offsetFromUTC-GlobalState.mccOffsetFromUTC)
                                    currentTimezoneIndexPreferredTemp = n
                                }
                                //Check if the difference for the current timezone is less compared to the previous difference stored
                                else if((timezone.offsetFromUTC-GlobalState.mccOffsetFromUTC)< currentDifference){
                                    currentDifference = Math.abs(timezone.offsetFromUTC-GlobalState.mccOffsetFromUTC)
                                    currentTimezoneIndexPreferredTemp = n
                                }
                            }
                        }
                    }

                    //Add each timezone to the model
                    timezoneModel.append({
                                           timezoneCity: timezone.City,
                                           timezoneDescription: timezone.Description,
                                           timezoneCountryCode: timezone.CountryCode,
                                           timezoneCountry: timezone.Country,
                                           timezoneSupportsDST: timezone.supportsDST,
                                           timezoneZoneID: timezone.ZoneID,
                                           timezoneOffsetFromUTC: timezone.offsetFromUTC,
                                           timezoneOffsetSign: timezone.offsetFromUTC.toString().substring(0,1) == "-" ? "-" : "+",
                                           timezoneOffsetHours: timezone.offsetFromUTC.toString().substring(0,1) == "-" ? Math.floor(timezone.offsetFromUTC.toString().substring(1)/60) + ":" +(timezone.offsetFromUTC.toString().substring(1)%60+"00").substring(0,2): Math.floor(timezone.offsetFromUTC.toString()/60) + ":" +(timezone.offsetFromUTC.toString()%60+"00").substring(0,2),
                                           timezonePreferred: timezone.preferred ? timezone.preferred : false
                                       })


                }

                //This is a bit nasty but it will help us to find the right timezone and store it.
                var timezone2
                //Take the closest match based on both country, mcc offset
                if(currentTimezoneIndexPreferredOffset !== -1) {
                    timezone2 = response.timeZone[currentTimezoneIndexPreferredOffset]
                }
                //Otherwise find closest "preferred" based on mcc
                else if(currentTimezoneIndexPreferredTemp !== -1) {
                    timezone2 = response.timeZone[currentTimezoneIndexPreferredTemp]
                }
                //Take any preferred that's available
                else if(currentTimezoneIndexPreferred !== -1) {
                    timezone2 = response.timeZone[currentTimezoneIndexPreferred]
                }
                //Otherwise just the country one (for countries with a single one)
                else {
                    timezone2 = response.timeZone[currentTimezoneIndex]
                }

                //Make sure to save the settings right away.
                applySelectedTimezone(timezone2.City, timezone2.Description, timezone2.CountryCode, timezone2.Country, timezone2.supportsDST, timezone2.ZoneID, timezone2.offsetFromUTC, timezone2.preferred)
            }

            //Make sure we select the right one in the list

            //If we don't have a closest match
            if(currentTimezoneIndexPreferredOffset == -1) {
                //And also none nearest to current mcc
                if(currentTimezoneIndexPreferredTemp == -1) {
                    //And also no preferred one, so defaulting to the available one (usually for countries with a single timezone only)
                    if(currentTimezoneIndexPreferred == -1) {
                        timezoneList.currentIndex = currentTimezoneIndex
                        timezoneList.positionViewAtIndex(currentTimezoneIndex, ListView.Center)
                    }
                    //Use the preferred one
                    else {
                        timezoneList.currentIndex = currentTimezoneIndexPreferred
                        timezoneList.positionViewAtIndex(currentTimezoneIndexPreferred, ListView.Center)
                    }
                }
                //Use the one nearest to the current mcc
                else {
                    timezoneList.currentIndex = currentTimezoneIndexPreferredTemp
                    timezoneList.positionViewAtIndex(currentTimezoneIndexPreferredTemp, ListView.Center)
                }
            }
            //We prefer the closest match
            else {
                timezoneList.currentIndex = currentTimezoneIndexPreferredOffset
                timezoneList.positionViewAtIndex(currentTimezoneIndexPreferredOffset, ListView.Center)
            }
        }
    }

    Component.onCompleted: {
        getPreference.call(JSON.stringify({
                                              keys: ["region", "timeZone"]
                                          }), getPreferencesSuccess,
                           getPreferencesFailure)
    }

    function getPreferencesSuccess(message) {
        var response = JSON.parse(message.payload)

        if (response.region.countryCode !== undefined) {
            currentRegion = response.region.countryCode.toUpperCase()
        }

        if (response.timeZone !== undefined) {
            currentTimezone = response.timeZone
        }
		
        // now we can fetch all possible values and setup our model
        fetchAvailableTimezones.call(JSON.stringify({
                                                      key: "timeZone"
                                                  }))
    }

    function getPreferencesFailure(message) {
        console.log("No region found")
    }

    function applySelectedTimezone(timezoneCity, timezoneDescription, timezoneCountryCode, timezoneCountry, timezoneSupportsDST, timezoneZoneID, timezoneOffsetFromUTC, timezonePreferred) {
        var request = {
            timeZone: {
                "City": timezoneCity,
                "Description": timezoneDescription,
                "CountryCode": timezoneCountryCode,
                "Country": timezoneCountry,
                "supportsDST": timezoneSupportsDST,
                "ZoneID": timezoneZoneID,
                "offsetFromUTC": timezoneOffsetFromUTC,
                "preferred": true
            }
        }
        setPreferences.call(JSON.stringify(request))
    }

    ListModel {
        id: timezoneModel
        dynamicRoles: true
    }

    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(1)

        ListView {
            id: timezoneList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing

            model: timezoneModel

            delegate: MouseArea {
                id: delegate
                anchors.right: parent.right
                anchors.left: parent.left
                height: tzCountry.height+tzCity.height > tzDescription.height+tzOffset.height ? tzCountry.height+tzCity.height + Units.gu(1) : tzDescription.height+tzOffset.height + Units.gu(1)//timezoneCity ? Units.gu(5) : Units.gu(4)
                Label {
                    id: tzCountry
                    width: parent.width / 2
                    anchors.top: parent.top
                    anchors.left: parent.left
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: timezoneCountry
                    font.bold: delegate.ListView.isCurrentItem
                    wrapMode: Text.Wrap
                }
                Label {
                    id: tzCity
                    width: parent.width / 2
                    anchors.top: tzCountry.bottom
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("x-small")
                    text: timezoneCity
                    font.bold: delegate.ListView.isCurrentItem
                    wrapMode: Text.Wrap
                }
                Label {
                    id: tzDescription
                    width: parent.width / 2
                    anchors.top: parent.top
                    anchors.right: parent.right
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: timezoneDescription
                    font.bold: delegate.ListView.isCurrentItem
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.Wrap
                }
                Label {
                    id: tzOffset
                    width: parent.width / 2
                    anchors.right: parent.right
                    anchors.top: tzDescription.bottom
                    color: "white"
                    font.pixelSize: FontUtils.sizeToPixels("x-small")
                    text: "GMT "+timezoneOffsetSign + timezoneOffsetHours
                    font.bold: delegate.ListView.isCurrentItem
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.Wrap
                }

                onClicked: {
                    timezoneList.currentIndex = index
                    applySelectedTimezone(timezoneCity, timezoneDescription, timezoneCountryCode, timezoneCountry, timezoneSupportsDST, timezoneZoneID, timezoneOffsetFromUTC, timezonePreferred)
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
