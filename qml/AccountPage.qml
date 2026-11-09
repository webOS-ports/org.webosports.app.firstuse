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
 * Signing in with a Community Account, making one, or skipping it.
 *
 * com.palm.accountservices (org.webosports.service.communityaccount) signs
 * in or signs up, makes the account the device's profile and keeps the token
 * it gets back; the password is only passed on, never kept here or there.
 * Signing up shows the account server's terms first, as plain text: creating
 * the account is agreeing to them.
 */
BasePage {
    id: page

    title: "Your Community Account"
    forwardButtonText: signedInAs !== "" ? "Next" : "Skip"
    keyboardFocusItem: firstName.activeFocus ? firstName
                     : lastName.activeFocus ? lastName
                     : email.activeFocus ? email : password

    //! The account signed in with on this page, "" while there is none.
    property string signedInAs: ""
    property bool busy: false
    //! Making a new account rather than signing in to one.
    property bool creating: false
    //! The server's terms, as plain text; "" until they have come.
    property string terms: ""
    property bool termsBusy: false

    readonly property string authenticateUri: "luna://com.palm.accountservices/authenticateAccount"
    readonly property string createUri: "luna://com.palm.accountservices/createNovaAccount"
    readonly property string termsUri: "luna://com.palm.accountservices/getTermsAndConditions"
    readonly property string unavailableText: "Signing in is not available right now. You can sign in later from Accounts."
    readonly property string termsUnavailableText: "The terms of service could not be fetched, so an account cannot be made right now. Check the network and try again, or skip this."

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

    // The server's codes this page has words for; anything else as it came.
    function showRefusal(reply) {
        var known = {
            "AUTH_FAILED": "That e-mail address and password do not match an account.",
            "EMAIL_TAKEN": "There is already an account with this e-mail address. Sign in with it instead.",
            "INVALID_EMAIL": "Please enter a valid e-mail address.",
            "WEAK_PASSWORD": "The password needs at least 8 characters."
        };
        var code = reply ? String(reply.errorCode) : "";
        if (known.hasOwnProperty(code))
            showError(known[code]);
        else
            showError(reply ? reply.errorText : "");
    }

    function signIn() {
        if (busy)
            return;
        var address = email.text.trim();
        if (address.length === 0 || password.text.length === 0) {
            showError("Please enter your e-mail address and password.");
            return;
        }
        send(authenticateUri, { email: address, password: password.text }, "Signing in...");
    }

    function createAccount() {
        if (busy || terms === "")
            return;
        var address = email.text.trim();
        var first = firstName.text.trim();
        if (first.length === 0 || address.length === 0 || password.text.length === 0) {
            showError("Please enter your first name, e-mail address and a password.");
            return;
        }
        send(createUri, { firstName: first, lastName: lastName.text.trim(), email: address, password: password.text },
             "Making your account...");
    }

    function send(uri, args, doing) {
        busy = true;
        status.isError = false;
        status.text = doing;
        Qt.inputMethod.hide();
        var payload = JSON.stringify(args);
        // Not kept any longer than the call needs it.
        password.text = "";
        service.call(uri, payload, signInReply, signInFailed);
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
            showRefusal(reply);
            return;
        }
        signedInAs = String(reply.username || reply.accountAlias || email.text.trim());
        status.isError = false;
        status.text = (creating ? "Your account is ready. " : "") + "Signed in as " + signedInAs + ".";
    }

    function signInFailed(error) {
        busy = false;
        showError("");
    }

    function startCreating() {
        creating = true;
        status.text = "";
        if (terms === "" && !termsBusy) {
            termsBusy = true;
            service.call(termsUri, "{}", termsReply, termsFailed);
        }
    }

    function stopCreating() {
        creating = false;
        status.text = "";
    }

    function termsReply(message) {
        termsBusy = false;
        var reply = null;
        try {
            reply = JSON.parse(message.payload);
        } catch (e) {
            reply = null;
        }
        if (reply && reply.returnValue === true && typeof reply.terms === "string" && reply.terms.trim().length > 0) {
            // A screenful or so is what the server sends; more than this is not terms.
            terms = reply.terms.substring(0, 20000);
            return;
        }
        termsFailed("");
    }

    function termsFailed(error) {
        termsBusy = false;
        if (creating) {
            status.isError = true;
            status.text = termsUnavailableText;
        }
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
                objectName: "accountIntro"
                width: parent.width
                wrapMode: Text.Wrap
                text: creating
                      ? "Make a Community Account to use on this device. You will be signed in with it straight away."
                      : "Sign in with your Community Account to use it on this device, make one, or skip this and sign in later from Accounts."
                color: "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            TextField {
                id: firstName
                objectName: "accountFirstName"
                width: parent.width
                height: Units.gu(4)
                visible: creating
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "First name"
                inputMethodHints: Qt.ImhNoPredictiveText
                enabled: !busy && signedInAs === ""
                onAccepted: lastName.forceActiveFocus()
            }

            TextField {
                id: lastName
                objectName: "accountLastName"
                width: parent.width
                height: Units.gu(4)
                visible: creating
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "Last name (optional)"
                inputMethodHints: Qt.ImhNoPredictiveText
                enabled: !busy && signedInAs === ""
                onAccepted: email.forceActiveFocus()
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
                placeholderText: creating ? "Password (at least 8 characters)" : "Password"
                echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                enabled: !busy && signedInAs === ""
                onAccepted: creating ? Qt.inputMethod.hide() : page.signIn()
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
                visible: signedInAs === "" && !creating
                enabled: !busy
                onClicked: page.signIn()
            }

            Button {
                objectName: "accountStartCreate"
                width: buttonWidth
                text: "Create an account"
                visible: signedInAs === "" && !creating
                enabled: !busy
                onClicked: page.startCreating()
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
                width: parent.width
                visible: creating && signedInAs === ""
                text: "Terms of service"
                color: "white"
                font.bold: true
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            Text {
                objectName: "accountTerms"
                width: parent.width
                visible: creating && signedInAs === ""
                wrapMode: Text.Wrap
                // The server's words: plain text, so nothing in them is fetched or followed.
                textFormat: Text.PlainText
                text: terms !== "" ? terms : (termsBusy ? "Fetching the terms of service..." : "")
                color: "white"
                opacity: 0.85
                font.pixelSize: FontUtils.sizeToPixels("small")
            }

            Text {
                width: parent.width
                visible: creating && signedInAs === "" && terms !== ""
                wrapMode: Text.Wrap
                text: "By creating an account you agree to these terms."
                color: "white"
                font.pixelSize: FontUtils.sizeToPixels("medium")
            }

            Button {
                objectName: "accountCreate"
                width: buttonWidth
                text: "Create account"
                visible: creating && signedInAs === ""
                enabled: !busy && terms !== ""
                onClicked: page.createAccount()
            }

            Button {
                objectName: "accountHaveOne"
                width: buttonWidth
                text: "I have an account"
                visible: creating && signedInAs === ""
                enabled: !busy
                onClicked: page.stopCreating()
            }

            Text {
                objectName: "accountPrivacy"
                width: parent.width
                wrapMode: Text.Wrap
                text: creating
                      ? "Your name, e-mail address and password are sent over an encrypted connection to the Community Account service at appcatalog.webosarchive.org, which keeps your name and e-mail address. The password is not stored on this device."
                      : "Your e-mail address and password are sent over an encrypted connection to the Community Account service at appcatalog.webosarchive.org. The password is not stored on this device."
                color: "white"
                opacity: 0.7
                font.pixelSize: FontUtils.sizeToPixels("small")
            }
        }
    }
}
