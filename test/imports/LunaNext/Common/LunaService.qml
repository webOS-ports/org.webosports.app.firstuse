/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
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
    property var onResponse
    property var onError

    signal initialized

    property var findNetworksSubscriber

    Component.onCompleted: {
        initialized();
    }

    function call(/*serviceURI, jsonArgs, returnFct, handleError*/) {
        if (arguments.length === 1)
            callWithArguments(arguments[0]);
        else if (arguments.length === 3)
            callWithArgumentsAndCallbacks(arguments[0], arguments[1], arguments[2]);
        else if (arguments.length === 4)
            callFull(arguments[0], arguments[1], arguments[2], arguments[3]);
    }

    function callWithArguments(arguments) {
    }

    function callWithArgumentsAndCallbacks(args, responseCallback, errorCallback) {
    }

    function callFull(uri, args, responseCallback, errorCallback) {
        console.log("LunaService::call called with uri " + uri + " args " + args);
        var parsedArgs = JSON.parse(args);
        if (uri === "luna://com.palm.wifi/connect") {
            var resonse = { returnValue: true };
            responseCallback({"payload": JSON.stringify(response)});
        }
        else {
            var message = { applicationId: "org.webosports.tests.dummyWindow", payload: parsedArgs };
            if( !(LSRegisteredMethods.executeMethod(uri, message)) ) {
                if (errorCallback)
                    errorCallback("unrecognized call: " + uri);
            }
        }
    }

    function subscribe() {
        console.log("arguments " + arguments.length);
        if (arguments.length === 1)
            subscribeWithArguments(arguments[0]);
        else if (arguments.length === 3)
            subscribeWithArgumentsAndCallbacks(arguments[0], arguments[1], arguments[2]);
        else if (arguments.length === 4)
            subscribeFull(arguments[0], arguments[1], arguments[2], arguments[3]);
    }

    function subscribeWithArguments(args) {
        var uri = service + "/" + method;
        console.log("uri " + uri);
        subscribeFull(uri, args, onResponse, onError);
    }

    function subscribeWithArgumentsAndCallbacks(args, responseCallback, errorCallback) {
        var uri = service + "/" + method;
        subscribeFull(uri, args, responseCallback, errorCallback);
    }

    function subscribeFull(uri, args, responseCallback, errorCallback) {
        var parsedArgs = JSON.parse(args);
        if( uri === "palm://com.palm.bus/signal/registerServerStatus" ||
            uri === "luna://com.palm.bus/signal/registerServerStatus" )
        {
            responseCallback({"payload": JSON.stringify({"connected": true})});
        }
        else if (uri === "palm://com.palm.bus/signal/addmatch" )
        {
            LSRegisteredMethods.addRegisteredMethod("palm://" + name + parsedArgs.category + "/" + args.name, returnFct);
            responseCallback({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
        }
        else if (uri === "luna://com.palm.wifi/findnetworks") {
            findNetworksSubscriber = {func: responseCallback};
            var response = {
                "foundNetworks": [
                    {"networkInfo":{"signalLevel":65,"ssid":"AP1","signalBars":3,"supported":true,"availableSecurityTypes":["psk"]}},
                    {"networkInfo":{"signalLevel":34,"ssid":"AP2","signalBars":2,"supported":true,"availableSecurityTypes":["none"]}},
                    {"networkInfo":{"signalLevel":10,"ssid":"AP3","signalBars":1,"supported":true,"availableSecurityTypes":["wep"]}}
                ],
                "subscribed": true,
                "returnValue":true
            };
            responseCallback({"payload": JSON.stringify(response)});
        }
        else {
            responseCallback({"payload": JSON.stringify({"subscribed": true})}); // simulate subscription answer
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
}
