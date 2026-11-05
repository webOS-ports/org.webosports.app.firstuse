Summary
=======
LuneOS first use application

Description
===========
This application is running as first application when LuneOS is installed onto a new
device and will guide the user through the setup process of the system.

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
- `test/screens/tst_screens.qml`: the whole app walked through every step -
  Welcome, language, country, time zone, Wi-Fi (with the passphrase page and
  the connect problem popup), feeds (with the third-party feed warning),
  licence and the last page - once per screen in `PROFILES`. The default is
  `mindphone q25 tp radon` (480x800, 720x720, 1024x768 and 720x1600, from
  luneos-components' desktop stand-ins); set `PROFILES` to run others, e.g.
  `PROFILES=tp test/run-tests.sh`. Each step checks that its page, title,
  buttons and main content are on screen, have a size and stay clear of the
  buttons, and is saved as `build/test-output/ui/<profile>-<step>.png`.
