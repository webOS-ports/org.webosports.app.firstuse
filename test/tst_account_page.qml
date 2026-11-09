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

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.LuneOS
import QtTest

import "../qml"

/*
 * The account page signing in, against test/imports' LunaService, which
 * lets the test answer as com.palm.accountservices would. Run with
 * test/run-tests.sh.
 */
Item {
    id: root
    width: 480
    height: 800

    StackView {
        id: pageStack
        anchors.fill: parent
        pushEnter: null
        pushExit: null
        popEnter: null
        popExit: null
        function next() { }
        function back() { }
    }

    Component {
        id: pageComponent
        AccountPage { }
    }

    TestCase {
        name: "AccountPage"
        when: windowShown

        readonly property string uri: "luna://com.palm.accountservices/authenticateAccount"

        property var page: null
        property var luna: null

        function init() {
            page = pageStack.push(pageComponent, {}, StackView.Immediate);
            verify(page !== null, "the page did not load");
            luna = findChild(page, "accountService");
            verify(luna !== null);
        }

        function cleanup() {
            pageStack.clear(StackView.Immediate);
        }

        function child(name) {
            var c = findChild(page, name);
            verify(c !== null, name);
            return c;
        }

        // A tap on what may be below the fold: the page scrolls it into view first, as a finger would.
        function tap(name) {
            var c = child(name);
            var flick = child("accountFlick");
            verify(c.visible, name + " is not shown");
            // Laid out first: the terms may just have come in.
            waitForRendering(flick);
            var at = c.mapToItem(flick.contentItem, 0, 0);
            flick.contentY = Math.max(0, Math.min(at.y, flick.contentHeight - flick.height));
            waitForRendering(flick);
            var inView = c.mapToItem(flick, 0, 0);
            verify(inView.y >= 0 && inView.y + c.height <= flick.height, name + " is not in view to tap");
            mouseClick(c);
        }

        function fill(address, password) {
            child("accountEmail").text = address;
            child("accountPassword").text = password;
        }

        // Fill in, tap Sign in, and return the call it sent.
        function signIn() {
            fill("  member@example.org ", "s3cret");
            mouseClick(child("accountSignIn"));
            compare(luna.callsTo(uri).length, 1, "no sign-in was sent");
            return luna.callsTo(uri)[0];
        }

        function test_skippingIsTheDefault() {
            compare(page.forwardButtonText, "Skip");
            compare(child("accountPassword").echoMode, TextInput.Password);
            compare(luna.calls.length, 0, "the page called something on its own");
        }

        function test_signInSendsTheTrimmedAddressAndForgetsThePassword() {
            var call = signIn();
            compare(call.args.email, "member@example.org");
            compare(call.args.password, "s3cret");
            compare(Object.keys(call.args).sort().join(","), "email,password");
            compare(child("accountPassword").text, "", "the password stayed in the field");
            verify(page.busy);
            verify(!child("accountSignIn").enabled, "Sign in can be tapped again while signing in");
            verify(!child("accountEmail").enabled);
        }

        function test_oneSignInAtATime() {
            signIn();
            page.signIn();
            compare(luna.callsTo(uri).length, 1);
        }

        function test_signedIn() {
            luna.reply(signIn(), { returnValue: true, accountAlias: "member@example.org", username: "Member" });
            compare(page.signedInAs, "Member");
            compare(page.forwardButtonText, "Next");
            verify(!page.busy);
            compare(child("accountStatus").text, "Signed in as Member.");
            verify(!child("accountSignIn").visible, "Sign in is still offered");
            verify(!child("accountEmail").enabled && !child("accountPassword").enabled);
        }

        function test_refusedSaysWhyAndCanBeTriedAgain() {
            luna.reply(signIn(), { returnValue: false, errorCode: "LOGIN_ERROR", errorText: "Wrong e-mail address or password" });
            compare(page.signedInAs, "");
            compare(page.forwardButtonText, "Skip");
            verify(!page.busy);
            var status = child("accountStatus");
            verify(status.isError);
            compare(status.text, "Wrong e-mail address or password");
            verify(child("accountSignIn").enabled && child("accountEmail").enabled && child("accountPassword").enabled);
            compare(child("accountEmail").text, "  member@example.org ", "the address has to be typed again");
        }

        function test_whatTheServerSaysIsPlainTextAndShort() {
            var html = "<a href=\"https://evil.example\">tap here</a><img src=\"x\">" + new Array(400).join("x");
            luna.reply(signIn(), { returnValue: false, errorText: html });
            var status = child("accountStatus");
            compare(status.textFormat, Text.PlainText);
            compare(status.text.length, 200);
            compare(status.text, html.substring(0, 200));
        }

        function test_noErrorTextOrAMalformedReply() {
            luna.reply(signIn(), { returnValue: false });
            compare(child("accountStatus").text, page.unavailableText);

            cleanup();
            init();
            luna.reply(signIn(), "{not json");
            compare(child("accountStatus").text, page.unavailableText);
            compare(page.signedInAs, "");

            // returnValue has to be true itself, not just something.
            cleanup();
            init();
            luna.reply(signIn(), { returnValue: "true", username: "Member" });
            compare(page.signedInAs, "");
        }

        function test_noServiceToSignInWith() {
            var call = signIn();
            call.onCallFailed("Service does not exist: com.palm.accountservices");
            verify(!page.busy);
            compare(child("accountStatus").text, page.unavailableText);
            compare(page.forwardButtonText, "Skip");
        }

        // ---- making an account ----

        readonly property string createUri: "luna://com.palm.accountservices/createNovaAccount"
        readonly property string termsUri: "luna://com.palm.accountservices/getTermsAndConditions"
        readonly property string someTerms: "Terms of Service\n\n1. Your account\n\n<b>not bold</b>"

        // Tap Create an account and answer the terms call.
        function startCreating(termsReply) {
            tap("accountStartCreate");
            compare(luna.callsTo(termsUri).length, 1, "the terms were not asked for");
            if (termsReply !== undefined)
                luna.reply(luna.callsTo(termsUri)[0], termsReply);
        }

        function fillNew() {
            child("accountFirstName").text = " Ada ";
            child("accountLastName").text = "Lovelace ";
            fill(" new@example.org ", "correct horse");
        }

        function test_creatingShowsTheTermsAsPlainTextBeforeAnythingCanBeSent() {
            verify(!child("accountFirstName").visible);
            startCreating();
            verify(page.creating);
            verify(child("accountFirstName").visible && child("accountLastName").visible);
            verify(!child("accountSignIn").visible, "Sign in is offered while making an account");
            verify(!child("accountCreate").enabled, "an account can be made before the terms are shown");
            luna.reply(luna.callsTo(termsUri)[0], { returnValue: true, terms: someTerms });
            var shown = child("accountTerms");
            compare(shown.textFormat, Text.PlainText);
            compare(shown.text, someTerms);
            verify(child("accountCreate").enabled);
        }

        function test_createSendsNameAddressAndPasswordAndForgetsThePassword() {
            startCreating({ returnValue: true, terms: someTerms });
            fillNew();
            tap("accountCreate");
            var calls = luna.callsTo(createUri);
            compare(calls.length, 1);
            compare(calls[0].args.firstName, "Ada");
            compare(calls[0].args.lastName, "Lovelace");
            compare(calls[0].args.email, "new@example.org");
            compare(calls[0].args.password, "correct horse");
            compare(Object.keys(calls[0].args).sort().join(","), "email,firstName,lastName,password");
            compare(child("accountPassword").text, "");
            compare(luna.callsTo(uri).length, 0, "a sign-in was sent as well");

            page.createAccount();
            compare(luna.callsTo(createUri).length, 1, "two at once");

            luna.reply(calls[0], { returnValue: true, accountAlias: "new@example.org", username: "Ada Lovelace" });
            compare(page.signedInAs, "Ada Lovelace");
            compare(page.forwardButtonText, "Next");
            compare(child("accountStatus").text, "Your account is ready. Signed in as Ada Lovelace.");
            verify(!child("accountCreate").visible && !child("accountTerms").visible);
        }

        function test_createNeedsAFirstNameAnAddressAndAPassword() {
            startCreating({ returnValue: true, terms: someTerms });
            fillNew();
            child("accountFirstName").text = "  ";
            tap("accountCreate");
            fillNew();
            child("accountEmail").text = "";
            tap("accountCreate");
            fillNew();
            child("accountPassword").text = "";
            tap("accountCreate");
            compare(luna.callsTo(createUri).length, 0);
            verify(child("accountStatus").isError);
        }

        function test_noTermsNoAccount() {
            startCreating({ returnValue: false, errorCode: "TERMS_ERROR" });
            verify(!child("accountCreate").enabled);
            compare(child("accountStatus").text, page.termsUnavailableText);
            fillNew();
            page.createAccount();
            compare(luna.callsTo(createUri).length, 0);

            // Blank terms are no terms either, and nor is no service.
            cleanup();
            init();
            startCreating({ returnValue: true, terms: "  \n " });
            verify(!child("accountCreate").enabled);
            cleanup();
            init();
            startCreating();
            luna.callsTo(termsUri)[0].onCallFailed("Service does not exist");
            verify(!child("accountCreate").enabled);
            compare(child("accountStatus").text, page.termsUnavailableText);
        }

        function test_theTermsAreFetchedOnce() {
            startCreating({ returnValue: true, terms: someTerms });
            tap("accountHaveOne");
            verify(!page.creating);
            verify(child("accountSignIn").visible);
            tap("accountStartCreate");
            compare(luna.callsTo(termsUri).length, 1);
            verify(child("accountCreate").enabled);
        }

        function test_theServersCodesInWords() {
            startCreating({ returnValue: true, terms: someTerms });
            fillNew();
            tap("accountCreate");
            luna.reply(luna.callsTo(createUri)[0], { returnValue: false, errorCode: "EMAIL_TAKEN", errorText: "account server error EMAIL_TAKEN" });
            compare(child("accountStatus").text, "There is already an account with this e-mail address. Sign in with it instead.");
            compare(page.signedInAs, "");
            verify(child("accountCreate").enabled);

            cleanup();
            init();
            luna.reply(signIn(), { returnValue: false, errorCode: "AUTH_FAILED", errorText: "wrong e-mail address or password" });
            compare(child("accountStatus").text, "That e-mail address and password do not match an account.");
        }

        function test_nothingIsSentWithoutBoth() {
            fill("", "s3cret");
            mouseClick(child("accountSignIn"));
            fill("   ", "s3cret");
            mouseClick(child("accountSignIn"));
            fill("member@example.org", "");
            mouseClick(child("accountSignIn"));
            compare(luna.callsTo(uri).length, 0);
            verify(child("accountStatus").isError);
            verify(child("accountStatus").text.length > 0);
        }
    }
}
