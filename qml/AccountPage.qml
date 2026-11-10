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

import "js/Account.js" as Account

/*
 * Signing in with a Community Account, or skipping it. Making a new one is a
 * page of its own (CreateAccountPage), opened from the link here.
 *
 * com.palm.accountservices (org.webosports.service.communityaccount) signs
 * in, makes the account the device's profile and keeps the token it gets
 * back; the password is only passed on, never kept here or there. Once
 * signed in - here or on the new account's page - the page says so for a
 * moment and setup goes on by itself.
 */
BasePage {
    id: page

    title: "Your Community Account"
    forwardButtonText: signedInAs !== "" ? "Next" : "Skip"
    keyboardFocusItem: email.activeFocus ? email : password

    //! The account signed in with, "" while there is none.
    property string signedInAs: ""
    property bool busy: false
    //! How long "Signed in as ..." shows before setup goes on.
    property int goOnAfterMs: 1500

    readonly property string authenticateUri: "luna://com.palm.accountservices/authenticateAccount"
    readonly property string unavailableText: Account.UNAVAILABLE

    LunaService {
        id: service
        objectName: "accountService"
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component {
        id: createPage
        CreateAccountPage { }
    }

    // Next tapped while "Signed in as ..." shows: setup has gone on already,
    // and going on again when the wait is up would pass the last step by.
    onForwardClicked: goOn.stop()

    Timer {
        id: goOn
        objectName: "accountGoOn"
        interval: page.goOnAfterMs
        // Only from here: Back (or anything else) may have left this page.
        onTriggered: if (pageStack.currentItem === page) pageStack.next()
    }

    Timer {
        id: reveal
        interval: 50
        onTriggered: page.revealStatus()
    }

    // A message below the fold is no message: it is scrolled to.
    function revealStatus() {
        if (!status.visible)
            return;
        var y = status.mapToItem(column, 0, 0).y;
        if (y + status.height > flick.contentY + flick.height)
            flick.contentY = Math.max(0, Math.min(y + status.height - flick.height, flick.contentHeight - flick.height));
        else if (y < flick.contentY)
            flick.contentY = y;
    }

    function showError(text, code) {
        status.isError = true;
        status.text = text;
        status.code = code || "";
    }

    function signIn() {
        if (busy || signedInAs !== "")
            return;
        var address = email.text.trim();
        if (address.length === 0 || password.text.length === 0) {
            showError("Please enter your e-mail address and password.", "");
            return;
        }
        busy = true;
        status.isError = false;
        status.code = "";
        status.text = "Signing in...";
        Qt.inputMethod.hide();
        var payload = JSON.stringify({ email: address, password: password.text });
        // Not kept any longer than the call needs it.
        password.text = "";
        service.call(authenticateUri, payload, signInReply, signInFailed);
    }

    function signInReply(message) {
        busy = false;
        var reply = Account.parse(message);
        if (!reply || reply.returnValue !== true) {
            var why = Account.refusal(reply);
            showError(why.text, why.code);
            return;
        }
        signedIn(String(reply.username || reply.accountAlias || email.text.trim()), false);
    }

    function signInFailed(error) {
        busy = false;
        showError(Account.SENTENCES[Account.NO_SERVICE], Account.NO_SERVICE);
    }

    // Signed in, here or on the new account's page: say so, then go on.
    function signedIn(name, made) {
        signedInAs = name;
        status.isError = false;
        status.code = "";
        status.text = (made ? "Your account is ready. " : "") + "Signed in as " + name + ".";
        goOn.restart();
    }

    function openCreate() {
        if (busy || signedInAs !== "")
            return;
        status.text = "";
        status.code = "";
        var p = pageStack.push(createPage, { prefillEmail: email.text.trim() });
        p.accountMade.connect(function(name) {
            // Back here, with nothing above, before setup goes on.
            pageStack.pop(page, StackView.Immediate);
            signedIn(name, true);
        });
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
                objectName: "accountSignIn"
                width: buttonWidth
                text: "Sign in"
                visible: signedInAs === ""
                enabled: !busy
                onClicked: page.signIn()
            }

            StatusText {
                id: status
                // Once laid out: the column places it after the change.
                onTextChanged: reveal.restart()
                onHeightChanged: if (visible) reveal.restart()
                objectName: "accountStatus"
                width: parent.width
            }

            LinkText {
                objectName: "accountStartCreate"
                width: parent.width
                text: "New here? Create a Community Account"
                visible: signedInAs === ""
                enabled: !busy
                onClicked: page.openCreate()
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
