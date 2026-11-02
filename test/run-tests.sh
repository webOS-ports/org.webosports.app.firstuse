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

status=0
for t in tst_*.qml; do
    echo "--- $t"
    "$QMLTESTRUNNER" -input "$t" \
        -import "$LUNEOS_COMPONENTS/modules" \
        -import "$LUNEOS_COMPONENTS/test/imports" \
        -import imports "$@" || status=1
done

exit $status
