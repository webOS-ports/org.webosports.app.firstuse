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
(org.webosports.service.communityaccount), makes one with
`createNovaAccount`, or is skipped. Making one first fetches the account
server's terms of service (`getTermsAndConditions`, as plain text, shown as
plain text) and cannot be sent until they are on the page; creating the
account is agreeing to them, and signs the device in with it. The name,
address and password go to that service and on to the account server; the
app does not keep the password, and clears it from the field as soon as it
is sent.

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
- `test/tst_account_page.qml`: the account step signing in - what is sent, the
  password cleared, one sign-in at a time, a refusal, a reply that is not
  JSON, no service to sign in with, and the server's words shown as short
  plain text.
- `test/screens/tst_screens.qml`: the whole app walked through every step -
  Welcome, language, country, time zone, Wi-Fi (with the passphrase page and
  the connect problem popup), feeds (with the third-party feed warning),
  licence, the account step and the last page (ending with "Done!" and a
  restore handed off before first use is marked done) - once per screen in `PROFILES`. The default is
  `mindphone q25 tp radon` (480x800, 720x720, 1024x768 and 720x1600, from
  luneos-components' desktop stand-ins); set `PROFILES` to run others, e.g.
  `PROFILES=tp test/run-tests.sh`. Each step checks that its page, title,
  buttons and main content are on screen, have a size and stay clear of the
  buttons, and is saved as `build/test-output/ui/<profile>-<step>.png`.

The plugin's hand-off writer has C++ unit tests of its own, built with
`-DBUILD_TESTING=ON` and run with `ctest`: `test/unit/tst_handoff.cpp`.
