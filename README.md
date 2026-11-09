Summary
=======
LuneOS first use application

Description
===========
This application is running as first application when LuneOS is installed onto a new
device and will guide the user through the setup process of the system.

## Signing in and what comes after

The account step signs in with a Community Account through
`com.palm.accountservices/authenticateAccount`
(org.webosports.service.communityaccount), or is skipped. A link opens a page
of its own (`CreateAccountPage`, pushed onto the stack, not one of the steps)
to make one with `createNovaAccount`. That page fetches the account server's
terms of service (`getTermsAndConditions`, plain text, shown as plain text on
`TermsPage`); the account is made only once "I agree to the Terms of Service"
is ticked, and the server signs the device in with it. Signed in either way,
the account page says so for a moment and setup goes on by itself. The name,
address and password go to that service and on to the account server; the
app does not keep the password, and clears it from the field as soon as it
is sent. A refusal is a sentence for the service's code (`qml/js/Account.js`)
with the code itself under it in small type, scrolled into view; the
service's own error text is for the log and not shown.

## Software update

After Wi-Fi and the feeds, `UpdatesPage` checks for a system update with
org.webosports.service.update (`checkUpdate`, as the Settings app's System
Updates page does), which shows no toast of its own while first use runs. An
update can be installed there ("Install now": `downloadUpdate`, then
`initiateUpdate`, which restarts the device into the update) or left for
later. Before the restart the page sets the systemservice preference
`firstUseResume` to `"Updates"`; main.qml reads it as it starts and opens that
step, with nothing before it, so setup goes on after the update rather than
from the start. The step clears it when it opens again, and when the restart
could not be started; if the preference cannot be set, the restart is not
started.

Restoring a backup and adding accounts cannot happen during first use: the
Accounts app needs a normal session, and a restore ends in a restart. The last
page lets the user pick either or both; on "Done!" the app writes the choice
to `/var/luna/preferences/firstuse-handoff.json` (`{"restore":..,"accounts":..}`,
whole or not at all, before first use is marked done), and LunaAppManager
opens the Backup app on its restore flow and the Accounts app once the device
enters normal operation, then removes the file.

## Contributing

If you want to contribute you can just start with cloning the repository and make your
contributions. We're using a pull-request based development and utilizing github for the
management of those. All developers must provide their contributions as pull-request and
github and at least one of the core developers needs to approve the pull-request before it
can be merged.

Please refer to http://www.webos-ports.org/wiki/Communications for information about how to
contact the developers of this project.

## Tests

`test/run-tests.sh` runs the tests on a development machine, against a built
luneos-components checkout (`LUNEOS_COMPONENTS`, by default one next to this
checkout) and Qt 6's `qmltestrunner`; without a display, run it with
`QT_QPA_PLATFORM=offscreen`:

    QT_QPA_PLATFORM=offscreen test/run-tests.sh

- `test/tst_wifi_page.qml`: the Wi-Fi page when a connect fails, once.
- `test/tst_account_page.qml`: signing in - what is sent, the password
  cleared, one sign-in at a time, a refusal in words with its code, a reply
  that is not JSON, no service, going on by itself once signed in - and
  making an account on its own page: the terms on theirs, nothing sent until
  they are there and agreed to, the password length counted as the server
  counts it, and back to the account step signed in.
- `test/tst_updates_page.qml`: the update step - checking, up to date, an
  update offered and not forced, the download and its failures, stopping it,
  the place kept before the restart and only then the restart - and first
  use starting again at that step after it.
- `test/screens/tst_screens.qml`: the whole app walked through every step -
  Welcome, language, country, time zone, Wi-Fi (with the passphrase page and
  the connect problem popup), feeds (with the third-party feed warning),
  the update step, licence, the account step (with the new account and terms
  pages) and the last page (ending with "Done!" and a
  restore handed off before first use is marked done) - once per screen in `PROFILES`. The default is
  `mindphone q25 tp radon` (480x800, 720x720, 1024x768 and 720x1600, from
  luneos-components' desktop stand-ins); set `PROFILES` to run others, e.g.
  `PROFILES=tp test/run-tests.sh`. Each step checks that its page, title,
  buttons and main content are on screen, have a size and stay clear of the
  buttons, and is saved as `build/test-output/ui/<profile>-<step>.png`.

The plugin's hand-off writer has C++ unit tests of its own, built with
`-DBUILD_TESTING=ON` and run with `ctest`: `test/unit/tst_handoff.cpp`.
