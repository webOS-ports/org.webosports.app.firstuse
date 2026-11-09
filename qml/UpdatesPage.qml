/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
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

import QtQuick 2.6
import QtQuick.Controls 2.0

import LunaNext.Common 0.1
import LuneOS.Service 1.0

/*
 * Installing a system update before setup goes on, as a phone does on its
 * first start. The step is only seen when there is one: main.qml checks in
 * the background on the step before and passes it over when there is none;
 * when the answer is not in yet, this page checks and goes on by itself if
 * there is nothing to install (or no answer that says there is).
 *
 * org.webosports.service.update does the work, as for the Settings app's
 * System Updates page: checkUpdate, then the downloadUpdate subscription
 * ({percentage}, then {finished} or {error, msg, needCheck}), then
 * initiateUpdate, which restarts the device into the update. The service
 * shows no toast of its own while First Use runs.
 *
 * Before the restart the page leaves the systemservice preference
 * firstUseResume set to "Updates"; main.qml reads it when First Use starts
 * again and comes back here (resumed), so setup goes on where it was, with
 * what was chosen before kept by the system.
 */
BasePage {
    id: page

    title: "Software Update"

    readonly property string updateService: "org.webosports.service.update"
    readonly property string resumeKey: "firstUseResume"

    //! First Use came back here after installing an update.
    property bool resumed: false
    //! checkUpdate's reply that said there is an update, when main.qml
    //! checked before this step opened: it is not asked again.
    property var knownReply: null
    //! Went on by itself, having nothing to offer: back() steps over it.
    property bool passedOver: false

    // "checking", "uptodate", "available", "downloading", "installing" or
    // "failed". Not "state": that is Item's.
    property string updateState: "checking"
    property string statusText: ""
    property real percentage: 0
    property string localVersion: ""
    //! The newest version on offer, "" while there is none.
    property string newVersion: ""
    property var changes: []
    property var _downloadCall: null

    readonly property bool working: updateState === "downloading" || updateState === "installing"

    hasBackButton: !working && !resumed
    forwardButtonVisible: !working
    forwardButtonText: updateState === "available" ? "Later"
                     : updateState === "checking" ? "Skip" : "Next"

    LunaService {
        id: luna
        objectName: "updatesService"
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component.onCompleted: {
        if (resumed)
            setResume("");
        retrieveVersion();
        if (knownReply) {
            updateState = "checking";
            _checkReply(knownReply);
        } else {
            checkForUpdate();
        }
    }

    // The step is only for installing an update: with none to offer (or no
    // answer that says there is one), setup goes on without it.
    function goOnWithoutIt() {
        if (pageStack.currentItem !== page)
            return;
        passedOver = true;
        pageStack.next();
    }

    function _parse(message) {
        if (!message || !message.payload)
            return null;
        try {
            return JSON.parse(message.payload);
        } catch (e) {
            return null;
        }
    }

    // A version's changes as lines, no more than a list needs. In a model
    // they come as a list type, not a JS Array, so they are read by index.
    function changeLines(list) {
        var lines = [];
        var n = list && typeof list !== "string" && list.length !== undefined ? Math.min(list.length, 20) : 0;
        for (var i = 0; i < n; i++)
            lines.push("- " + String(list[i]).substring(0, 200));
        return lines.join("\n");
    }

    function _fail(text) {
        updateState = "failed";
        statusText = text;
    }

    // What the service says, kept short: it can be the feed's or the downloadmanager's.
    function _reason(r) {
        var t = r && (r.msg || r.message || r.errorText);
        return t ? String(t).substring(0, 200) : "";
    }

    function retrieveVersion() {
        luna.call("luna://" + updateService + "/retrieveVersion", "{}", function(message) {
            var r = _parse(message);
            if (r && r.returnValue === true && r.localVersion !== undefined)
                localVersion = String(r.localVersion);
        }, function() { });
    }

    function checkForUpdate() {
        updateState = "checking";
        newVersion = "";
        changes = [];
        statusText = "Checking for updates...";
        luna.call("luna://" + updateService + "/checkUpdate", "{}", _checkReply, _checkFailed);
    }

    function _checkReply(message) {
        if (updateState !== "checking")
            return;
        var r = _parse(message);
        if (!r || r.returnValue === false || r.success !== true) {
            _fail("Could not check for updates" + (_reason(r) ? ": " + _reason(r) : ".") +
                  " You can check later in Settings, System Updates.");
            goOnWithoutIt();
            return;
        }
        if (r.needUpdate === true) {
            changes = Array.isArray(r.changesSinceLast) ? r.changesSinceLast : [];
            newVersion = changes.length > 0 && changes[0].version !== undefined ? String(changes[0].version) : "";
            updateState = "available";
            statusText = "A system update is available" + (newVersion !== "" ? ": version " + newVersion : "") +
                    ". Install it now, or later from Settings, System Updates.";
        } else {
            updateState = "uptodate";
            statusText = resumed ? "The update is installed. This device is up to date."
                                 : "This device is up to date.";
            goOnWithoutIt();
        }
    }

    function _checkFailed(error) {
        if (updateState !== "checking")
            return;
        _fail("Could not check for updates. You can check later in Settings, System Updates.");
        goOnWithoutIt();
    }

    function installNow() {
        if (updateState !== "available" && !(updateState === "failed" && newVersion !== ""))
            return;
        _endDownload();
        updateState = "downloading";
        percentage = 0;
        statusText = "Downloading the update...";
        _downloadCall = luna.subscribe("luna://" + updateService + "/downloadUpdate",
                                       JSON.stringify({ subscribe: true }), _downloadReply, _downloadFailed);
    }

    function _downloadReply(message) {
        if (updateState !== "downloading")
            return;
        var r = _parse(message);
        if (!r)
            return;
        if (r.error === true || r.returnValue === false) {
            _endDownload();
            if (r.needCheck === true) {
                // What the check found is no longer in the feed: look again.
                checkForUpdate();
                return;
            }
            _fail("The download failed" + (_reason(r) ? ": " + _reason(r) : ".") +
                  " Try again, or go on and install it later from Settings, System Updates.");
            return;
        }
        if (r.finished === true) {
            _endDownload();
            percentage = 100;
            install();
            return;
        }
        if (r.percentage !== undefined) {
            var p = parseFloat(r.percentage);
            if (!isNaN(p)) {
                percentage = p;
                statusText = "Downloading the update: " + Math.floor(p) + "%";
            }
        }
    }

    function _downloadFailed(error) {
        if (updateState !== "downloading")
            return;
        _endDownload();
        _fail("The download failed. Try again, or go on and install it later from Settings, System Updates.");
    }

    function cancelDownload() {
        if (updateState !== "downloading")
            return;
        _endDownload();
        updateState = "available";
        statusText = "The download was stopped. Install the update now, or later from Settings, System Updates.";
    }

    function _endDownload() {
        if (_downloadCall) {
            _downloadCall.cancel();
            _downloadCall = null;
        }
    }

    // Where First Use goes on after the restart, then the restart.
    function install() {
        updateState = "installing";
        statusText = "Installing the update. The device restarts, and setup goes on after it.";
        setResume("Updates", function(ok) {
            if (!ok) {
                // Restarting would start setup over: better not to.
                _fail("The update could not be started: setup could not keep its place. " +
                      "Go on, and install it later from Settings, System Updates.");
                return;
            }
            luna.call("luna://" + updateService + "/initiateUpdate", "{}", _initiateReply, _initiateFailed);
        });
    }

    function _initiateReply(message) {
        var r = _parse(message);
        if (r && r.success === true)
            return;     // the device restarts
        setResume("");
        _fail("The update could not be started" + (_reason(r) ? ": " + _reason(r) : ".") +
              " Go on, and install it later from Settings, System Updates.");
    }

    function _initiateFailed(error) {
        setResume("");
        _fail("The update could not be started. Go on, and install it later from Settings, System Updates.");
    }

    // "" clears it. done(ok), if given, once systemservice has answered.
    function setResume(where, done) {
        var prefs = {};
        prefs[resumeKey] = where;
        luna.call("luna://com.palm.systemservice/setPreferences", JSON.stringify(prefs), function(message) {
            var r = _parse(message);
            if (done)
                done(r !== null && r.returnValue === true);
        }, function() {
            if (done)
                done(false);
        });
    }

    Flickable {
        id: flick
        objectName: "updatesFlick"
        anchors.fill: content
        contentWidth: width
        contentHeight: column.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator { }

        Column {
            id: column
            width: flick.width
            spacing: Units.gu(1.5)

            Text {
                objectName: "updatesStatus"
                width: parent.width
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: statusText
                color: updateState === "failed" ? "#ff8a80" : "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            Text {
                objectName: "updatesVersion"
                width: parent.width
                visible: localVersion !== ""
                text: "This device runs LuneOS " + localVersion + "."
                color: "white"
                opacity: 0.7
                font.pixelSize: FontUtils.sizeToPixels("small")
            }

            ProgressBar {
                objectName: "updatesProgress"
                width: parent.width
                visible: updateState === "checking" || working
                indeterminate: updateState !== "downloading" || percentage <= 0
                from: 0
                to: 100
                value: percentage
            }

            Button {
                objectName: "updatesInstall"
                width: buttonWidth
                text: updateState === "failed" ? "Try again" : "Install now"
                visible: updateState === "available" || (updateState === "failed" && newVersion !== "")
                onClicked: page.installNow()
            }

            Button {
                objectName: "updatesCheckAgain"
                width: buttonWidth
                text: "Check again"
                visible: updateState === "failed" && newVersion === ""
                onClicked: page.checkForUpdate()
            }

            Button {
                objectName: "updatesCancel"
                width: buttonWidth
                text: "Stop download"
                visible: updateState === "downloading"
                onClicked: page.cancelDownload()
            }

            Text {
                width: parent.width
                visible: changes.length > 0 && !working
                text: "What is new"
                color: "white"
                font.bold: true
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            Repeater {
                model: working ? [] : changes
                delegate: Text {
                    width: column.width
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    // The feed's words: plain text, and only as much as a list needs.
                    text: "Version " + String(modelData.version).substring(0, 20) + "\n" + page.changeLines(modelData.changes)
                    color: "white"
                    opacity: 0.85
                    font.pixelSize: FontUtils.sizeToPixels("small")
                }
            }
        }
    }
}
