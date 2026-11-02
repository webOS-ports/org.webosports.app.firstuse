/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
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
import QtQuick.Layouts 1.0
import QtQuick.Controls.LuneOS 2.0

import LunaNext.Common 0.1

/*
 * What happened to a connect the user asked for, when it did not work. The
 * same two cases as Settings' popup of this name, but this page talks to
 * com.palm.wifi rather than to connman, so it gets that service's errors and
 * stops an attempt through its "cancel".
 *
 * An earlier attempt is still running (a tap on a network that is connecting,
 * or a connect refused as "Already connecting"): say so and offer to stop it,
 * since otherwise nothing at all happens. Or the attempt failed: say why.
 */
Popup {
    id: connectProblemPopup

    // WCA_API_ERROR_ALREADY_CONNECTING and _ALREADY_CONNECTED in
    // webos-connman-adapter's errors.h.
    readonly property int errorAlreadyConnecting: 101
    readonly property int errorAlreadyConnected: 165
    // WCA_API_ERROR_UNKNOWN: what a failure without a reason from connman gets.
    readonly property int errorUnknown: 1

    property string ssid: ""
    // true: an earlier attempt is still running; false: this one failed.
    property bool busy: false
    property string message: ""

    signal stopConnecting()

    modal: true
    dim: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width - Units.gu(4), Units.gu(46))

    function showBusy(networkSsid) {
        ssid = networkSsid;
        busy = true;
        message = "";
        open();
    }

    function showFailure(networkSsid, text) {
        ssid = networkSsid;
        busy = false;
        message = text;
        open();
    }

    /*
     * Words for a refused connect, or "" when there is nothing to tell. The
     * service's errorText is already written for people.
     */
    function failureText(errorCode, errorText) {
        if (errorCode === errorAlreadyConnected)
            return "";
        if (errorCode === errorUnknown || !errorText)
            return "Could not connect.";
        return errorText + ".";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Units.gu(2)

        Label {
            Layout.fillWidth: true
            text: connectProblemPopup.ssid
            font.bold: true
            elide: Text.ElideRight
            font.pixelSize: FontUtils.sizeToPixels("medium")
        }

        Label {
            objectName: "connectProblemText"
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            font.pixelSize: FontUtils.sizeToPixels("medium")
            text: connectProblemPopup.busy
                  ? "Still trying to connect from an earlier attempt. Stop it, "
                    + "then tap the network to try again."
                  : connectProblemPopup.message + " Tap the network to try again."
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Units.gu(1)

            Button {
                objectName: "connectProblemStop"
                Layout.fillWidth: true
                visible: connectProblemPopup.busy
                text: "Stop connecting"
                LuneOSButton.mainColor: LuneOSButton.negativeColor
                LuneOSButton.textColor: "white"
                onClicked: {
                    connectProblemPopup.stopConnecting();
                    connectProblemPopup.close();
                }
            }
            Button {
                objectName: "connectProblemDismiss"
                Layout.fillWidth: true
                text: connectProblemPopup.busy ? "Keep waiting" : "OK"
                LuneOSButton.mainColor: LuneOSButton.secondaryColor
                onClicked: connectProblemPopup.close()
            }
        }
    }
}
