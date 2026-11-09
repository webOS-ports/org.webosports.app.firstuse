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
 * Making a Community Account, opened from the Account page and not one of
 * First Use's steps: Back (or "Sign in instead") goes back to it.
 *
 * The account server's terms of service are fetched as the page opens and
 * can be read on a page of their own (TermsPage); the account is made only
 * once "I agree" is ticked. The server answers a new account as a sign-in,
 * so the device is signed in with it at once: accountMade(name) tells the
 * Account page, which says so and goes on with setup.
 */
BasePage {
    id: page

    title: "Create a Community Account"
    customBack: true
    forwardButtonVisible: false
    keyboardFocusItem: firstName.activeFocus ? firstName
                     : lastName.activeFocus ? lastName
                     : email.activeFocus ? email : password

    //! The address typed on the Account page, to start from.
    property string prefillEmail: ""
    property bool busy: false
    property bool made: false
    //! The server's terms, as plain text; "" until they have come.
    property string terms: ""
    property bool termsBusy: false
    property alias agreed: agree.checked
    //! How long "Your account is ready" shows before going on.
    property int goOnAfterMs: 1500

    readonly property string createUri: "luna://com.palm.accountservices/createNovaAccount"
    readonly property string termsUri: "luna://com.palm.accountservices/getTermsAndConditions"
    readonly property bool canCreate: !busy && !made && agreed && terms !== ""

    signal accountMade(string name)

    onBackClicked: if (!busy && !made) pageStack.pop()

    LunaService {
        id: service
        objectName: "accountService"
        name: "org.webosports.app.firstuse"
        usePrivateBus: true
    }

    Component {
        id: termsPage
        TermsPage { }
    }

    Timer {
        id: goOn
        interval: page.goOnAfterMs
        property string name: ""
        onTriggered: page.accountMade(name)
    }

    Component.onCompleted: {
        email.text = prefillEmail;
        fetchTerms();
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

    function fetchTerms() {
        if (terms !== "" || termsBusy)
            return;
        termsBusy = true;
        service.call(termsUri, "{}", termsReply, termsFailed);
    }

    function termsReply(message) {
        termsBusy = false;
        var reply = Account.parse(message);
        if (reply && reply.returnValue === true && typeof reply.terms === "string" && reply.terms.trim().length > 0) {
            // A screenful or so is what the server sends; more than this is not terms.
            terms = reply.terms.substring(0, 20000);
            // The failure to fetch them, whatever its code, is over.
            if (status.text === Account.SENTENCES["TERMS_ERROR"])
                status.text = "";
            return;
        }
        var why = Account.refusal(reply);
        showError(Account.SENTENCES["TERMS_ERROR"], why.code === "UNKNOWN" ? "TERMS_ERROR" : why.code);
    }

    function termsFailed(error) {
        termsBusy = false;
        showError(Account.SENTENCES["TERMS_ERROR"], Account.NO_SERVICE);
    }

    function openTerms() {
        if (terms === "") {
            fetchTerms();
            return;
        }
        var p = pageStack.push(termsPage, { terms: terms });
        p.agreedToTerms.connect(function() {
            agree.checked = true;
        });
    }

    function createAccount() {
        if (!canCreate)
            return;
        var address = email.text.trim();
        var first = firstName.text.trim();
        if (first.length === 0 || address.length === 0 || password.text.length === 0) {
            showError("Please enter your first name, e-mail address and a password.", "");
            return;
        }
        if (Account.utf8Length(password.text) < Account.MIN_PASSWORD) {
            showError(Account.SENTENCES["WEAK_PASSWORD"], "");
            return;
        }
        busy = true;
        status.isError = false;
        status.code = "";
        status.text = "Making your account...";
        Qt.inputMethod.hide();
        var payload = JSON.stringify({ firstName: first, lastName: lastName.text.trim(), email: address, password: password.text });
        // Not kept any longer than the call needs it.
        password.text = "";
        service.call(createUri, payload, createReply, createFailed);
    }

    function createReply(message) {
        busy = false;
        var reply = Account.parse(message);
        if (!reply || reply.returnValue !== true) {
            var why = Account.refusal(reply);
            showError(why.text, why.code);
            return;
        }
        made = true;
        goOn.name = String(reply.username || reply.accountAlias || email.text.trim());
        status.isError = false;
        status.code = "";
        status.text = "Your account is ready. Signed in as " + goOn.name + ".";
        goOn.start();
    }

    function createFailed(error) {
        busy = false;
        showError(Account.SENTENCES[Account.NO_SERVICE], Account.NO_SERVICE);
    }

    Flickable {
        id: flick
        objectName: "createFlick"
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

            TextField {
                id: firstName
                objectName: "createFirstName"
                width: parent.width
                height: Units.gu(4)
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "First name"
                inputMethodHints: Qt.ImhNoPredictiveText
                enabled: !busy && !made
                onAccepted: lastName.forceActiveFocus()
            }

            TextField {
                id: lastName
                objectName: "createLastName"
                width: parent.width
                height: Units.gu(4)
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "Last name (optional)"
                inputMethodHints: Qt.ImhNoPredictiveText
                enabled: !busy && !made
                onAccepted: email.forceActiveFocus()
            }

            TextField {
                id: email
                objectName: "createEmail"
                width: parent.width
                height: Units.gu(4)
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "E-mail address"
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                enabled: !busy && !made
                onAccepted: password.forceActiveFocus()
            }

            TextField {
                id: password
                objectName: "createPassword"
                width: parent.width
                height: Units.gu(4)
                font.pixelSize: FontUtils.sizeToPixels("medium")
                placeholderText: "Password (at least 8 characters)"
                echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                enabled: !busy && !made
                onAccepted: Qt.inputMethod.hide()
            }

            ChoiceBox {
                id: showPassword
                text: "Show password"
                visible: !made
            }

            ChoiceBox {
                id: agree
                objectName: "createAgree"
                width: parent.width
                text: "I agree to the Terms of Service"
                visible: !made
                enabled: !busy && terms !== ""
            }

            LinkText {
                objectName: "createReadTerms"
                width: parent.width
                text: terms !== "" ? "Read the Terms of Service"
                    : termsBusy ? "Fetching the Terms of Service..." : "Fetch the Terms of Service again"
                visible: !made
                enabled: !busy && !termsBusy
                onClicked: page.openTerms()
            }

            Button {
                objectName: "createAccount"
                width: buttonWidth
                text: "Create account"
                visible: !made
                enabled: page.canCreate
                onClicked: page.createAccount()
            }

            StatusText {
                id: status
                // Once laid out: the column places it after the change.
                onTextChanged: reveal.restart()
                onHeightChanged: if (visible) reveal.restart()
                objectName: "createStatus"
                width: parent.width
            }

            LinkText {
                objectName: "createHaveOne"
                width: parent.width
                text: "Already have an account? Sign in"
                visible: !made
                enabled: !busy
                onClicked: pageStack.pop()
            }

            Text {
                objectName: "createPrivacy"
                width: parent.width
                wrapMode: Text.Wrap
                text: "Your name, e-mail address and password are sent over an encrypted connection to the Community Account service at appcatalog.webosarchive.org, which keeps your name and e-mail address. The password is not stored on this device."
                color: "white"
                opacity: 0.7
                font.pixelSize: FontUtils.sizeToPixels("small")
            }
        }
    }
}
