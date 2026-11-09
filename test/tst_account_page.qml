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
 * The Community Account pages - signing in (AccountPage), making an account
 * (CreateAccountPage) and its terms (TermsPage) - against test/imports'
 * LunaService, which lets the test answer as com.palm.accountservices
 * would. Run with test/run-tests.sh.
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
        replaceEnter: null
        replaceExit: null
        // First Use's own steps, counted: the pages here only open their own.
        property int nextCount: 0
        property int backCount: 0
        function next() { nextCount++; }
        function back() { backCount++; }
    }

    Component {
        id: pageComponent
        AccountPage { goOnAfterMs: 20 }
    }

    TestCase {
        name: "AccountPage"
        when: windowShown

        readonly property string uri: "luna://com.palm.accountservices/authenticateAccount"
        readonly property string createUri: "luna://com.palm.accountservices/createNovaAccount"
        readonly property string termsUri: "luna://com.palm.accountservices/getTermsAndConditions"
        readonly property string someTerms: "Terms of Service\n\n1. Your account\n\n<b>not bold</b>"

        property var page: null
        property var luna: null

        function init() {
            pageStack.nextCount = 0;
            pageStack.backCount = 0;
            page = pageStack.push(pageComponent, {}, StackView.Immediate);
            verify(page !== null, "the page did not load");
            luna = findChild(page, "accountService");
            verify(luna !== null);
        }

        function cleanup() {
            pageStack.clear(StackView.Immediate);
        }

        function child(name, from) {
            var c = findChild(from || page, name);
            verify(c !== null, name);
            return c;
        }

        // A tap on what may be below the fold: the page scrolls it into view first, as a finger would.
        function tap(name, from, flickName) {
            var p = from || page;
            var c = child(name, p);
            var flick = child(flickName || "accountFlick", p);
            verify(c.visible, name + " is not shown");
            waitForRendering(flick);
            var at = c.mapToItem(flick.contentItem, 0, 0);
            flick.contentY = Math.max(0, Math.min(at.y, flick.contentHeight - flick.height));
            waitForRendering(flick);
            var inView = c.mapToItem(flick, 0, 0);
            verify(inView.y >= 0 && inView.y + c.height <= flick.height, name + " is not in view to tap");
            mouseClick(c);
        }

        function statusOf(p, name) {
            var s = child(name, p);
            return { text: child("statusLine", s).text, code: s.code, codeShown: child("statusCode", s).visible, isError: s.isError };
        }

        function fill(address, password) {
            child("accountEmail").text = address;
            child("accountPassword").text = password;
        }

        // Fill in, tap Sign in, and return the call it sent.
        function signIn() {
            fill("  member@example.org ", "s3cret");
            tap("accountSignIn");
            compare(luna.callsTo(uri).length, 1, "no sign-in was sent");
            return luna.callsTo(uri)[0];
        }

        // ---- signing in ----

        function test_skippingIsTheDefault() {
            compare(page.forwardButtonText, "Skip");
            compare(child("accountPassword").echoMode, TextInput.Password);
            compare(luna.calls.length, 0, "the page called something on its own");
            verify(!child("accountStatus").visible);
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
            verify(!child("accountStartCreate").enabled, "an account can be made while signing in");
        }

        function test_oneSignInAtATime() {
            signIn();
            page.signIn();
            compare(luna.callsTo(uri).length, 1);
        }

        function test_signedInSaysSoThenGoesOn() {
            luna.reply(signIn(), { returnValue: true, accountAlias: "member@example.org", username: "Member" });
            compare(page.signedInAs, "Member");
            compare(page.forwardButtonText, "Next");
            verify(!page.busy);
            var s = statusOf(page, "accountStatus");
            compare(s.text, "Signed in as Member.");
            verify(!s.isError && !s.codeShown);
            verify(!child("accountSignIn").visible, "Sign in is still offered");
            verify(!child("accountStartCreate").visible, "making an account is still offered");
            verify(!child("accountEmail").enabled && !child("accountPassword").enabled);
            compare(pageStack.nextCount, 0, "went on before saying who is signed in");
            tryCompare(pageStack, "nextCount", 1, 2000, "setup did not go on");
            wait(100);
            compare(pageStack.nextCount, 1, "went on twice");
        }

        function test_refusedSaysWhyWithItsCodeAndCanBeTriedAgain() {
            luna.reply(signIn(), { returnValue: false, errorCode: "AUTH_FAILED", errorText: "wrong e-mail address or password" });
            compare(page.signedInAs, "");
            compare(page.forwardButtonText, "Skip");
            verify(!page.busy);
            var s = statusOf(page, "accountStatus");
            verify(s.isError);
            compare(s.text, "That e-mail address and password do not match an account.");
            compare(s.code, "AUTH_FAILED");
            verify(s.codeShown, "the code is not shown");
            verify(child("accountSignIn").enabled && child("accountEmail").enabled && child("accountPassword").enabled);
            compare(child("accountEmail").text, "  member@example.org ", "the address has to be typed again");
            wait(100);
            compare(pageStack.nextCount, 0);
        }

        function test_eachCodeInWords() {
            var words = {
                "SERVER_UNREACHABLE": "The account server cannot be reached. Check that the device is online, then try again.",
                "SERVER_ERROR": "The account server had a problem. Please try again later.",
                "CONNECTOR_EXCEPTION": "Something went wrong on this device while signing in. You can sign in later from Accounts.",
                "LOGIN_ERROR": "That e-mail address and password do not match an account."
            };
            for (var code in words) {
                cleanup();
                init();
                luna.reply(signIn(), { returnValue: false, errorCode: code, errorText: "Error: palm://com.palm.db/put {\"token\":\"x\"}: db" });
                var s = statusOf(page, "accountStatus");
                compare(s.text, words[code], code);
                compare(s.code, code);
            }
        }

        // The service's errorText is for the log: bus calls, payloads, the server's words.
        function test_whatTheServiceSaysIsNotShown() {
            var html = "<a href=\"https://evil.example\">tap here</a>";
            luna.reply(signIn(), { returnValue: false, errorCode: "<b>X</b>", errorText: html });
            var s = statusOf(page, "accountStatus");
            compare(s.text, page.unavailableText);
            compare(s.code, "UNKNOWN", "a code that is not a word is not shown as one");
            compare(child("statusLine", child("accountStatus")).textFormat, Text.PlainText);
        }

        function test_noErrorTextOrAMalformedReply() {
            luna.reply(signIn(), { returnValue: false });
            compare(statusOf(page, "accountStatus").text, page.unavailableText);
            compare(statusOf(page, "accountStatus").code, "UNKNOWN");

            cleanup();
            init();
            luna.reply(signIn(), "{not json");
            compare(statusOf(page, "accountStatus").code, "BAD_REPLY");
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
            var s = statusOf(page, "accountStatus");
            compare(s.text, page.unavailableText);
            compare(s.code, "NO_SERVICE");
            compare(page.forwardButtonText, "Skip");
        }

        function test_nothingIsSentWithoutBoth() {
            fill("", "s3cret");
            tap("accountSignIn");
            fill("   ", "s3cret");
            tap("accountSignIn");
            fill("member@example.org", "");
            tap("accountSignIn");
            compare(luna.callsTo(uri).length, 0);
            verify(statusOf(page, "accountStatus").isError);
        }

        // ---- making an account: a page of its own ----

        property var made: null
        property var madeLuna: null

        // Tap the link, and answer the terms call the new page makes.
        function openCreate(termsReply) {
            child("accountEmail").text = " new@example.org ";
            tap("accountStartCreate");
            compare(pageStack.depth, 2, "no page of its own");
            made = pageStack.currentItem;
            compare(made.title, "Create a Community Account");
            made.goOnAfterMs = 20;
            madeLuna = child("accountService", made);
            compare(madeLuna.callsTo(termsUri).length, 1, "the terms were not asked for");
            if (termsReply !== undefined)
                madeLuna.reply(madeLuna.callsTo(termsUri)[0], termsReply);
        }

        function fillNew() {
            child("createFirstName", made).text = " Ada ";
            child("createLastName", made).text = "Lovelace ";
            child("createEmail", made).text = " new@example.org ";
            child("createPassword", made).text = "correct horse";
        }

        function tapNew(name) {
            tap(name, made, "createFlick");
        }

        function test_theCreatePageStartsFromTheAddressAndIsNoStepOfItsOwn() {
            openCreate();
            compare(child("createEmail", made).text, "new@example.org");
            verify(!made.forwardButtonVisible, "it has a forward button");
            compare(luna.calls.length, 0, "the Account page called something");
            // Back goes back to the Account page, not a First Use step back.
            made.backClicked();
            compare(pageStack.depth, 1);
            compare(pageStack.backCount, 0);
            compare(pageStack.currentItem, page);
        }

        function test_createWaitsForTheTermsAndTheTick() {
            openCreate();
            verify(!child("createAccount", made).enabled, "an account can be made before the terms are there");
            verify(!child("createAgree", made).enabled, "agreeing before the terms are there");
            madeLuna.reply(madeLuna.callsTo(termsUri)[0], { returnValue: true, terms: someTerms });
            verify(child("createAgree", made).enabled);
            verify(!child("createAgree", made).checked, "ticked for the user");
            verify(!child("createAccount", made).enabled, "an account can be made without agreeing");
            tapNew("createAgree");
            verify(child("createAgree", made).checked);
            verify(child("createAccount", made).enabled);
        }

        function test_theTermsArePlainTextOnAPageOfTheirOwn() {
            openCreate({ returnValue: true, terms: someTerms });
            tapNew("createReadTerms");
            compare(pageStack.depth, 3);
            var terms = pageStack.currentItem;
            compare(terms.title, "Terms of Service");
            var shown = child("termsText", terms);
            compare(shown.textFormat, Text.PlainText);
            compare(shown.text, someTerms);
            // Back: read, not agreed.
            terms.backClicked();
            compare(pageStack.depth, 2);
            verify(!child("createAgree", made).checked);
            // "I agree" ticks the box, and goes back.
            tapNew("createReadTerms");
            pageStack.currentItem.forwardClicked();
            compare(pageStack.depth, 2);
            compare(pageStack.currentItem, made);
            verify(child("createAgree", made).checked);
            compare(madeLuna.callsTo(termsUri).length, 1, "the terms were fetched again");
            compare(pageStack.backCount + pageStack.nextCount, 0);
        }

        function test_createSendsNameAddressAndPasswordThenGoesOnSignedIn() {
            openCreate({ returnValue: true, terms: someTerms });
            fillNew();
            tapNew("createAgree");
            tapNew("createAccount");
            var calls = madeLuna.callsTo(createUri);
            compare(calls.length, 1);
            compare(calls[0].args.firstName, "Ada");
            compare(calls[0].args.lastName, "Lovelace");
            compare(calls[0].args.email, "new@example.org");
            compare(calls[0].args.password, "correct horse");
            compare(Object.keys(calls[0].args).sort().join(","), "email,firstName,lastName,password");
            compare(child("createPassword", made).text, "");
            compare(madeLuna.callsTo(uri).length + luna.callsTo(uri).length, 0, "a sign-in was sent as well");

            made.createAccount();
            compare(madeLuna.callsTo(createUri).length, 1, "two at once");

            madeLuna.reply(calls[0], { returnValue: true, accountAlias: "new@example.org", username: "Ada Lovelace" });
            compare(statusOf(made, "createStatus").text, "Your account is ready. Signed in as Ada Lovelace.");
            verify(!child("createAccount", made).visible);
            made.backClicked();
            compare(pageStack.depth, 2, "Back left a made account's page before it went on");
            // Back on the Account page, signed in, and then on with setup.
            tryCompare(pageStack, "depth", 1, 2000);
            compare(pageStack.currentItem, page);
            compare(page.signedInAs, "Ada Lovelace");
            compare(statusOf(page, "accountStatus").text, "Your account is ready. Signed in as Ada Lovelace.");
            tryCompare(pageStack, "nextCount", 1, 2000, "setup did not go on");
        }

        function test_createNeedsAFirstNameAnAddressAndALongEnoughPassword() {
            openCreate({ returnValue: true, terms: someTerms });
            tapNew("createAgree");
            fillNew();
            child("createFirstName", made).text = "  ";
            tapNew("createAccount");
            fillNew();
            child("createEmail", made).text = "";
            tapNew("createAccount");
            fillNew();
            child("createPassword", made).text = "short";
            tapNew("createAccount");
            compare(madeLuna.callsTo(createUri).length, 0);
            var s = statusOf(made, "createStatus");
            compare(s.text, "The password needs at least 8 characters.");
            // Counted as the server counts it: five characters, ten bytes.
            child("createPassword", made).text = "ééééé";
            tapNew("createAccount");
            compare(madeLuna.callsTo(createUri).length, 1);
        }

        function test_theServersRefusalInWordsWithItsCode() {
            openCreate({ returnValue: true, terms: someTerms });
            fillNew();
            tapNew("createAgree");
            tapNew("createAccount");
            madeLuna.reply(madeLuna.callsTo(createUri)[0], { returnValue: false, errorCode: "EMAIL_TAKEN", errorText: "account server error EMAIL_TAKEN" });
            var s = statusOf(made, "createStatus");
            compare(s.text, "There is already an account with this e-mail address. Sign in with it instead.");
            compare(s.code, "EMAIL_TAKEN");
            verify(s.codeShown);
            verify(child("createAccount", made).enabled);
            // "Sign in" goes back to signing in.
            tapNew("createHaveOne");
            compare(pageStack.depth, 1);
            compare(page.signedInAs, "");
            compare(pageStack.nextCount, 0);
        }

        function test_noTermsNoAccountAndTheyCanBeFetchedAgain() {
            openCreate({ returnValue: false, errorCode: "TERMS_ERROR" });
            verify(!child("createAccount", made).enabled);
            var s = statusOf(made, "createStatus");
            compare(s.text, "The terms of service could not be fetched. Check that the device is online, then try again.");
            compare(s.code, "TERMS_ERROR");
            fillNew();
            made.createAccount();
            compare(madeLuna.callsTo(createUri).length, 0);
            compare(child("createReadTerms", made).text, "Fetch the Terms of Service again");
            tapNew("createReadTerms");
            compare(madeLuna.callsTo(termsUri).length, 2);
            compare(pageStack.depth, 2, "a terms page with no terms");
            madeLuna.reply(madeLuna.callsTo(termsUri)[1], { returnValue: true, terms: someTerms });
            verify(!child("createStatus", made).visible, "the old error stayed");
            verify(child("createAgree", made).enabled);

            // Blank terms are no terms either, and nor is no service.
            cleanup();
            init();
            openCreate({ returnValue: true, terms: "  \n " });
            verify(!child("createAgree", made).enabled);
            cleanup();
            init();
            openCreate();
            madeLuna.callsTo(termsUri)[0].onCallFailed("Service does not exist");
            verify(!child("createAccount", made).enabled);
            compare(statusOf(made, "createStatus").code, "NO_SERVICE");
            // and fetched again, that failure goes too.
            tapNew("createReadTerms");
            madeLuna.reply(madeLuna.callsTo(termsUri)[1], { returnValue: true, terms: someTerms });
            verify(!child("createStatus", made).visible, "the old error stayed");
        }
    }
}
