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
import QtTest

import "../qml"

/*
 * The software update step, against test/imports' LunaService, which lets
 * the test answer as org.webosports.service.update and systemservice
 * would; and First Use coming back to it after the update's restart. Run
 * with test/run-tests.sh.
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
        property int nextCount: 0
        function next() { nextCount++; }
        function back() { }
    }

    Component {
        id: pageComponent
        UpdatesPage { }
    }

    TestCase {
        name: "UpdatesPage"
        when: windowShown

        readonly property string checkUri: "luna://org.webosports.service.update/checkUpdate"
        readonly property string downloadUri: "luna://org.webosports.service.update/downloadUpdate"
        readonly property string initiateUri: "luna://org.webosports.service.update/initiateUpdate"
        readonly property string versionUri: "luna://org.webosports.service.update/retrieveVersion"
        readonly property string prefsUri: "luna://com.palm.systemservice/setPreferences"
        readonly property var available: ({ returnValue: true, success: true, needUpdate: true,
            changesSinceLast: [ { version: 26, changes: [ "c" ] }, { version: 25, changes: [ "b" ] } ] })

        property var page: null
        property var luna: null

        function open(props) {
            pageStack.nextCount = 0;
            page = pageStack.push(pageComponent, props || {}, StackView.Immediate);
            verify(page !== null, "the page did not load");
            luna = findChild(page, "updatesService");
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

        function answerCheck(reply) {
            var calls = luna.callsTo(checkUri);
            verify(calls.length > 0, "no check");
            luna.reply(calls[calls.length - 1], reply);
        }

        // Laid out first: the button may just have been shown.
        function click(name) {
            var c = child(name);
            verify(c.visible, name + " is not shown");
            waitForRendering(page);
            mouseClick(c);
        }

        function download() {
            click("updatesInstall");
            compare(luna.subscriptions.length, 1, "no download");
            compare(luna.subscriptions[0].uri, downloadUri);
            compare(luna.subscriptions[0].args.subscribe, true);
            return luna.subscriptions[0];
        }

        function send(sub, payload) {
            sub.onReply({ payload: JSON.stringify(payload) });
        }

        function test_checksAsItOpensAndCanBeSkipped() {
            open();
            compare(luna.callsTo(checkUri).length, 1);
            compare(luna.callsTo(versionUri).length, 1);
            compare(page.updateState, "checking");
            compare(page.forwardButtonText, "Skip");
            verify(page.forwardButtonVisible);
            compare(luna.callsTo(prefsUri).length, 0, "the place was cleared, or set, on a first visit");
        }

        function test_upToDate() {
            open();
            luna.reply(luna.callsTo(versionUri)[0], { returnValue: true, localVersion: "1.0" });
            answerCheck({ returnValue: true, success: true, needUpdate: false });
            compare(page.updateState, "uptodate");
            compare(page.statusText, "This device is up to date.");
            compare(page.forwardButtonText, "Next");
            verify(!child("updatesInstall").visible);
            compare(child("updatesVersion").text, "This device runs LuneOS 1.0.");
            // Nothing to install: setup goes on without this step, and Back steps over it.
            compare(pageStack.nextCount, 1);
            verify(page.passedOver);
        }

        function test_anUpdateFoundBeforeTheStepIsNotAskedForAgain() {
            open({ knownReply: { payload: JSON.stringify(available) } });
            compare(luna.callsTo(checkUri).length, 0, "checked again");
            compare(page.updateState, "available");
            compare(page.newVersion, "26");
            compare(pageStack.nextCount, 0);
            verify(!page.passedOver);
        }

        function test_anUpdateIsOfferedNotForced() {
            open();
            answerCheck(available);
            compare(page.updateState, "available");
            compare(page.newVersion, "26");
            compare(page.forwardButtonText, "Later");
            verify(child("updatesInstall").visible);
            verify(page.statusText.indexOf("version 26") > 0, page.statusText);
            compare(luna.subscriptions.length, 0, "a download started by itself");
        }

        function test_aCheckThatFailsLetsSetupGoOn() {
            open();
            answerCheck({ returnValue: false, success: false, needUpdate: false, message: "No internet connection." });
            compare(page.updateState, "failed");
            compare(page.statusText, "Could not check for updates: No internet connection. You can check later in Settings, System Updates.");
            compare(page.forwardButtonText, "Next");
            // No answer that says there is an update: setup goes on without the step.
            compare(pageStack.nextCount, 1);
            verify(page.passedOver);
            verify(child("updatesCheckAgain").visible);
            click("updatesCheckAgain");
            compare(luna.callsTo(checkUri).length, 2);

            // No update service on the bus at all.
            cleanup();
            open();
            luna.callsTo(checkUri)[0].onCallFailed("Service does not exist");
            compare(page.updateState, "failed");
            verify(page.forwardButtonVisible);
            compare(pageStack.nextCount, 1);
        }

        function test_installNowDownloadsKeepsThePlaceThenRestarts() {
            open();
            answerCheck(available);
            var sub = download();
            compare(page.updateState, "downloading");
            verify(!page.forwardButtonVisible, "setup can go on during the download");
            verify(!page.hasBackButton, "setup can go back during the download");
            send(sub, { percentage: "42.50" });
            compare(page.percentage, 42.5);
            compare(page.statusText, "Downloading the update: 42%");
            send(sub, { success: true, finished: true, error: false, msg: "Done downloading." });
            verify(sub.cancelled, "the subscription was left open");
            compare(page.updateState, "installing");
            // The place first, and only once it is kept, the restart.
            var prefs = luna.callsTo(prefsUri);
            compare(prefs.length, 1);
            compare(prefs[0].args.firstUseResume, "Updates");
            compare(luna.callsTo(initiateUri).length, 0, "restarting before setup kept its place");
            luna.reply(prefs[0], { returnValue: true });
            compare(luna.callsTo(initiateUri).length, 1);
            luna.reply(luna.callsTo(initiateUri)[0], { success: true, error: false });
            compare(page.updateState, "installing");
            verify(!page.forwardButtonVisible);
        }

        function test_noPlaceKeptNoRestart() {
            open();
            answerCheck(available);
            send(download(), { finished: true });
            luna.reply(luna.callsTo(prefsUri)[0], { returnValue: false, errorText: "no" });
            compare(luna.callsTo(initiateUri).length, 0);
            compare(page.updateState, "failed");
            verify(page.forwardButtonVisible);
            verify(child("updatesInstall").visible, "no second try");
        }

        function test_aRestartThatFailsClearsThePlace() {
            open();
            answerCheck(available);
            send(download(), { finished: true });
            luna.reply(luna.callsTo(prefsUri)[0], { returnValue: true });
            luna.reply(luna.callsTo(initiateUri)[0], { success: false, error: true, msg: "script exited with code 1" });
            compare(page.updateState, "failed");
            var prefs = luna.callsTo(prefsUri);
            compare(prefs.length, 2);
            compare(prefs[1].args.firstUseResume, "");
            verify(page.statusText.indexOf("script exited with code 1") > 0, page.statusText);
        }

        function test_aDownloadThatFailsCanBeTriedAgainOrLeft() {
            open();
            answerCheck(available);
            var sub = download();
            send(sub, { success: false, error: true, msg: "The downloaded update is not the one the update server lists (SHA-256 differs); it was removed.", needCheck: false });
            compare(page.updateState, "failed");
            verify(sub.cancelled);
            verify(page.statusText.indexOf("SHA-256 differs") > 0);
            compare(child("updatesInstall").text, "Try again");
            verify(page.forwardButtonVisible);
            compare(luna.callsTo(prefsUri).length, 0);
            click("updatesInstall");
            compare(luna.subscriptions.length, 2);
        }

        function test_aDownloadForWhatIsGoneChecksAgain() {
            open();
            answerCheck(available);
            send(download(), { success: false, error: true, msg: "version not present anymore", needCheck: true });
            compare(page.updateState, "checking");
            compare(luna.callsTo(checkUri).length, 2);
            compare(pageStack.nextCount, 0);
            // and it is gone: nothing left to install.
            answerCheck({ returnValue: true, success: true, needUpdate: false });
            compare(pageStack.nextCount, 1);
        }

        function test_stoppingTheDownload() {
            open();
            answerCheck(available);
            var sub = download();
            click("updatesCancel");
            verify(sub.cancelled);
            compare(page.updateState, "available");
            // What it sends after is not news.
            send(sub, { finished: true });
            compare(page.updateState, "available");
            compare(luna.callsTo(prefsUri).length, 0);
        }

        function test_theFeedsWordsArePlainAndShort() {
            open();
            var longChange = new Array(400).join("x");
            answerCheck({ returnValue: true, success: true, needUpdate: true,
                          changesSinceLast: [ { version: "<b>27</b>", changes: [ "<img src=x>", longChange ] } ] });
            waitForRendering(page);
            var shown = findChild(page, "updatesFlick");
            var texts = [];
            (function walk(item) {
                for (var i = 0; i < item.children.length; i++) {
                    var c = item.children[i];
                    if (c.text !== undefined && String(c.text).indexOf("<img") >= 0)
                        texts.push(c);
                    walk(c);
                }
            })(shown.contentItem);
            compare(texts.length, 1);
            compare(texts[0].textFormat, Text.PlainText);
            verify(texts[0].text.indexOf(longChange) < 0, "a change was shown whole");
        }

        function test_backAfterTheUpdateClearsThePlaceAndSaysSo() {
            open({ resumed: true });
            var prefs = luna.callsTo(prefsUri);
            compare(prefs.length, 1);
            compare(prefs[0].args.firstUseResume, "");
            verify(!page.hasBackButton);
            answerCheck({ returnValue: true, success: true, needUpdate: false });
            compare(page.statusText, "The update is installed. This device is up to date.");
            compare(pageStack.nextCount, 1, "stayed on the step with nothing more to install");
        }

        function test_anUpdateDoesNotGoOnByItself() {
            open();
            answerCheck(available);
            compare(pageStack.nextCount, 0);
            verify(!page.passedOver);
            // nor does a download that failed.
            send(download(), { error: true, msg: "x" });
            compare(pageStack.nextCount, 0);
        }
    }

    // First Use as a whole: where it starts after the update's restart, and
    // when the update step is shown at all.
    TestCase {
        name: "MainFlow"
        when: windowShown

        function makeApp() {
            var component = Qt.createComponent(Qt.resolvedUrl("../qml/main.qml"));
            if (component.status === Component.Error)
                fail(component.errorString());
            var app = component.createObject(null);
            verify(app !== null);
            var luna = findChild(app, "firstUseService");
            verify(luna !== null);
            return { app: app, luna: luna, stack: app.contentItem.children[0] };
        }

        function resumeCall(luna) {
            var calls = luna.callsTo("luna://com.palm.systemservice/getPreferences").filter(function(c) {
                return c.args.keys && c.args.keys[0] === "firstUseResume";
            });
            compare(calls.length, 1, "First Use did not ask where to start");
            return calls[0];
        }

        function test_startsAtTheUpdateStepAfterTheRestart() {
            var a = makeApp();
            luna_reply(a.luna, resumeCall(a.luna), { returnValue: true, firstUseResume: "Updates" });
            tryVerify(function() { return a.stack.currentItem && a.stack.currentItem.title === "Software Update"; }, 5000);
            compare(a.stack.depth, 1, "there is something to go back to");
            compare(a.stack._currentPage, a.app.pageList.indexOf("Updates"));
            verify(a.stack.currentItem.resumed);
            a.app.destroy();
        }

        function test_startsAtTheStartOtherwise() {
            var answers = [ { returnValue: true }, { returnValue: true, firstUseResume: "" },
                            { returnValue: true, firstUseResume: "Finished" }, { returnValue: false } ];
            for (var i = 0; i < answers.length; i++) {
                var a = makeApp();
                luna_reply(a.luna, resumeCall(a.luna), answers[i]);
                wait(50);
                compare(a.stack._currentPage, 0, JSON.stringify(answers[i]));
                compare(a.stack.depth, 1);
                a.app.destroy();
            }
        }

        function luna_reply(luna, call, payload) {
            luna.reply(call, payload);
        }

        // ---- the update step, shown only for an update ----

        readonly property string checkUri: "luna://org.webosports.service.update/checkUpdate"

        // To the feeds step, which starts the check; the stand-in answers nothing by itself.
        function toFeeds() {
            var a = makeApp();
            a.app.pageList = [ "Welcome", "Feeds", "Updates", "LicenseAgreement", "Finished" ];
            a.stack.next();
            tryVerify(function() { return a.stack.currentItem.title === "Preware Feeds"; }, 5000);
            var calls = a.luna.callsTo(checkUri);
            compare(calls.length, 1, "the check did not start on the step before");
            a.check = calls[0];
            return a;
        }

        function settle(a) {
            tryVerify(function() { return !a.stack.busy; }, 5000);
        }

        function test_noUpdateNoStep() {
            var a = toFeeds();
            luna_reply(a.luna, a.check, { returnValue: true, success: true, needUpdate: false });
            a.stack.next();
            settle(a);
            compare(a.stack.currentItem.title, "License Agreement");
            compare(a.stack.depth, 3);
            // Back steps over it, and forward again too.
            a.stack.back();
            settle(a);
            compare(a.stack.currentItem.title, "Preware Feeds");
            a.stack.next();
            settle(a);
            compare(a.stack.currentItem.title, "License Agreement");
            compare(a.luna.callsTo(checkUri).length, 1, "checked twice");
            a.app.destroy();
        }

        function test_noAnswerThatSaysSoNoStep() {
            var a = toFeeds();
            a.check.onCallFailed("Service does not exist");
            a.stack.next();
            settle(a);
            compare(a.stack.currentItem.title, "License Agreement");
            a.app.destroy();
            a = toFeeds();
            luna_reply(a.luna, a.check, { returnValue: false, success: false, message: "No internet connection." });
            a.stack.next();
            settle(a);
            compare(a.stack.currentItem.title, "License Agreement");
            a.app.destroy();
        }

        function test_anUpdateIsTheStep() {
            var a = toFeeds();
            luna_reply(a.luna, a.check, { returnValue: true, success: true, needUpdate: true,
                                          changesSinceLast: [ { version: 26, changes: [ "c" ] } ] });
            a.stack.next();
            settle(a);
            var p = a.stack.currentItem;
            compare(p.title, "Software Update");
            compare(p.updateState, "available");
            compare(findChild(p, "updatesService").callsTo(checkUri).length, 0, "the step checked again");
            a.app.destroy();
        }

        function test_stillCheckingTheStepChecksAndGoesOnIfNothing() {
            var a = toFeeds();
            a.stack.next();
            settle(a);
            var p = a.stack.currentItem;
            compare(p.title, "Software Update");
            compare(p.updateState, "checking");
            var own = findChild(p, "updatesService").callsTo(checkUri);
            compare(own.length, 1);
            findChild(p, "updatesService").reply(own[0], { returnValue: true, success: true, needUpdate: false });
            settle(a);
            compare(a.stack.currentItem.title, "License Agreement");
            // Back steps over the step that went on by itself.
            a.stack.back();
            settle(a);
            compare(a.stack.currentItem.title, "Preware Feeds");
            compare(a.stack.depth, 2);
            a.app.destroy();
        }
    }
}
