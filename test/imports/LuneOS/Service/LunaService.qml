/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
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
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0

import "LunaServiceRegistering.js" as LSRegisteredMethods

QtObject {
    property string name
    property string method
    property bool usePrivateBus: false
    property string service

    property var lockStatusSubscriber
    property string currentLockStatus: "locked"

    property var deviceLockModeSubscriber
    property string deviceLockMode: "none"
    property string polcyState: "none"
    property int retriesLeft: 3
    property string configuredPasscode: "4242"

    signal response
    signal initialized
    signal error

    Component.onCompleted: {
        initialized();
    }

    function call(serviceURI, jsonArgs, returnFct, handleError) {
        console.log("LunaService::call called with serviceURI=" + serviceURI + ", args=" + jsonArgs);
        var args = JSON.parse(jsonArgs);
        if( serviceURI === "luna://com.palm.applicationManager/listLaunchPoints" ) {
            listLaunchPoints_call(args, returnFct, handleError);
        }
        else if( serviceURI === "luna://com.palm.applicationManager/launch" ) {
            launchApp_call(args, returnFct, handleError);
        }
        else if( serviceURI === "palm://com.palm.applicationManager/getAppInfo" ) {
            giveFakeAppInfo_call(args, returnFct, handleError);
        }
        else if (serviceURI === "luna://com.palm.display/control/setLockStatus") {
            setLockStatus_call(args, returnFct, handleError);
        }
        else if (serviceURI === "luna://com.palm.systemmanager/getDeviceLockMode") {
            getDeviceLockMode_call(args, returnFct, handleError);
        }
        else if (serviceURI === "luna://com.palm.systemservice/getPreferences") {
            getPreferences_call(args, returnFct, handleError);
        }
        else if (serviceURI === "luna://com.palm.systemservice/getPreferenceValues") {
            getPreferenceValues_call(args, returnFct, handleError);
        }
        else if (serviceURI === "luna://com.palm.systemmanager/matchDevicePasscode") {
            matchDevicePasscode_call(args, returnFct, handleError);
        }
        else if (serviceURI === "luna://com.palm.power/com/palm/power/batteryStatusQuery") {
            getBatteryStatusQuery_call(args, returnFct, handleError);
        }
        else {
            // Embed the jsonArgs into a payload message
            var message = { applicationId: "org.webosports.tests.dummyWindow", payload: jsonArgs };
            if( !(LSRegisteredMethods.executeMethod(serviceURI, message)) ) {
                if (handleError)
                    handleError("unrecognized call: " + serviceURI);
            }
        }
    }

    function subscribe(serviceURI, jsonArgs, returnFct, handleError) {
        if( arguments.length === 1 ) {
            // handle the short form of subscribe
            return subscribe(service+"/"+method, arguments[0], onResponse, onError);
        }
        else if(arguments.length === 3 ) {
            // handle the intermediate form of subscribe
            return subscribe(service+"/"+method, arguments[0], arguments[1], arguments[2]);
        }

        var args = JSON.parse(jsonArgs);
        if( serviceURI === "palm://com.palm.bus/signal/registerServerStatus" ||
            serviceURI === "luna://com.palm.bus/signal/registerServerStatus" )
        {
            returnFct({"payload": JSON.stringify({"connected": true})});
        }
        else if( serviceURI === "luna://com.palm.applicationManager/launchPointChanges" && args.subscribe)
        {
            returnFct({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
            returnFct({"payload": JSON.stringify({})});
        }
        else if( serviceURI === "luna://org.webosports.bootmgr/getStatus" && args.subscribe )
        {
            console.log("bootmgr status: normal");
            returnFct({"payload": JSON.stringify({"subscribed":true, "state": "normal"})}); // simulate subscription answer
        }
        else if( serviceURI === "palm://com.palm.systemservice/getPreferences" && args.subscribe)
        {
            returnFct({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
            returnFct({"payload": JSON.stringify({"wallpaper": { "wallpaperFile": Qt.resolvedUrl("../../../../images/background.jpg")}})});
        }
        else if (serviceURI === "luna://org.webosports.audio/getStatus")
        {
            returnFct({"payload": JSON.stringify({"volume":54,"mute":false})});
        }
        else if (serviceURI === "luna://com.palm.display/control/lockStatus") {
            lockStatusSubscriber =  {func: returnFct};
            returnFct({payload: "{\"lockState\":\"" + currentLockStatus + "\"}"});
        }
        else if (serviceURI === "luna://com.palm.systemmanager/getDeviceLockMode") {
            deviceLockModeSubscriber = {func: returnFct};
            getDeviceLockMode_call(jsonArgs, returnFct, handleError);
        }
        else if (serviceURI === "palm://com.palm.bus/signal/addmatch" )
        {
            LSRegisteredMethods.addRegisteredMethod("palm://" + name + args.category + "/" + args.name, returnFct);
            returnFct({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
        }
    }

    function registerMethod(category, fct, callback) {
        console.log("registering " + "luna://" + name + category + fct);
        LSRegisteredMethods.addRegisteredMethod("luna://" + name + category + fct, callback);
    }

    function addSubscription() {
        /* do nothing */
    }

    function replyToSubscribers(path, callerAppId, jsonArgs) {
        console.log("replyToSubscribers " + "luna://" + name + path);
        LSRegisteredMethods.executeMethod("luna://" + name + path, {"applicationId": callerAppId, "payload": jsonArgs});
    }

    function listLaunchPoints_call(jsonArgs, returnFct, handleError) {
        returnFct({"payload": JSON.stringify({"returnValue": true,
                    "launchPoints": [
             { "title": "Calendar", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Email", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Calculator", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png", "showInSearch": false },
             { "title": "Snowshoe", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "This is a long title", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "This_is_also_a_long_title", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Preware 5", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "iOS", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Oh My", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Test1", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Test2", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Test3", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Test5", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Test5bis", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "Test6", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" },
             { "title": "End Of All Tests", "id": "org.webosports.tests.dummyWindow", "icon": "../images/default-app-icon.png" }
           ]})});
    }

    function giveFakeAppInfo_call(args, returnFct, handleError) {
        returnFct({"payload": JSON.stringify({"returnValue": true, "appInfo": { "appmenu": "Fake App" } })});
    }

    function launchApp_call(jsonArgs, returnFct, handleError) {
        // The JSON params can contain "id" (string) and "params" (object)
        if( jsonArgs.id === "org.webosports.tests.dummyWindow" || jsonArgs.id === "org.webosports.tests.dummyWindow2" ) {
            // start a DummyWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("DummyWindow", jsonArgs);
        }
        else if( jsonArgs.id === "org.webosports.tests.fakeOverlayWindow" ) {
            // start a FakeOverlayWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakeOverlayWindow", jsonArgs);
        }
        else if( jsonArgs.id === "org.webosports.tests.fakeDashboardWindow" ) {
            // start a FakeDashboardWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakeDashboardWindow", jsonArgs);
        }
        else if( jsonArgs.id === "org.webosports.tests.fakePopupAlertWindow" ) {
            // start a FakeDashboardWindow
            // Simulate the attachement of a new window to the stub Wayland compositor
            compositor.createFakeWindow("FakePopupAlertWindow", jsonArgs);
        }
        else {
            handleError("Error: parameter 'id' not specified");
        }
    }

    function createNotification_call(jsonArgs, returnFct, handleError) {

        if( jsonArgs ) {
            var callerAppId = "org.webosports.tests.dummyWindow"; // hard-coded

            replyToSubscribers("/createNotification", callerAppId, jsonArgs);
        }
        else {
            handleError("Error: parameter 'id' not specified");
        }
    }


    function setLockStatus_call(args, returnFct, handleError) {
        console.log("setLockStatus_call: arg.status = " + args.status + " currentLockStatus = " + currentLockStatus);
        if (args.status === "unlock" && currentLockStatus === "locked") {
            currentLockStatus = "unlocked";
            lockStatusSubscriber.func({payload: "{\"lockState\":\"" + currentLockStatus + "\"}"});
        }
    }

    function getDeviceLockMode_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "lockMode": deviceLockMode,
            "policyState": polcyState,
            "retriesLeft": retriesLeft
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function getPreferences_call(args, returnFct, handleError) {

        //return preference value for locale
        if (args.keys == "locale")
        {
            var message = {
            "returnValue": true,
            "locale": { "languageCode": "en", "countryCode": "us", "phoneRegion": { "countryName": "United States", "countryCode": "us" } }
        };
        }
        else if(args.keys == "region")
        {
            var message = {
            "returnValue": true,
            "locale": { "languageCode": "en", "countryCode": "us", "phoneRegion": { "countryName": "United States", "countryCode": "us" } }
        };
        }

        else
        {
            console.log("We don't have a preference for: "+args.keys);
        }

        returnFct({payload: JSON.stringify(message)});
    }

    function getPreferenceValues_call(args, returnFct, handleError) {
        //return preference values for locale
        if (args.key == "locale")
        {
            var message = { "returnValue": true, "locale": [ { "languageName": "Albanian", "languageCode": "sq", "countries": [ { "countryName": "Albania", "countryCode": "al" }, { "countryName": "Montenegro", "countryCode": "me" } ] }, { "languageName": "Arabic", "languageCode": "ar", "countries": [ { "countryName": "Saudi Arabia", "countryCode": "sa" }, { "countryName": "Algeria", "countryCode": "dz" }, { "countryName": "Bahrain", "countryCode": "bh" }, { "countryName": "Djibouti", "countryCode": "dj" }, { "countryName": "Egypt", "countryCode": "eg" }, { "countryName": "Iraq", "countryCode": "iq" }, { "countryName": "Jordan", "countryCode": "jo" }, { "countryName": "Kuwait", "countryCode": "kw" }, { "countryName": "Lebanon", "countryCode": "lb" }, { "countryName": "Libya", "countryCode": "ly" }, { "countryName": "Mauritania", "countryCode": "mr" }, { "countryName": "Morocco", "countryCode": "ma" }, { "countryName": "Oman", "countryCode": "om" }, { "countryName": "Qatar", "countryCode": "qa" }, { "countryName": "Sudan", "countryCode": "sd" }, { "countryName": "Syria", "countryCode": "sy" }, { "countryName": "Tunisia", "countryCode": "tn" }, { "countryName": "UAE", "countryCode": "ae" }, { "countryName": "Yemen", "countryCode": "ye" } ] }, { "languageName": "Assamese", "languageCode": "as", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Bengali", "languageCode": "bn", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Bosnian", "languageCode": "bs", "countries": [ { "countryName": "Bosnia", "countryCode": "latn-ba" }, { "countryName": "Montenegro", "countryCode": "latn-me" } ] }, { "languageName": "Bulgarian", "languageCode": "bg", "countries": [ { "countryName": "Bulgaria", "countryCode": "bg" } ] }, { "languageName": "Croation", "languageCode": "hr", "countries": [ { "countryName": "Croatia", "countryCode": "hr" }, { "countryName": "Montenegro", "countryCode": "me" } ] }, { "languageName": "Czech", "languageCode": "cs", "countries": [ { "countryName": "Czech Republic", "countryCode": "cz" } ] }, { "languageName": "Deutsch", "languageCode": "de", "countries": [ { "countryName": "Deutschland", "countryCode": "de" }, { "countryName": "Austria", "countryCode": "at" }, { "countryName": "Swizerland", "countryCode": "ch" }, { "countryName": "Luxemburg", "countryCode": "lu" } ] }, { "languageName": "Danish", "languageCode": "da", "countries": [ { "countryName": "Denmark", "countryCode": "dk" } ] }, { "languageName": "Dutch", "languageCode": "nl", "countries": [ { "countryName": "Belgium", "countryCode": "be" }, { "countryName": "Netherlands", "countryCode": "nl" } ] }, { "languageName": "English", "languageCode": "en", "countries": [ { "countryName": "United States", "countryCode": "us" }, { "countryName": "United Kingdom", "countryCode": "gb" }, { "countryName": "Pseudoland", "countryCode": "pl" }, { "countryName": "Canada", "countryCode": "ca" }, { "countryName": "Ireland", "countryCode": "ie" }, { "countryName": "Mexico", "countryCode": "mx" }, { "countryName": "China", "countryCode": "cn" }, { "countryName": "Taiwan", "countryCode": "tw" }, { "countryName": "India", "countryCode": "in" }, { "countryName": "Australia", "countryCode": "au" }, { "countryName": "New Zealand", "countryCode": "nz" }, { "countryName": "South Africa", "countryCode": "za" }, { "countryName": "Azerbaijan", "countryCode": "az" }, { "countryName": "Armenia", "countryCode": "am" }, { "countryName": "Ethiopia", "countryCode": "et" }, { "countryName": "Gambia", "countryCode": "gm" }, { "countryName": "Ghana", "countryCode": "gh" }, { "countryName": "Hong Kong", "countryCode": "hk" }, { "countryName": "Iceland", "countryCode": "is" }, { "countryName": "Kenya", "countryCode": "ke" }, { "countryName": "Liberia", "countryCode": "lr" }, { "countryName": "Malawi", "countryCode": "mw" }, { "countryName": "Myanmar", "countryCode": "mm" }, { "countryName": "South Africa", "countryCode": "za" }, { "countryName": "Nigeria", "countryCode": "ng" }, { "countryName": "Pakistan", "countryCode": "pk" }, { "countryName": "Philippines", "countryCode": "ph" }, { "countryName": "Puerto Rico", "countryCode": "pr" }, { "countryName": "Rwanda", "countryCode": "rw" }, { "countryName": "Sierra Leone", "countryCode": "sl" }, { "countryName": "Singapore", "countryCode": "sg" }, { "countryName": "Sri Lanka", "countryCode": "lk" }, { "countryName": "Sudan", "countryCode": "sd" }, { "countryName": "Tanzania", "countryCode": "tz" }, { "countryName": "Uganda", "countryCode": "ug" }, { "countryName": "Malaysia", "countryCode": "my" }, { "countryName": "Mauritius", "countryCode": "mu" }, { "countryName": "Zambia", "countryCode": "zm" } ] }, { "languageName": "Español", "languageCode": "es", "countries": [ { "countryName": "Estados Unidos", "countryCode": "us" }, { "countryName": "España", "countryCode": "es" }, { "countryName": "México", "countryCode": "mx" }, { "countryName": "Colombia", "countryCode": "co" }, { "countryName": "Guinea Equatorial", "countryCode": "gq" }, { "countryName": "Argentina", "countryCode": "ar" }, { "countryName": "Bolivia", "countryCode": "bo" }, { "countryName": "Chile", "countryCode": "cl" }, { "countryName": "Costa Rica", "countryCode": "cr" }, { "countryName": "Dominican Republic", "countryCode": "do" }, { "countryName": "Ecuador", "countryCode": "ec" }, { "countryName": "El Salvador", "countryCode": "sv" }, { "countryName": "Guatemala", "countryCode": "gt" }, { "countryName": "Honduras", "countryCode": "hn" }, { "countryName": "Panama", "countryCode": "pa" }, { "countryName": "Nicaragua", "countryCode": "ni" }, { "countryName": "Paraguay", "countryCode": "py" }, { "countryName": "Peru", "countryCode": "pe" }, { "countryName": "Philippines", "countryCode": "ph" }, { "countryName": "Puerto Rico", "countryCode": "pr" }, { "countryName": "Uruguay", "countryCode": "uy" }, { "countryName": "Venezuela", "countryCode": "ve" } ] }, { "languageName": "Estonian", "languageCode": "et", "countries": [ { "countryName": "Estonia", "countryCode": "ee" } ] }, { "languageName": "Farsi", "languageCode": "fa", "countries": [ { "countryName": "Afghanistan", "countryCode": "af" }, { "countryName": "Iran", "countryCode": "ir" } ] }, { "languageName": "Finnish", "languageCode": "fi", "countries": [ { "countryName": "Finland", "countryCode": "fi" } ] }, { "languageName": "Français", "languageCode": "fr", "countries": [ { "countryName": "France", "countryCode": "fr" }, { "countryName": "Canada", "countryCode": "ca" }, { "countryName": "Algeria", "countryCode": "dz" }, { "countryName": "Belgium", "countryCode": "be" }, { "countryName": "Guinea Equatorial", "countryCode": "cq" }, { "countryName": "Swizerland", "countryCode": "ch" }, { "countryName": "Luxemburg", "countryCode": "lu" }, { "countryName": "Benin", "countryCode": "bj" }, { "countryName": "Burkina Faso", "countryCode": "bf" }, { "countryName": "Cameroon", "countryCode": "cm" }, { "countryName": "Central African Republic", "countryCode": "cf" }, { "countryName": "Democratic Republic Congo", "countryCode": "cd" }, { "countryName": "Djibouti", "countryCode": "dj" }, { "countryName": "Gabon", "countryCode": "ga" }, { "countryName": "Guinea", "countryCode": "gn" }, { "countryName": "Ivory Coast", "countryCode": "ci" }, { "countryName": "Lebanon", "countryCode": "lb" }, { "countryName": "Mali", "countryCode": "ml" }, { "countryName": "Republic of the Congo", "countryCode": "cg" }, { "countryName": "Rwanda", "countryCode": "rw" }, { "countryName": "Senegal", "countryCode": "sn" }, { "countryName": "Mauritius", "countryCode": "mu" }, { "countryName": "Togo", "countryCode": "tg" } ] }, { "languageName": "Gaelic", "languageCode": "ga", "countries": [ { "countryName": "Ireland", "countryCode": "ie" } ] }, { "languageName": "Greek", "languageCode": "el", "countries": [ { "countryName": "Greece", "countryCode": "gr" }, { "countryName": "Cyprus", "countryCode": "cy" } ] }, { "languageName": "Gujarathi", "languageCode": "gu", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Hebrew", "languageCode": "he", "countries": [ { "countryName": "Isreal", "countryCode": "il" } ] }, { "languageName": "Hindi", "languageCode": "hi", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Hungarian", "languageCode": "hu", "countries": [ { "countryName": "Hungary", "countryCode": "hu" } ] }, { "languageName": "Indonesian", "languageCode": "id", "countries": [ { "countryName": "Indonesia", "countryCode": "id" } ] }, { "languageName": "Italiano", "languageCode": "it", "countries": [ { "countryName": "Italia", "countryCode": "it" }, { "countryName": "Swizerland", "countryCode": "ch" } ] }, { "languageName": "Japanese", "languageCode": "ja", "countries": [ { "countryName": "Japan", "countryCode": "jp" } ] }, { "languageName": "Kannada", "languageCode": "kn", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Kazakh", "languageCode": "kk", "countries": [ { "countryName": "Kazakhstan", "countryCode": "cyrl-kz" } ] }, { "languageName": "Korean", "languageCode": "ko", "countries": [ { "countryName": "Korea, Republic of", "countryCode": "kr" }, { "countryName": "Japan", "countryCode": "jp" } ] }, { "languageName": "Kurdish", "languageCode": "ku", "countries": [ { "countryName": "Iraq", "countryCode": "arab-iq" } ] }, { "languageName": "Latvian", "languageCode": "lv", "countries": [ { "countryName": "Latvia", "countryCode": "lv" } ] }, { "languageName": "Lithunian", "languageCode": "lt", "countries": [ { "countryName": "Lithuania", "countryCode": "lt" } ] }, { "languageName": "Malayalam", "languageCode": "ml", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Macedonian", "languageCode": "mk", "countries": [ { "countryName": "Macedonia", "countryCode": "mk" } ] }, { "languageName": "Malaysian", "languageCode": "ms", "countries": [ { "countryName": "Malaysia", "countryCode": "my" }, { "countryName": "Singapore", "countryCode": "sg" } ] }, { "languageName": "Marathi", "languageCode": "mr", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Mongolian", "languageCode": "mn", "countries": [ { "countryName": "Mongolia", "countryCode": "cyrl-mn" } ] }, { "languageName": "Norwegia Bokmal", "languageCode": "nb", "countries": [ { "countryName": "Norway", "countryCode": "no" } ] }, { "languageName": "Polish", "languageCode": "pl", "countries": [ { "countryName": "Poland", "countryCode": "pl" } ] }, { "languageName": "Portuguese", "languageCode": "pt", "countries": [ { "countryName": "Portugal", "countryCode": "pt" }, { "countryName": "Brazil", "countryCode": "br" }, { "countryName": "Angola", "countryCode": "ao" }, { "countryName": "Cape Verde", "countryCode": "cv" }, { "countryName": "Guinea Equatorial", "countryCode": "cq" } ] }, { "languageName": "Punjabi", "languageCode": "pa", "countries": [ { "countryName": "India", "countryCode": "in" }, { "countryName": "Pakistan", "countryCode": "pk" } ] }, { "languageName": "Romanian", "languageCode": "ro", "countries": [ { "countryName": "Romania", "countryCode": "ro" } ] }, { "languageName": "Russian", "languageCode": "ru", "countries": [ { "countryName": "Russian Federation", "countryCode": "ru" }, { "countryName": "Belarus", "countryCode": "by" }, { "countryName": "Georgia", "countryCode": "ge" }, { "countryName": "Kazakhstan", "countryCode": "kz" }, { "countryName": "Kyrgyzstan", "countryCode": "kg" }, { "countryName": "Ukraine", "countryCode": "ua" } ] }, { "languageName": "Serbian", "languageCode": "sr", "countries": [ { "countryName": "Serbia", "countryCode": "latn-rs" }, { "countryName": "Montenegro", "countryCode": "latn-me" } ] }, { "languageName": "Slovak", "languageCode": "sk", "countries": [ { "countryName": "Slovakia", "countryCode": "sk" } ] }, { "languageName": "Slovenian", "languageCode": "sl", "countries": [ { "countryName": "Slovenia", "countryCode": "sl" } ] }, { "languageName": "Swedish", "languageCode": "sv", "countries": [ { "countryName": "Finland", "countryCode": "fi" }, { "countryName": "Sweden", "countryCode": "se" } ] }, { "languageName": "Tamil", "languageCode": "ta", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Telugu", "languageCode": "te", "countries": [ { "countryName": "India", "countryCode": "in" } ] }, { "languageName": "Thai", "languageCode": "th", "countries": [ { "countryName": "Thailand", "countryCode": "th" } ] }, { "languageName": "Turkish", "languageCode": "tr", "countries": [ { "countryName": "Armenia", "countryCode": "am" }, { "countryName": "Azerbaijan", "countryCode": "az" }, { "countryName": "Cyprus", "countryCode": "cy" }, { "countryName": "Turkey", "countryCode": "tr" } ] }, { "languageName": "Urdu", "languageCode": "ur", "countries": [ { "countryName": "India", "countryCode": "in" }, { "countryName": "Pakistan", "countryCode": "pk" } ] }, { "languageName": "Ukranian", "languageCode": "uk", "countries": [ { "countryName": "Ukraine", "countryCode": "ua" } ] }, { "languageName": "Uzbek", "languageCode": "uz", "countries": [ { "countryName": "Uzbekistan", "countryCode": "cyrl-uz" }, { "countryName": "Uzbekistan", "countryCode": "latn-uz" } ] }, { "languageName": "Vietnamese", "languageCode": "vi", "countries": [ { "countryName": "Vietnam", "countryCode": "vn" } ] }, { "languageName": "中文", "languageCode": "zh", "countries": [ { "countryName": "简体", "countryCode": "cn" }, { "countryName": "繁体", "countryCode": "hk" }, { "countryName": "Malaysia", "countryCode": "my" }, { "countryName": "Singapore", "countryCode": "sg" }, { "countryName": "Taiwan", "countryCode": "tw" } ] } ]
        };
        }

        else if (args.key == "region")
        {
            var message = { "returnValue": true , "region": [ { "shortCountryName": "Afghanistan", "countryName": "Afghanistan", "countryCode": "af" }, { "shortCountryName": "Algeria", "countryName": "Algeria", "countryCode": "dz" }, { "shortCountryName": "Angola", "countryName": "Angola", "countryCode": "ao" }, { "shortCountryName": "Argentina", "countryName": "Argentina", "countryCode": "ar" }, { "shortCountryName": "Armenia", "countryName": "Armenia", "countryCode": "am" }, { "shortCountryName": "Albania", "countryName": "Albania", "countryCode": "al" }, { "shortCountryName": "Australia", "countryName": "Australia", "countryCode": "au" }, { "shortCountryName": "Austria", "countryName": "Austria", "countryCode": "at" }, { "shortCountryName": "Azerbaijan", "countryName": "Azerbaijan", "countryCode": "az" }, { "shortCountryName": "Bahrain", "countryName": "Bahrain", "countryCode": "bh" }, { "shortCountryName": "Belarus", "countryName": "Belarus", "countryCode": "by" }, { "shortCountryName": "Belgium", "countryName": "Belgium", "countryCode": "be" }, { "shortCountryName": "Benin", "countryName": "Benin", "countryCode": "bj" }, { "shortCountryName": "Bolivia", "countryName": "Bolivia", "countryCode": "bo" }, { "shortCountryName": "Bosnia", "countryName": "Bosnia", "countryCode": "ba" }, { "shortCountryName": "Brazil", "countryName": "Brazil", "countryCode": "br" }, { "shortCountryName": "Bulgaria", "countryName": "Bulgaria", "countryCode": "bg" }, { "shortCountryName": "Burkina Faso", "countryName": "Burkina Faso", "countryCode": "bf" }, { "shortCountryName": "Cameroon", "countryName": "Cameroon", "countryCode": "cm" }, { "shortCountryName": "Canada", "countryName": "Canada", "countryCode": "ca" }, { "shortCountryName": "Cape Verde", "countryName": "Cape Verde", "countryCode": "cv" }, { "shortCountryName": "Africa", "countryName": "Central African Republic", "countryCode": "cf" }, { "shortCountryName": "Chile", "countryName": "Chile", "countryCode": "cl" }, { "shortCountryName": "China", "countryName": "China", "countryCode": "cn" }, { "shortCountryName": "Colombia", "countryName": "Colombia", "countryCode": "co" }, { "shortCountryName": "Congo", "countryName": "Congo, The Democratic Republic of the", "countryCode": "cd" }, { "shortCountryName": "Costa Rica", "countryName": "Costa Rica", "countryCode": "cr" }, { "shortCountryName": "Croatia", "countryName": "Croatia", "countryCode": "hr" }, { "shortCountryName": "Cyprus", "countryName": "Cyprus", "countryCode": "cy" }, { "shortCountryName": "Czech ", "countryName": "Czech Republic", "countryCode": "cz" }, { "shortCountryName": "Denmark", "countryName": "Denmark", "countryCode": "dk" }, { "shortCountryName": "Djibouti", "countryName": "Djibouti", "countryCode": "dj" }, { "shortCountryName": "Dominican Republic", "countryName": "Dominican Republic", "countryCode": "do" }, { "shortCountryName": "Ecuador", "countryName": "Ecuador", "countryCode": "ec" }, { "shortCountryName": "Egypt", "countryName": "Egypt", "countryCode": "eg" }, { "shortCountryName": "El Salvador", "countryName": "El Salvador", "countryCode": "sv" }, { "shortCountryName": "Estonia", "countryName": "Estonia", "countryCode": "ee" }, { "shortCountryName": "Ethiopia", "countryName": "Ethiopia", "countryCode": "et" }, { "shortCountryName": "Finland", "countryName": "Finland", "countryCode": "fi" }, { "shortCountryName": "France", "countryName": "France", "countryCode": "fr" }, { "shortCountryName": "Gabon", "countryName": "Gabon", "countryCode": "ga" }, { "shortCountryName": "Gambia", "countryName": "Gambia", "countryCode": "gm" }, { "shortCountryName": "Georgia", "countryName": "Georgia", "countryCode": "ge" }, { "shortCountryName": "Germany", "countryName": "Germany", "countryCode": "de" }, { "shortCountryName": "Ghana", "countryName": "Ghana", "countryCode": "gh" }, { "shortCountryName": "Greece", "countryName": "Greece", "countryCode": "gr" }, { "shortCountryName": "Guatemala", "countryName": "Guatemala", "countryCode": "gt" }, { "shortCountryName": "Guinea Equatorial", "countryName": "Guinea Equatorial", "countryCode": "gq" }, { "shortCountryName": "Guinea Equatorial", "countryName": "Guinea Equatorial", "countryCode": "cq" }, { "shortCountryName": "Guinea", "countryName": "Guinea", "countryCode": "gn" }, { "shortCountryName": "Honduras", "countryName": "Honduras", "countryCode": "hn" }, { "shortCountryName": "Hong Kong", "countryName": "Hong Kong", "countryCode": "hk" }, { "shortCountryName": "Hungary", "countryName": "Hungary", "countryCode": "hu" }, { "shortCountryName": "Iceland", "countryName": "Iceland", "countryCode": "is" }, { "shortCountryName": "India", "countryName": "India", "countryCode": "in" }, { "shortCountryName": "Indonesia", "countryName": "Indonesia", "countryCode": "id" }, { "shortCountryName": "Iran", "countryName": "Iran", "countryCode": "ir" }, { "shortCountryName": "Iraq", "countryName": "Iraq", "countryCode": "iq" }, { "shortCountryName": "Ireland", "countryName": "Ireland", "countryCode": "ie" }, { "shortCountryName": "Israel", "countryName": "Israel", "countryCode": "il" }, { "shortCountryName": "Italy", "countryName": "Italy", "countryCode": "it" }, { "shortCountryName": "Ivory Coast", "countryName": "Ivory Coast", "countryCode": "ci" }, { "shortCountryName": "Jamaica", "countryName": "Jamaica", "countryCode": "jm" }, { "shortCountryName": "Japan", "countryName": "Japan", "countryCode": "jp" }, { "shortCountryName": "Jordan", "countryName": "Jordan", "countryCode": "jo" }, { "shortCountryName": "Kazakhstan", "countryName": "Kazakhstan", "countryCode": "kz" }, { "shortCountryName": "Kenya", "countryName": "Kenya", "countryCode": "ke" }, { "shortCountryName": "Korea", "countryName": "Korea, Republic of", "countryCode": "kr" }, { "shortCountryName": "Kuwait", "countryName": "Kuwait", "countryCode": "kw" }, { "shortCountryName": "Kyrgyzstan", "countryName": "IKyrgyzstan", "countryCode": "kg" }, { "shortCountryName": "Latvia", "countryName": "Latvia", "countryCode": "lv" }, { "shortCountryName": "Lebanon", "countryName": "Lebanon", "countryCode": "lb" }, { "shortCountryName": "Lesotho", "countryName": "Lesotho", "countryCode": "ls" }, { "shortCountryName": "Liberia", "countryName": "Liberia", "countryCode": "lr" }, { "shortCountryName": "Libya", "countryName": "Libya", "countryCode": "ly" }, { "shortCountryName": "Lithuania", "countryName": "Lithuania", "countryCode": "lt" }, { "shortCountryName": "Luxembourg", "countryName": "Luxembourg", "countryCode": "lu" }, { "shortCountryName": "Macedonia", "countryName": "Macedonia, The Former Yugoslav Republic Of", "countryCode": "mk" }, { "shortCountryName": "Malawi", "countryName": "Malawi", "countryCode": "mw" }, { "shortCountryName": "Malaysia", "countryName": "Malaysia", "countryCode": "my" }, { "shortCountryName": "Mali", "countryName": "Mali", "countryCode": "ml" }, { "shortCountryName": "Malta", "countryName": "Malta", "countryCode": "mt" }, { "shortCountryName": "Mauritania", "countryName": "Mauritania", "countryCode": "mr" }, { "shortCountryName": "Mauritius", "countryName": "Mauritius", "countryCode": "mu" }, { "shortCountryName": "Mongolia", "countryName": "Mongolia", "countryCode": "mn" }, { "shortCountryName": "Montenegro", "countryName": "Montenegro", "countryCode": "me" }, { "shortCountryName": "Morocco", "countryName": "Morocco", "countryCode": "ma" }, { "shortCountryName": "Mexico", "countryName": "Mexico", "countryCode": "mx" }, { "shortCountryName": "Mozambique", "countryName": "Mozambique", "countryCode": "mz" }, { "shortCountryName": "Myanmar", "countryName": "Myanmar", "countryCode": "mm" }, { "shortCountryName": "Netherlands", "countryName": "Netherlands", "countryCode": "nl" }, { "shortCountryName": "New Zealand", "countryName": "New Zealand", "countryCode": "nz" }, { "shortCountryName": "Nicaragua", "countryName": "Nicaragua", "countryCode": "ni" }, { "shortCountryName": "Nigeria", "countryName": "Nigeria", "countryCode": "ng" }, { "shortCountryName": "Norway", "countryName": "Norway", "countryCode": "no" }, { "shortCountryName": "Oman", "countryName": "Oman", "countryCode": "om" }, { "shortCountryName": "Pakistan", "countryName": "Pakistan", "countryCode": "pk" }, { "shortCountryName": "Panama", "countryName": "Panama", "countryCode": "pa" }, { "shortCountryName": "Paraguay", "countryName": "Paraguay", "countryCode": "py" }, { "shortCountryName": "Peru", "countryName": "Peru", "countryCode": "pe" }, { "shortCountryName": "Philippines", "countryName": "Philippines", "countryCode": "ph" }, { "shortCountryName": "Poland", "countryName": "Poland", "countryCode": "pl" }, { "shortCountryName": "Portugal", "countryName": "Portugal", "countryCode": "pt" }, { "shortCountryName": "Puerto Rico", "countryName": "Puerto Rico", "countryCode": "pr" }, { "shortCountryName": "Qatar", "countryName": "Qatar", "countryCode": "qa" }, { "shortCountryName": "Republic of the Congo", "countryName": "Republic of the Congo", "countryCode": "cg" }, { "shortCountryName": "Romania", "countryName": "Romania", "countryCode": "ro" }, { "shortCountryName": "Russian Federation", "countryName": "Russian Federation", "countryCode": "ru" }, { "shortCountryName": "Rwanda", "countryName": "Rwanda", "countryCode": "rw" }, { "shortCountryName": "Saudi Arabia", "countryName": "Saudi Arabia", "countryCode": "sa" }, { "shortCountryName": "Senegal", "countryName": "Senegal", "countryCode": "sn" }, { "shortCountryName": "Serbia", "countryName": "Serbia", "countryCode": "rs" }, { "shortCountryName": "Sierra Leone", "countryName": "Sierra Leone", "countryCode": "sl" }, { "shortCountryName": "Singapore", "countryName": "Singapore", "countryCode": "sg" }, { "shortCountryName": "Slovakia", "countryName": "Slovakia", "countryCode": "sk" }, { "shortCountryName": "Slovenia", "countryName": "Slovenia", "countryCode": "si" }, { "shortCountryName": "South Africa", "countryName": "South Africa", "countryCode": "za" }, { "shortCountryName": "Spain", "countryName": "Spain", "countryCode": "es" }, { "shortCountryName": "Sri Lanka", "countryName": "Sri Lanka", "countryCode": "lk" }, { "shortCountryName": "Sudan", "countryName": "Sudan", "countryCode": "sd" }, { "shortCountryName": "Sweden", "countryName": "Sweden", "countryCode": "se" }, { "shortCountryName": "Switzerland", "countryName": "Switzerland", "countryCode": "ch" }, { "shortCountryName": "Syria", "countryName": "Syria", "countryCode": "sy" }, { "shortCountryName": "Taiwan", "countryName": "Taiwan", "countryCode": "tw" }, { "shortCountryName": "Tanzania", "countryName": "Tanzania, United Republic of", "countryCode": "tz" }, { "shortCountryName": "Thailand", "countryName": "Thailand", "countryCode": "th" }, { "shortCountryName": "Togo", "countryName": "Togo", "countryCode": "tg" }, { "shortCountryName": "Tunisia", "countryName": "Tunisia", "countryCode": "tn" }, { "shortCountryName": "Turkey", "countryName": "Turkey", "countryCode": "tr" }, { "shortCountryName": "UAE", "countryName": "United Arab Emirates", "countryCode": "ae" }, { "shortCountryName": "United Kingdom", "countryName": "United Kingdom", "countryCode": "gb" }, { "shortCountryName": "Uganda", "countryName": "Uganda", "countryCode": "ug" }, { "shortCountryName": "Ukraine", "countryName": "Ukraine", "countryCode": "ua" }, { "shortCountryName": "Uruguay", "countryName": "Uruguay", "countryCode": "uy" }, { "shortCountryName": "USA", "countryName": "United States of America", "countryCode": "us" }, { "shortCountryName": "Uzbekistan", "countryName": "Uzbekistan", "countryCode": "uz" }, { "shortCountryName": "Venezuela", "countryName": "Venezuela", "countryCode": "ve" }, { "shortCountryName": "Vietnam", "countryName": "Vietnam", "countryCode": "vn" }, { "shortCountryName": "Yemen", "countryName": "Yemen", "countryCode": "ye" }, { "shortCountryName": "Zambia", "countryName": "Zambia", "countryCode": "zm" } ]}
        }

        else
        {
            console.log("We don't have preference values for: "+args.keys);
        }

        returnFct({payload: JSON.stringify(message)});
    }


    function getBatteryStatusQuery_call(args, returnFct, handleError) {
        var message = {
            "returnValue": true,
            "percent_ui": 10
        };

        returnFct({payload: JSON.stringify(message)});
    }

    function matchDevicePasscode_call(args, returnFct, handleError) {
        var success = (args.passCode === configuredPasscode);

        if (retriesLeft == 0)
            success = false;

        if (!success) {
            if (retriesLeft == 0) {
                /* FIXME */
            }
            else
                retriesLeft = retriesLeft - 1;
        }

        var message = {
            returnValue: success,
            retriesLeft: retriesLeft,
            lockedOut: false
        };

        returnFct({payload: JSON.stringify(message)});
    }
}
