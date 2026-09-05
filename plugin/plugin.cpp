/*
 * Copyright (C) 2014 Simon Busch <morphis@gravedo.de>
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

#include <QtQml/qqml.h>
#include <QFile>
#include <QIODevice>
#include <QLatin1String>
#include <QObject>
#include <QString>
#include <QtGlobal>

#include <array>

#include "plugin.h"

class FirstUseUtils : public QObject
{
    Q_OBJECT

public:
    static FirstUseUtils* instance()
    {
        static auto *instance = new FirstUseUtils;
        return instance;
    }

    // Not static: QML cannot call static Q_INVOKABLEs on all supported Qt versions.
    Q_INVOKABLE void markFirstUseDone() // NOLINT(readability-convert-member-functions-to-static)
    {
        /*
         * Two sentinel filenames are in use across the system, and both have
         * to be written or the components disagree about whether first use
         * has run:
         *
         *   ran-first-use  LunaSysMgr (SystemService::cbGetBootStatus),
         *                  LunaAppManager, com.palm.service.accounts
         *   ran-firstuse   configurator (ActivityConfigurator::FIRST_USE_FLAG),
         *                  SettingsService, and webos_firstusesentinelfile in
         *                  webos_filesystem_paths.bbclass
         *
         * Writing only the first left configurator permanently in "before
         * first use" mode, in which it installs solely activities marked
         * firstUseSafe. That silently skipped 14 of the 16 definitions under
         * /etc/palm/activities, among them com.palm.telephony's
         * outgoing-sms.json - the db8 watch that drains the outgoing SMS
         * outbox - so sending an SMS never triggered anything.
         */
        static const std::array<const char *, 2> markers = {
            "/var/luna/preferences/ran-first-use",
            "/var/luna/preferences/ran-firstuse",
        };

        for (const char *const path : markers) {
            QFile marker(QString::fromLatin1(path));
            if (marker.open(QIODevice::ReadWrite)) {
                marker.close();
            } else {
                qWarning("firstuse: could not create %s: %s", path,
                         qPrintable(marker.errorString()));
            }
        }
    }
};

namespace {

QObject *firstuseutils_callback(QQmlEngine * /*engine*/, QJSEngine * /*scriptEngine*/)
{
    return FirstUseUtils::instance();
}

} // namespace

void FirstUsePlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("firstuse"));
    qmlRegisterSingletonType<FirstUseUtils>(uri, 1, 0, "FirstUseUtils", firstuseutils_callback);
}

#include "plugin.moc"
