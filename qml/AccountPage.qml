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
 * Signing in with a Community Account, or skipping it.
 *
 * com.palm.accountservices (org.webosports.service.communityaccount) signs
 * in, makes the signed-in account the device's profile and keeps the token it
 * gets back; the password is only passed on, never kept here or there.
 */
BasePage {
    id: page

    title: "Your webOS account"
    forwardButtonText: signedInAs !== "" ? "Next" : "Skip"
    keyboardFocusItem: email.activeFocus ? email : password

    //! The account signed in with on this page, "" while there is none.
    property string signedInAs: ""
    property bool busy: false

    readonly property string authenticateUri: "luna://com.palm.accountservices/authenticateAccount"
    readonly property string unavailableText: "Signing in is not available right now. You can sign in later from Accounts."

    LunaService {
        id: service
        objectName: "accountService"
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    // What the service said, shown as plain text and kept short: it can come
    // from the account server.
    function showError(text) {
        status.isError = true;
        status.text = (text && text.length) ? String(text).substring(0, 200) : unavailableText;
    }

    function signIn() {
        if (busy)
            return;
        var address = email.text.trim();
        if (address.length === 0 || password.text.length === 0) {
            showError("Please enter your e-mail address and password.");
            return;
        }
        busy = true;
        status.isError = false;
        status.text = "Signing in...";
        Qt.inputMethod.hide();
        var args = JSON.stringify({ email: address, password: password.text });
        // Not kept any longer than the call needs it.
        password.text = "";
        service.call(authenticateUri, args, signInReply, signInFailed);
    }

    function signInReply(message) {
        busy = false;
        var reply = null;
        try {
            reply = JSON.parse(message.payload);
        } catch (e) {
            reply = null;
        }
        if (!reply || reply.returnValue !== true) {
            showError(reply ? reply.errorText : "");
            return;
        }
        signedInAs = String(reply.username || reply.accountAlias || email.text.trim());
        status.isError = false;
        status.text = "Signed in as " + signedInAs + ".";
    }

    function signInFailed(error) {
        busy = false;
        showError("");
    }

    Flickable {
        id: flick
        objectName: "accountFlick"
        anchors.fill: content
        contentWidth: width
        contentHeight: column.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollIndicator.vertical: ScrollIndicator { }

        Column {
            id: column
            width: flick.width
            spacing: Units.gu(1)

            Text {
                width: parent.width
                wrapMode: Text.Wrap
                text: "Sign in with your Community Account to use it on this device, or skip this and sign in later from Accounts."
                color: "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            TextField {
                id: email
                objectName: "accountEmail"
                width: parent.width
                height: Units.gu(4)
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "E-mail address"
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                enabled: !busy && signedInAs === ""
                onAccepted: password.forceActiveFocus()
            }

            TextField {
                id: password
                objectName: "accountPassword"
                width: parent.width
                height: Units.gu(4)
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "Password"
                echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                enabled: !busy && signedInAs === ""
                onAccepted: page.signIn()
            }

            ChoiceBox {
                id: showPassword
                text: "Show password"
                visible: signedInAs === ""
            }

            Button {
                id: signInButton
                objectName: "accountSignIn"
                width: buttonWidth
                text: "Sign in"
                visible: signedInAs === ""
                enabled: !busy
                onClicked: page.signIn()
            }

            Text {
                id: status
                objectName: "accountStatus"
                property bool isError: false
                width: parent.width
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                visible: text.length > 0
                color: isError ? "#ff8a80" : "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            Text {
                objectName: "accountPrivacy"
                width: parent.width
                wrapMode: Text.Wrap
                text: "Your e-mail address and password are sent over an encrypted connection to the Community Account service at appcatalog.webosarchive.org. The password is not stored on this device."
                color: "white"
                opacity: 0.7
                font.pixelSize: FontUtils.sizeToPixels("small")
            }
        }
    }
}
