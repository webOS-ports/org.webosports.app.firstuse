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

import LunaNext.Common 0.1
import firstuse 1.0

/*
 * The app as a whole - qml/main.qml - walked through every step the way a
 * user goes, on one screen per run (see test/run-tests.sh), against
 * luneos-components' LunaService stand-in. Each step is checked for the
 * basics that break when a screen is a different size, and saved as a
 * picture in build/test-output/ui/<profile>-<step>.png to look at.
 */
TestCase {
    id: test
    name: "Screens"
    when: windowShown

    readonly property string shotDir: decodeURIComponent(Qt.resolvedUrl("../../build/test-output/ui").toString()
                                                         .replace(/^file:\/\//, ""))
    readonly property string profile: Settings.profileName
    property var app: null
    // What the layout checks found wrong on the step being looked at, and
    // on all of them. They are reported at the end of the walk, so every
    // step still gets its picture to look at.
    property var problems: []
    property var allProblems: []

    function expect(ok, message) {
        if (!ok)
            problems.push(message);
        return ok;
    }

    function shot(name) {
        var done = false;
        var ok = app.contentItem.grabToImage(function(result) {
            result.saveToFile(shotDir + "/" + profile + "-" + name + ".png");
            done = true;
        });
        verify(ok, "could not grab " + name);
        tryVerify(function() { return done; }, 5000, "no picture of " + name);
        for (var i = 0; i < problems.length; i++)
            allProblems.push(name + ": " + problems[i]);
        problems = [];
    }

    // The first visible descendant of item that passes match.
    function find(item, match) {
        if (!item)
            return null;
        var found = null;
        var kids = item.children || [];
        for (var i = 0; i < kids.length; i++) {
            if (match(kids[i]))
                return kids[i];
            found = find(kids[i], match);
            if (found)
                return found;
        }
        // A Popup is not a child item of what declares it.
        var data = item.data || [];
        for (var j = 0; j < data.length; j++) {
            if (data[j] instanceof Popup && data[j].contentItem) {
                if (match(data[j].contentItem))
                    return data[j].contentItem;
                found = find(data[j].contentItem, match);
                if (found)
                    return found;
            }
        }
        return null;
    }

    function button(item, text) {
        var b = find(item, function(c) {
            return c instanceof Button && c.text === text && c.visible;
        });
        verify(b !== null, "no \"" + text + "\" button");
        return b;
    }

    function stack() {
        return app.contentItem.children[0];
    }

    function page() {
        var s = stack();
        tryVerify(function() { return !s.busy; }, 5000, "the page did not settle");
        return s.currentItem;
    }

    // The item's rectangle in window coordinates.
    function rect(item) {
        var p = item.mapToItem(app.contentItem, 0, 0);
        return { x: p.x, y: p.y, w: item.width, h: item.height };
    }

    // On screen, with a size, and inside the window (a pixel of rounding
    // allowed).
    function verifyInside(item, what) {
        if (!expect(item.visible, what + " is not visible"))
            return;
        var r = rect(item);
        expect(r.w > 0 && r.h > 0, what + " has no size: " + r.w + "x" + r.h);
        expect(r.x >= -1 && r.y >= -1 && r.x + r.w <= app.width + 1 && r.y + r.h <= app.height + 1,
               what + " is outside the " + app.width + "x" + app.height + " window: "
               + r.x + "," + r.y + " " + r.w + "x" + r.h);
    }

    // Text that should wrap or fit, never run off its own width.
    function verifyFits(textItem, what) {
        verifyInside(textItem, what);
        expect(textItem.contentWidth <= textItem.width + 1,
               what + " runs wider (" + textItem.contentWidth + ") than its " + textItem.width);
    }

    // Above the page's own buttons, which sit over the content.
    function verifyClearOfButtons(p, item, what) {
        verifyInside(item, what);
        var buttonsTop = rect(button(p, forwardTextOf(p))).y;
        var r = rect(item);
        expect(r.y + r.h <= buttonsTop + 1, what + " reaches " + (r.y + r.h) + ", under the buttons at " + buttonsTop);
    }

    // A list scrolled to its current row starts on a whole row, not on one
    // half hidden under what sits above it.
    function verifyWholeTopRow(list, what) {
        var top = list.itemAt(list.width / 2, list.contentY + 1);
        expect(top !== null && Math.abs(top.y - list.contentY) <= 1,
               what + " starts on a cut row: " + (top ? top.y : "none") + " at the top " + list.contentY);
    }

    // Each [item, what] can be scrolled fully into flick's view.
    function scrollEachIntoView(flick, items) {
        items.forEach(function(w) {
            verify(w[0] !== null, "no " + w[1]);
            var top = w[0].mapToItem(flick.contentItem, 0, 0).y;
            flick.contentY = Math.max(0, Math.min(top + w[0].height - flick.height,
                                                  flick.contentHeight - flick.height));
            var at = w[0].mapToItem(flick, 0, 0).y;
            expect(at >= -1 && at + w[0].height <= flick.height + 1,
                   w[1] + " cannot be scrolled into view: " + at + " in " + flick.height);
        });
        flick.contentY = flick.contentHeight - flick.height > 0 ? flick.contentHeight - flick.height : 0;
    }

    function forwardTextOf(p) {
        return p.forwardButtonText;
    }

    // What every step has: the page filling the window, its title (if it
    // has one) and its forward button on screen.
    function verifyStep(p, forwardText) {
        verify(p !== null, "no page");
        verifyInside(p, "the page");
        expect(p.width === app.width, "the page is " + p.width + " wide in a " + app.width + " window");
        expect(p.height === app.height, "the page is " + p.height + " high in a " + app.height + " window");
        if (!p.noTitle) {
            var t = find(p, function(c) { return c instanceof Label && c.text === p.title; });
            verify(t !== null, "no title");
            verifyFits(t, "the title");
        }
        verifyInside(button(p, forwardText), "the " + forwardText + " button");
        verifyInside(p.content, "the content");
    }

    function next(p, text) {
        var before = stack().depth;
        mouseClick(button(p, text));
        tryVerify(function() { return stack().depth === before + 1; }, 5000, "\"" + text + "\" did not go on");
        return page();
    }

    function initTestCase() {
        var component = Qt.createComponent(Qt.resolvedUrl("../../qml/main.qml"));
        if (component.status === Component.Error)
            fail(component.errorString());
        app = component.createObject(null);
        verify(app !== null, "main.qml made");
        // The stand-in's deviceInfo says qemux86, which has no Wi-Fi step;
        // a phone has one.
        app.pageList = [ "Welcome", "Locale", "Country", "TimeZone", "WiFi", "Feeds", "LicenseAgreement", "Account", "Finished" ];
        tryVerify(function() { return app.visible && app.contentItem.width === app.width; }, 5000);
        compare(app.width, Settings.displayWidth);
        compare(app.height, Settings.displayHeight);
    }

    function cleanupTestCase() {
        if (app)
            app.destroy();
    }

    function test_steps() {
        var p = page();
        verifyStep(p, "Continue");
        var welcome = find(p, function(c) { return c instanceof Label && c.text.indexOf("Welcome") === 0; });
        verify(welcome !== null);
        verifyFits(welcome, "the welcome text");
        verifyClearOfButtons(p, welcome, "the welcome text");
        shot("01-welcome");

        p = next(p, "Continue");
        compare(p.title, "Select your Language");
        verifyStep(p, "Next");
        var list = find(p, function(c) { return c instanceof ListView; });
        verify(list !== null, "no language list");
        tryVerify(function() { return list.count > 0; }, 5000, "no languages");
        verifyClearOfButtons(p, list, "the language list");
        verifyWholeTopRow(list, "the language list");
        shot("02-language");

        p = next(p, "Next");
        compare(p.title, "Select your Country");
        verifyStep(p, "Next");
        list = find(p, function(c) { return c instanceof ListView; });
        verify(list !== null, "no country list");
        tryVerify(function() { return list.count > 0; }, 5000, "no countries");
        verifyClearOfButtons(p, list, "the country list");
        verifyWholeTopRow(list, "the country list");
        shot("03-country");

        p = next(p, "Next");
        compare(p.title, "Select your Timezone");
        verifyStep(p, "Next");
        list = find(p, function(c) { return c instanceof ListView && c.visible; });
        verify(list !== null, "no time zone list");
        tryVerify(function() { return list.count > 0; }, 5000, "no time zones");
        verifyClearOfButtons(p, list, "the time zone list");
        // Room for the chosen time zone whole and some of the next, so the
        // list shows there is more to choose from.
        tryVerify(function() { return list.currentItem !== null; }, 5000, "no current time zone");
        expect(list.height >= list.currentItem.height + Units.gu(4),
               "the time zone list (" + list.height + ") has no room for more than one of its rows ("
               + list.currentItem.height + ")");
        var formatSwitch = find(p, function(c) { return c instanceof Switch && c.visible; });
        verify(formatSwitch !== null, "no time format switch");
        verifyInside(formatSwitch, "the time format switch");
        shot("04-timezone");

        p = next(p, "Next");
        compare(p.title, "Connect WiFi network");
        list = findChild(p, "wifiList");
        verify(list !== null, "no network list");
        tryVerify(function() { return list.count > 0; }, 5000, "no networks");
        // The stand-in is connected to one of them, so the step says Next.
        tryCompare(p, "forwardButtonText", "Next");
        verifyStep(p, "Next");
        verifyClearOfButtons(p, list, "the network list");
        verifyInside(list.itemAtIndex(0), "the first network");
        shot("05-wifi");

        // A network with a passphrase asks for it on a page of its own.
        var wifi = p;
        var secured = -1;
        for (var i = 0; i < list.count; i++) {
            // The stand-in names its networks after their security.
            if (/Security: wep$/.test(list.model.get(i).networkInfo.ssid))
                secured = i;
        }
        verify(secured >= 0, "no network with a passphrase");
        list.positionViewAtIndex(secured, ListView.Contain);
        var row = list.itemAtIndex(secured);
        verify(row !== null);
        var depth = stack().depth;
        mouseClick(row);
        tryVerify(function() { return stack().depth === depth + 1; }, 5000, "no passphrase page");
        p = page();
        verify(p.title.indexOf("Connect to ") === 0, p.title);
        verifyStep(p, "Connect");
        var passphrase = findChild(p, "passphrase");
        verify(passphrase !== null);
        verifyInside(passphrase, "the passphrase field");
        shot("06-wifi-passphrase");
        mouseClick(button(p, "Back"));
        tryVerify(function() { return stack().depth === depth; }, 5000, "Back did not go back");
        compare(page(), wifi);

        // com.palm.wifi refusing a second connect while one runs (the
        // stand-in does not refuse, so the popup is opened as the page does).
        var problem = findChild(wifi, "connectProblemPopup");
        verify(problem !== null);
        problem.showBusy("Test WiFi 3 Bars Security: wep");
        tryCompare(problem, "opened", true, 5000);
        verifyInside(problem.contentItem, "the connect problem popup");
        verifyFits(findChild(problem.contentItem, "connectProblemText"), "the connect problem text");
        verifyInside(findChild(problem.contentItem, "connectProblemStop"), "Stop connecting");
        verifyInside(findChild(problem.contentItem, "connectProblemDismiss"), "Keep waiting");
        shot("07-wifi-problem");
        findChild(problem.contentItem, "connectProblemDismiss").clicked();
        tryCompare(problem, "opened", false, 5000);

        p = next(wifi, "Next");
        compare(p.title, "Preware Feeds");
        verifyStep(p, "Continue");
        list = find(p, function(c) { return c instanceof ListView; });
        verify(list !== null, "no feed list");
        tryVerify(function() { return list.count > 0; }, 5000, "no feeds");
        verifyClearOfButtons(p, list, "the feed list");
        shot("08-feeds");

        // Turning on a feed that is not webos-ports' warns first.
        var other = -1;
        for (i = 0; i < list.count; i++) {
            if (list.model.get(i).configConfig !== "webos-ports.conf") {
                other = i;
                break;
            }
        }
        verify(other >= 0, "no feed but webos-ports'");
        list.positionViewAtIndex(other, ListView.Contain);
        var toggle = find(list.itemAtIndex(other), function(c) { return c instanceof Switch; });
        verify(toggle !== null);
        verifyInside(toggle, "the feed's switch");
        mouseClick(toggle);
        var ok = null;
        tryVerify(function() {
            ok = find(p, function(c) { return c instanceof Button && c.text === "OK" && c.visible; });
            return ok !== null && ok.width > 0;
        }, 5000, "no warning");
        var warning = ok.parent.parent;
        var warningPopup = null;
        for (i = 0; i < p.data.length; i++) {
            if (p.data[i] instanceof Popup)
                warningPopup = p.data[i];
        }
        verify(warningPopup !== null, "the warning is no popup");
        // Measured once it has come in, not on its way.
        tryCompare(warningPopup, "opened", true, 5000);
        // and has taken the width of what it holds.
        tryVerify(function() { return warningPopup.width >= warning.width; }, 5000, "the warning stays " + warningPopup.width
                  + " wide around its " + warning.width);
        verifyInside(warning, "the warning");
        verifyInside(ok, "the warning's OK");
        verifyInside(button(warning, "Cancel"), "the warning's Cancel");
        shot("09-feeds-warning");
        mouseClick(button(warning, "Cancel"));
        tryVerify(function() { return !ok.visible || ok.width === 0 || !warning.visible; }, 5000, "the warning stayed");

        p = next(p, "Continue");
        compare(p.title, "License Agreement");
        verifyStep(p, "Accept");
        var licence = find(p, function(c) { return c instanceof Flickable && !(c instanceof ListView); });
        verify(licence !== null, "no licence text");
        verifyClearOfButtons(p, licence, "the licence text");
        shot("10-licence");

        p = next(p, "Accept");
        compare(p.title, "Your Community Account");
        // Signing in is not needed to go on.
        verifyStep(p, "Skip");
        var accountFlick = findChild(p, "accountFlick");
        verify(accountFlick !== null, "no scrolling for the account page");
        verifyClearOfButtons(p, accountFlick, "the account page's content");
        var accountParts = [[findChild(p, "accountEmail"), "the e-mail field"],
                            [findChild(p, "accountPassword"), "the password field"],
                            [findChild(p, "accountSignIn"), "Sign in"],
                            [findChild(p, "accountPrivacy"), "the privacy note"]];
        shot("11-account");
        scrollEachIntoView(accountFlick, accountParts);
        shot("11-account-end");
        compare(findChild(p, "accountPassword").echoMode, TextInput.Password);

        // Making an account: terms as long as the server's, then every field
        // and button reachable.
        p.startCreating();
        var para = "We store only what is needed to run the service: your account details and a per-device sign-in token, and any app data you choose to sync.";
        p.termsReply({ payload: JSON.stringify({ returnValue: true,
            terms: "Terms of Service\n\n" + [1, 2, 3, 4, 5, 6].map(function(n) { return n + ". Section\n\n" + para; }).join("\n\n") }) });
        accountFlick.contentY = 0;
        waitForRendering(accountFlick);
        shot("11-account-create");
        scrollEachIntoView(accountFlick, [[findChild(p, "accountFirstName"), "the first name field"],
                                          [findChild(p, "accountLastName"), "the last name field"],
                                          [findChild(p, "accountEmail"), "the e-mail field"],
                                          [findChild(p, "accountPassword"), "the password field"],
                                          [findChild(p, "accountCreate"), "Create account"],
                                          [findChild(p, "accountHaveOne"), "I have an account"],
                                          [findChild(p, "accountPrivacy"), "the privacy note"]]);
        shot("11-account-create-end");
        // The terms may be longer than the screen: they scroll, all of them.
        var termsText = findChild(p, "accountTerms");
        var termsTop = termsText.mapToItem(accountFlick.contentItem, 0, 0).y;
        verify(termsText.height > 0 && termsTop >= 0 && termsTop + termsText.height <= accountFlick.contentHeight,
               "the terms are not all in the scrolled content");
        p.stopCreating();
        accountFlick.contentY = 0;

        p = next(p, "Skip");
        compare(p.title, "Everything setup!");
        verifyStep(p, "Done!");
        // A short screen scrolls the page's words: each is checked once
        // scrolled into view, as a user would get to it.
        var finishedFlick = findChild(p, "finishedFlick");
        verify(finishedFlick !== null, "no scrolling for the finished page");
        verifyClearOfButtons(p, finishedFlick, "the finished page's words");
        var restore = findChild(p, "restoreAfterSetup");
        var accounts = findChild(p, "accountsAfterSetup");
        verify(restore !== null && accounts !== null);
        // Nothing is opened afterwards unless asked for.
        verify(!restore.checked && !accounts.checked);
        [[restore, "the restore choice"], [accounts, "the accounts choice"]].forEach(function(w) {
            // Read whole, and light on the dark page. (On screen once
            // scrolled to, below.)
            expect(w[0].contentItem.width > 0 && w[0].contentItem.height > 0, w[1] + " has no size");
            expect(!w[0].contentItem.truncated, w[1] + " is cut off");
            expect(w[0].contentItem.lineCount === 1 || w[0].contentItem.wrapMode !== Text.NoWrap,
                   w[1] + " does not wrap");
            expect(Qt.colorEqual(w[0].contentItem.color, "white"), w[1] + " is " + w[0].contentItem.color);
        });
        var later = find(p, function(c) { return c instanceof Text && c.text.indexOf("Or you can now") === 0; });
        verify(later !== null);
        shot("12-finished");
        scrollEachIntoView(finishedFlick, [[restore, "the restore choice"],
                                           [accounts, "the accounts choice"],
                                           [later, "the closing words"]]);
        shot("12-finished-end");

        // Asking for a restore, and nothing else, hands that to
        // LunaAppManager before first use is marked done. Done! ends the
        // app, so this is the walk's last step.
        finishedFlick.contentY = Math.max(0, Math.min(restore.mapToItem(finishedFlick.contentItem, 0, 0).y,
                                                      finishedFlick.contentHeight - finishedFlick.height));
        mouseClick(restore);
        verify(restore.checked, "the restore choice did not take a tap");
        var handOffs = FirstUseUtils.handOffs.length;
        mouseClick(button(p, "Done!"));
        tryVerify(function() { return FirstUseUtils.handOffs.length === handOffs + 1; }, 5000, "nothing handed off");
        var handed = FirstUseUtils.handOffs[handOffs];
        compare(handed.restore, true);
        compare(handed.accounts, false);
        verify(handed.beforeDone, "handed off after first use was marked done");

        verify(allProblems.length === 0, allProblems.join("\n"));
    }
}
