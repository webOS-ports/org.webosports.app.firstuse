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
