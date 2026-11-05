#!/bin/sh
# Run the QML tests in test/ on a development machine.
#
# The pages import LuneOS modules, so the tests need a built luneos-components
# checkout (qmake6 && make at its top): its modules for the LuneOS style and
# its test/imports for the stand-ins of what talks to the system. Point
# LUNEOS_COMPONENTS at it; it defaults to one next to this checkout. This
# repository's own test/imports come last, so they win.
#
# Override QMLTESTRUNNER if your Qt lives elsewhere; any arguments are passed
# on to qmltestrunner. On a machine without a display, run with
# QT_QPA_PLATFORM=offscreen.
#
# screens/tst_screens.qml walks the app through every step once per screen in
# PROFILES (default: mindphone, q25, tp, radon - luneos-components' desktop
# stand-ins for the MindPhone, the Q25, the TouchPad and the FLX1s), and saves
# a picture of each step in build/test-output/ui/<profile>-<step>.png. The
# stand-ins read their profile (and with it the grid unit) once, as they load,
# so each screen runs against a copy of LunaNext.Common whose default profile
# is that screen. It talks to luneos-components' LunaService stand-in, which
# answers like the device's services; of this repository's test/imports it
# only takes the firstuse module.
cd "$(dirname "$0")" || exit 1

LUNEOS_COMPONENTS=${LUNEOS_COMPONENTS:-../../luneos-components}
if [ -z "${QMLTESTRUNNER:-}" ]; then
    for candidate in /usr/lib/qt6/bin/qmltestrunner \
            $(ls -d "$HOME"/Qt/6.*/gcc_64/bin/qmltestrunner 2>/dev/null | sort -V | tail -1) \
            "$(command -v qmltestrunner)"; do
        if [ -x "$candidate" ]; then
            QMLTESTRUNNER=$candidate
            break
        fi
    done
fi

if [ ! -x "$QMLTESTRUNNER" ]; then
    echo "qmltestrunner not found; set QMLTESTRUNNER to your Qt's bin/qmltestrunner" >&2
    exit 1
fi
if ! ls "$LUNEOS_COMPONENTS"/modules/QtQuick/Controls/LuneOS/libluneosstyleplugin.so >/dev/null 2>&1; then
    echo "no built luneos-components in $LUNEOS_COMPONENTS; build it or set LUNEOS_COMPONENTS" >&2
    exit 1
fi

export QT_QUICK_CONTROLS_STYLE=QtQuick.Controls.LuneOS
# LicenseAgreementPage reads the licence text from a file.
export QML_XHR_ALLOW_FILE_READ=1

status=0
for t in tst_*.qml; do
    echo "--- $t"
    "$QMLTESTRUNNER" -input "$t" \
        -import "$LUNEOS_COMPONENTS/modules" \
        -import "$LUNEOS_COMPONENTS/test/imports" \
        -import imports "$@" || status=1
done

PROFILES=${PROFILES:-mindphone q25 tp radon}
WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT
mkdir -p ../build/test-output/ui "$WORK/imports"
cp -r imports/firstuse "$WORK/imports/"
for profile in $PROFILES; do
    echo "--- screens/tst_screens.qml ($profile)"
    common=$WORK/profile-$profile/LunaNext/Common
    mkdir -p "$common"
    cp "$LUNEOS_COMPONENTS"/test/imports/LunaNext/Common/* "$common/"
    sed -i "s/^var defaultProfile = .*/var defaultProfile = \"$profile\";/" "$common/SettingsStub.js"
    if ! grep -q "^var defaultProfile = \"$profile\";" "$common/SettingsStub.js"; then
        echo "could not pick the profile $profile" >&2
        status=1
        continue
    fi
    "$QMLTESTRUNNER" -input screens/tst_screens.qml \
        -import "$LUNEOS_COMPONENTS/modules" \
        -import "$LUNEOS_COMPONENTS/test/imports" \
        -import "$WORK/imports" \
        -import "$WORK/profile-$profile" "$@" || status=1
done

exit $status
