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

Item {
    property string mccCountryCode: ""
    property bool foundCountryMCC: false

    LunaService {
        id: fetchNetworkId
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
                    foundCountryMCC = true
                    console.log("Found mcc: " + mcc + ", mccCountryCode: " + mccCountryCode)
                }
            }
        }
    }

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
            __currentCall = fetchNetworkId.subscribe(JSON.stringify({
                                                                        subscribe: true
                                                                    }))
        }
    }
}
