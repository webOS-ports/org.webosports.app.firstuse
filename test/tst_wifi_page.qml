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

import QtQuick
import QtQuick.Controls
import QtTest

import "../qml"

/*
 * The Wi-Fi page when a connect does not work, against test/imports' LunaService,
 * which answers like com.palm.wifi. Run with test/run-tests.sh.
 */
Item {
    id: root
    width: 480
    height: 800

    // The page only takes taps while it is the StackView's active page.
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
        WiFiPage { }
    }

    TestCase {
        name: "WiFiPage"
        when: windowShown

        readonly property string connectUri: "luna://com.palm.wifi/connect"
        readonly property string cancelUri: "luna://com.palm.wifi/cancel"

        property var page: null
        property var luna: null

        function init() {
            page = pageStack.push(pageComponent, {}, StackView.Immediate);
            verify(page !== null, "the page did not load");
            luna = findChild(page, "wifiService");
            verify(luna !== null);
        }

        function cleanup() {
            pageStack.clear(StackView.Immediate);
        }

        // A list with one network, whose row is returned.
        function row(networkInfo) {
            luna.networks([ { networkInfo: networkInfo } ]);
            var list = findChild(page, "wifiList");
            verify(list !== null);
            tryVerify(function() { return list.itemAtIndex(0) !== null; }, 2000);
            return list.itemAtIndex(0);
        }

        function savedNetwork(connectState) {
            var info = { ssid: "Home", profileId: 7, availableSecurityTypes: ["psk"], signalBars: 2 };
            if (connectState)
                info.connectState = connectState;
            return info;
        }

        function popup() {
            var p = findChild(page, "connectProblemPopup");
            verify(p !== null);
            return p;
        }

        function popupChild(name) {
            var c = findChild(popup().contentItem, name);
            verify(c !== null, name);
            return c;
        }

        // Tap a saved network and return the connect it sent.
        function tapAndGetConnect() {
            mouseClick(row(savedNetwork()));
            compare(luna.callsTo(connectUri).length, 1, "no connect was sent");
            return luna.callsTo(connectUri)[0];
        }

        function refused(errorCode, errorText) {
            return { returnValue: false, errorCode: errorCode, errorText: errorText };
        }

        // com.palm.wifi holds one connect at a time and refuses the next one.
        function test_alreadyConnectingOffersToStop() {
            var call = tapAndGetConnect();
            compare(call.args.profileId, 7);
            luna.reply(call, refused(101, "Already connecting to a network"));
            tryCompare(popup(), "opened", true, 2000);
            verify(popup().busy);
            compare(popup().ssid, "Home");
            verify(popupChild("connectProblemText").text.indexOf("earlier attempt") >= 0);
            verify(popupChild("connectProblemStop").visible);
            popupChild("connectProblemStop").clicked();
            compare(luna.callsTo(cancelUri).length, 1, "Stop connecting did not cancel");
            tryCompare(popup(), "opened", false, 2000);
        }

        function test_keepWaitingLeavesItAlone() {
            luna.reply(tapAndGetConnect(), refused(101, "Already connecting to a network"));
            tryCompare(popup(), "opened", true, 2000);
            popupChild("connectProblemDismiss").clicked();
            tryCompare(popup(), "opened", false, 2000);
            compare(luna.callsTo(cancelUri).length, 0);
        }

        // A tap on a network that is still connecting sends no second connect.
        function test_tapWhileConnectingOffersToStop() {
            mouseClick(row(savedNetwork("associating")));
            tryCompare(popup(), "opened", true, 2000);
            verify(popup().busy);
            compare(luna.callsTo(connectUri).length, 0, "a second connect was sent");
        }

        function test_tapWhileConfiguringOffersToStop() {
            mouseClick(row(savedNetwork("associated")));
            tryCompare(popup(), "opened", true, 2000);
            compare(luna.callsTo(connectUri).length, 0, "a second connect was sent");
        }

        function test_tapOnAnIdleNetworkConnects() {
            luna.reply(tapAndGetConnect(), { returnValue: true });
            wait(50);
            verify(!popup().opened);
        }

        // Refusals arrive in the reply, not through the second callback. This
        // is what the page missed: all it ever had was a handler for that one.
        function test_failureIsPutIntoWords() {
            luna.reply(tapAndGetConnect(), refused(10, "The supplied password is incorrect"));
            tryCompare(popup(), "opened", true, 2000);
            verify(!popup().busy);
            verify(!popupChild("connectProblemStop").visible);
            verify(popupChild("connectProblemText").text.indexOf("password is incorrect") >= 0);
        }

        function test_unknownErrorStaysReadable() {
            luna.reply(tapAndGetConnect(), refused(1, "Unknown error"));
            tryCompare(popup(), "opened", true, 2000);
            verify(popupChild("connectProblemText").text.indexOf("Could not connect.") === 0);
        }

        function test_callThatCouldNotBeSent() {
            tapAndGetConnect().onCallFailed("Failed to call remote service: no hub");
            tryCompare(popup(), "opened", true, 2000);
            verify(popupChild("connectProblemText").text.indexOf("no hub") >= 0);
        }

        function test_unreadableReplyIsAFailure() {
            luna.reply(tapAndGetConnect(), "[]");
            tryCompare(popup(), "opened", true, 2000);
            verify(!popup().busy);
        }

        function test_alreadyConnectedIsNotReported() {
            luna.reply(tapAndGetConnect(), refused(165, "Already connected via hidden network"));
            wait(100);
            verify(!popup().opened);
        }

        // Cancelling fails the attempt, and that answer must not read as a
        // problem: the user asked for it.
        function test_stoppingIsNotReported() {
            var call = tapAndGetConnect();
            luna.reply(call, refused(101, "Already connecting to a network"));
            tryCompare(popup(), "opened", true, 2000);
            popupChild("connectProblemStop").clicked();
            tryCompare(popup(), "opened", false, 2000);
            luna.reply(luna.callsTo(cancelUri)[0], { returnValue: true });

            // The connect that was running, answered as a failure.
            luna.reply(call, refused(1, "Unknown error"));
            wait(100);
            verify(!popup().opened);

            // Only that one: the next failure is reported again.
            luna.reply(call, refused(10, "The supplied password is incorrect"));
            tryCompare(popup(), "opened", true, 2000);
        }

        function test_cancelThatFailsIsReported() {
            luna.reply(tapAndGetConnect(), refused(101, "Already connecting to a network"));
            tryCompare(popup(), "opened", true, 2000);
            popupChild("connectProblemStop").clicked();
            tryCompare(popup(), "opened", false, 2000);
            luna.reply(luna.callsTo(cancelUri)[0], refused(106, "No service is connecting currently"));
            tryCompare(popup(), "opened", true, 2000);
            verify(popupChild("connectProblemText").text.indexOf("No service is connecting") >= 0);
            // And a later failure is not swallowed as the stop's answer.
            compare(page.stopRequested, false);
        }

        // The passphrase page is destroyed straight after asking to connect,
        // so a wrong passphrase has to come back to this page.
        function test_wrongPassphraseIsReportedAfterThePassphrasePageWent() {
            mouseClick(row({ ssid: "Cafe", availableSecurityTypes: ["psk"], signalBars: 1 }));
            compare(pageStack.depth, 2, "no passphrase page");
            findChild(pageStack.currentItem, "passphrase").text = "hunter22";
            pageStack.currentItem.forwardClicked();
            compare(pageStack.depth, 1, "the passphrase page stayed");
            var call = luna.callsTo(connectUri)[0];
            verify(call !== undefined, "no connect was sent");
            compare(call.args.ssid, "Cafe");
            compare(call.args.security.simpleSecurity.passKey, "hunter22");
            wait(50);   // the page's deferred destruction
            luna.reply(call, refused(10, "The supplied password is incorrect"));
            tryCompare(popup(), "opened", true, 2000);
            compare(popup().ssid, "Cafe");
        }

        function test_openNetworkConnectsBySsid() {
            mouseClick(row({ ssid: "Open", availableSecurityTypes: [], signalBars: 1 }));
            compare(luna.callsTo(connectUri)[0].args.ssid, "Open");
        }
    }
}
