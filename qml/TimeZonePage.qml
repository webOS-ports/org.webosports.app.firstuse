/*
* Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
* Copyright (C) 2015-2016 Herman van Hazendonk <github.com@herrie.org>
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

import QtQuick 2.3
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0

import QtQuick.Controls.Styles 1.4
import LunaNext.Common 0.1
import LuneOS.Service 1.0
import firstuse 1.0
import QtQml 2.2
import "js/GlobalState.js" as GlobalState


BasePage {
    id: root
    title: "Select your Timezone"
    forwardButtonSourceComponent: forwardButton
    keyboardFocusItem: filterTextField

    property variant currentTimezone: null
    property string currentRegionCountry: ""
    property string currentTimeFormat: ""
    property string currentLocaleCountry: ""
    property string currentLocaleLanguage: ""

    property int currentTimezoneIndex: -1
    property int currentDifference: -1
    property int currentTimezoneIndexPreferredTemp: -1
    property int currentTimezoneIndexPreferred: -1
    property int currentTimezoneIndexPreferredOffset: -1
    property int finalIndex: -1
    property string timeFormat: "HH12"

    signal tzUpdated;
    onCurrentTimeFormatChanged: tzUpdated();

    LunaService {
        id: service
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component.onCompleted: {
        service.call("luna://com.palm.systemservice/getPreferences", JSON.stringify({
                                              keys: ["region", "timeZone", "timeFormat", "locale"]
                                          }), getPreferencesSuccess,
                           getPreferencesFailure)
    }

    Stack.onStatusChanged: tzUpdated();

    function fetchAvailableTimezonesSuccess (message) {
                var response = JSON.parse(message.payload)

                timezoneModel.clear()
                if (response.timeZone && response.timeZone.length > 0) {
                    for (var n = 0; n < response.timeZone.length; n++) {
                        var timezone = response.timeZone[n]
                        if (currentRegionCountry === timezone.CountryCode) {
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

                        //Get the current date/time
                        var utcTime = new Date()

                        //Check if DST is being applied currently
                        var inDST = isDST(new Date()) && timezone.supportsDST

                        //In case DST is applied we need to adjust for 1 hr
                        var dstCorrection = inDST ? timezone.supportsDST * 60 : 0

                        //We need to correct for DST in the offset we receive from our timezone table
                        var dstDifferenceTemp = timezone.offsetFromUTC + dstCorrection

                        //Calculate the difference in hours and minutes, indicate if we're in DST.
                        var dstDifference
                        var dstOffset = ""
                        if(inDST){
                            dstDifference = ((timezone.offsetFromUTC+dstCorrection).toString().substring(0,1) === "-" ? Math.floor((timezone.offsetFromUTC+dstCorrection).toString().substring(1)/60) + ":" +((timezone.offsetFromUTC+dstCorrection).toString().substring(1)%60+"00").substring(0,2): Math.floor((timezone.offsetFromUTC+dstCorrection).toString()/60) + ":" +((timezone.offsetFromUTC+dstCorrection).toString()%60+"00").substring(0,2) )
                            dstOffset = "(DST +1:00)"
                        } else {
                            dstDifference = timezone.offsetFromUTC.toString().substring(0,1) === "-" ? Math.floor(timezone.offsetFromUTC.toString().substring(1)/60) + ":" +(timezone.offsetFromUTC.toString().substring(1)%60+"00").substring(0,2): Math.floor(timezone.offsetFromUTC.toString()/60) + ":" +(timezone.offsetFromUTC.toString()%60+"00").substring(0,2)
							dstOffset = ""
                        }

                        //Calculate the local time in a specific timezone, adjusted for DST etc, based on the current time.
                        //utcTime.setUTCMinutes(utcTime.getUTCMinutes()+new Date().getTimezoneOffset()+dstDifferenceTemp);

                        function isDST(t) { //t is the date object to check, returns true if daylight saving time is in effect.
                            var jan = new Date(t.getFullYear(),0,1);
                            var jul = new Date(t.getFullYear(),6,1);
                            return Math.min(jan.getTimezoneOffset(),jul.getTimezoneOffset()) === t.getTimezoneOffset();
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
                                               timezoneOffsetSign: timezone.offsetFromUTC.toString().substring(0,1) === "-" ? "-" : "+",
                                               timezoneOffsetHours: dstDifference,
                                               timezoneOffsetDST: dstOffset,
                                               timezonePreferred: timezone.preferred ? timezone.preferred : false,
                                               timezoneoffsetAdjustedTime: utcTime,
                                               timezoneDSTCorrection: dstCorrection
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
                    applySelectedTimeFormat(timeFormat)
                }

                //Make sure we select the right one in the list

                //Take the preferred one with smallest offset, regular prefered one or other available one
                if(currentTimezoneIndexPreferredOffset !== -1) {
                    finalIndex = currentTimezoneIndexPreferredOffset;
                } else if (currentTimezoneIndexPreferred !== -1) {
                    finalIndex = currentTimezoneIndexPreferred
                } else if (currentTimezoneIndexPreferredTemp !== -1) {
                    finalIndex = currentTimezoneIndexPreferredTemp
                } else {
                    finalIndex = currentTimezoneIndex;
                }

                timezoneList.currentIndex = finalIndex
                timezoneList.positionViewAtIndex(finalIndex, ListView.Center)

                filteredTimezoneModel.syncWithFilter();
            }
    function fetchAvailableTimezonesFailure (message) {
        console.log("Unable to fetch timezones")
            }


    function getPreferencesSuccess(message) {

        var response = JSON.parse(message.payload)

        if (response.region.countryCode !== undefined) {
            currentRegionCountry = response.region.countryCode.toUpperCase()
        }
/*
        if (response.timeZone !== undefined) {
            currentTimezone = response.timeZone
        }
*/

        //currently stored timeFormat
        if (response.timeFormat !== undefined) {
            currentTimeFormat = response.timeFormat
        }
        if (response.locale.countryCode !== undefined) {
            currentLocaleCountry = response.locale.countryCode.toUpperCase()
        }
        if (response.locale.languageCode !== undefined) {
            currentLocaleLanguage = response.locale.languageCode
        }

        var locale = Qt.locale(currentLocaleLanguage+"_"+currentLocaleCountry)

        //Some can have 24 hr + AM/PM, so we need to check for that.
        //If it has AM/PM indicator & small h we use HH12, in all other cases HH24
        if(locale.timeFormat().toUpperCase().indexOf("A") !== -1 && locale.timeFormat().substring(0,1)==="h") {
               timeFormat = "HH12"
           }
           else {
               timeFormat = "HH24"
           }

        //We assume that the user would like to use the format that's the default for the locale and country that was selected.
        if(currentTimeFormat!==timeFormat)
        {
            currentTimeFormat = timeFormat
        }


        // now we can fetch all possible values and setup our model
        service.call("luna://com.palm.systemservice/getPreferenceValues", JSON.stringify({
                                                      key: "timeZone"
                                                  }), fetchAvailableTimezonesSuccess, fetchAvailableTimezonesFailure)

    }

    function getPreferencesFailure(message) {
        console.log("No regions found")
    }

    function setPreferencesSuccess (request) {
        console.log("Setting timeZone succeeded")
        currentTimezone = request.timeZone;
        Date.timeZoneUpdated();
        tzUpdated();
    }

    function setPreferencesFailure (message) {
        console.log("Setting timeZone failed")
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
        service.call("luna://com.palm.systemservice/setPreferences", JSON.stringify(request), setPreferencesSuccess(request), setPreferencesFailure)

    }

    function setTimeFormatSuccess (message) {
        console.log("Setting timeFormat succeeded")
            }

    function setTimeFormatFailure (message) {
        console.log("Setting timeFormat failed")
            }

    function applySelectedTimeFormat(timeFormat) {
        var request = {
            "timeFormat": timeFormat
            }

        service.call("luna://com.palm.systemservice/setPreferences", JSON.stringify(request), setTimeFormatSuccess, setTimeFormatFailure)

    }

    ListModel {
        id: timezoneModel
    }

    ListModel {
        id: filteredTimezoneModel

        property string filter: filterTextField.text
        onFilterChanged: syncWithFilter();

        function syncWithFilter() {
            filteredTimezoneModel.clear()
            var index = -1;
            for( var i = 0; i < timezoneModel.count; ++i ) {
                var timezoneItem = timezoneModel.get(i);
                var filterLowered = filter.toLowerCase();
                if( filterLowered.length === 0 ||
                        timezoneItem.timezoneCountry.toLowerCase().indexOf(filterLowered) >= 0 ||
                        timezoneItem.timezoneCity.toLowerCase().indexOf(filterLowered) >= 0 )
                {
                    filteredTimezoneModel.append(timezoneItem);
                    if ( (currentTimezone.City === timezoneItem.timezoneCity)
                       &&(currentTimezone.Description === timezoneItem.timezoneDescription)
                       &&(currentTimezone.CountryCode === timezoneItem.timezoneCountryCode) )
                    {
                        index = filteredTimezoneModel.count - 1;
                    }
                }
            }
            timezoneList.currentIndex = index
            timezoneList.positionViewAtIndex(index, ListView.Center)

        }
    }



    Column {
        id: column
        anchors.fill: content
        spacing: Units.gu(2)

        Row {
            id: timeFormatRow
            width: parent.width
            Column{
                anchors.verticalCenter: timeFormatRow.verticalCenter
                width: parent.width - Units.gu(8)
                Text {
                    id: timeFormatText
                    text: "Time Format"
                    font.pixelSize: Units.gu(36/13.5)
                    color: "white"
                    anchors.left: parent.left
                    width: parent.width - Units.gu(8)
                }
            }
            Column
            {
                anchors.verticalCenter: timeFormatRow.verticalCenter
                Switch
                {
                    id: timeFormatSwitch
                    anchors.right: parent.right
                    checked: currentTimeFormat === "HH12" ? false : true
                    style: SwitchStyle {
                        groove: Image
                        {
                        id: grooveImage
                        source: timeFormatSwitch.checked ? "images/toggle-button-on.png" : "images/toggle-button-off.png"
                        width: Units.gu(8)
                        height: Units.gu(4)

                        Text
                        {
                            color: "white"
                            text: "24H"
                            font.bold: true
                            font.family: "Prelude"
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            visible: timeFormatSwitch.checked
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Units.gu(1)
                        }
                        Text
                        {
                            color: "white"
                            text: "12H"
                            font.bold: true
                            font.family: "Prelude"
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            visible: !timeFormatSwitch.checked
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: Units.gu(1)
                        }

                    }
                    handle: Rectangle {
                        color: "transparent"
                    }
                }
                onClicked:
                {
                    timeFormat = timeFormatSwitch.checked ? "HH24" : "HH12"
                    applySelectedTimeFormat(timeFormat)
                }
            }
        }
    }

        TextField {
            id: filterTextField
            placeholderText: "Filter list..."
            height: Units.gu(4)
            font.pixelSize: Units.gu(36/13.5)
            width: parent.width
            style: TextFieldStyle {
                background: Rectangle {
                    radius: 5
                }
            }
        }

        ListView {
            id: timezoneList
            anchors.left: parent.left
            anchors.right: parent.right
            height: column.height - column.spacing - filterTextField.height - timeFormatRow.height - column.spacing
            snapMode: ListView.SnapToItem	

            clip: true

            model: filteredTimezoneModel

            delegate: MouseArea {
                id: delegate
                height: Math.max(tzCountry.height+tzCity.height,
                                 tzDescription.height+tzOffset.height,
                                 tzCountry.height+tzDescription.height) + Units.gu(4.0)
                width: timezoneList.width

                Text {
                    id: tzCountry
                    width: parent.width / 2
                    anchors.top: parent.top
                    anchors.topMargin: Units.gu(1.5)
                    anchors.left: parent.left
                    color: delegate.ListView.isCurrentItem ? "white" : "#6e83a3"
                    font.pixelSize: FontUtils.sizeToPixels("20pt")
                    text: timezoneCountry ? timezoneCountry : ""
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: tzCity
                    width: parent.width / 2
                    anchors.top: tzCountry.bottom
                    color: delegate.ListView.isCurrentItem ? "white" : "#6e83a3"
                    font.pixelSize: FontUtils.sizeToPixels("13pt")
                    text: timezoneCity ? timezoneCity : ""
                    font.bold: true
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: tzOffset
                    width: content.width
                    anchors.top: timezoneOffsetDST !=="" ? parent.top : undefined
                    anchors.topMargin: timezoneOffsetDST !=="" ? Units.gu(1.5) : undefined
                    anchors.verticalCenter: timezoneOffsetDST ==="" ? tzTime.verticalCenter : undefined
                    anchors.rightMargin: timezoneOffsetDST ==="" ? Units.gu(0.3) : undefined
                    anchors.right: timezoneOffsetDST ==="" ? tzTime.left : undefined
                    anchors.horizontalCenter: timezoneOffsetDST !=="" ? tzOffsetDST.horizontalCenter : undefined
                    color: delegate.ListView.isCurrentItem ? "white" : "#6e83a3"
                    font.pixelSize: FontUtils.sizeToPixels("11pt")
                    text: timezoneOffsetHours==="0:00" ? "UTC " : "UTC " + timezoneOffsetSign + timezoneOffsetHours
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.NoWrap
                    visible: true
                }
                Text {
                    id: tzOffsetDST
                    width: content.width
                    anchors.top: tzOffset.bottom
                    anchors.rightMargin: Units.gu(0.2)
                    anchors.right: tzTime.left
                    color: delegate.ListView.isCurrentItem ? "white" : "#6e83a3"
                    font.pixelSize: FontUtils.sizeToPixels("9pt")
                    text: timezoneOffsetDST
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.NoWrap
                    visible: timezoneOffsetDST !==""
                }
                Text {
                    id: tzTime
                    anchors.top: tzCountry.top
                    anchors.right: parent.right
                    color: delegate.ListView.isCurrentItem ? "white" : "#6e83a3"
                    font.pixelSize: FontUtils.sizeToPixels("20pt")
                    text: ""
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.WordWrap

                    Component.onCompleted: root.tzUpdated();

                    Connections {
                        target: root
                        onTzUpdated: {
                            var adjustedTime =  new Date();
                            adjustedTime.setUTCMinutes(adjustedTime.getUTCMinutes() + timezoneDSTCorrection + timezoneOffsetFromUTC + adjustedTime.getTimezoneOffset());
                            tzTime.text = " | " + Qt.formatTime(adjustedTime, timeFormat === "HH24"? "hh:mm": "h:mm AP");
                        }
                    }
                }
                Text {
                    id: tzDescription
                    width: parent.width / 2
                    anchors.top: tzCity.top
                    anchors.right: parent.right
                    color: delegate.ListView.isCurrentItem ? "white" : "#6e83a3"
                    font.pixelSize: FontUtils.sizeToPixels("13pt")
                    text: timezoneDescription ? timezoneDescription : ""
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.WordWrap
                }
                Rectangle {
                    id: dividerRectangleTop
                    color: "#1e3355"
                    width: parent.width
                    height: Units.gu(1 / 10)
                    anchors.top: parent.top
                }
                Rectangle {
                    id: dividerRectangleBottom
                    color: "#1e3355"
                    width: parent.width
                    height: Units.gu(1 / 10)
                    anchors.top: parent.bottom
                }

                onClicked: {
                    timezoneList.currentIndex = index
                    applySelectedTimezone(timezoneCity, timezoneDescription, timezoneCountryCode, timezoneCountry, timezoneSupportsDST, timezoneZoneID, timezoneOffsetFromUTC, timezonePreferred)
                }
            }
        }
    }

    Timer {
        interval: 1000
        onTriggered: root.tzUpdated();
        repeat: true
        running: parent.Stack.status === Stack.Active
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
