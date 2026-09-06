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
         * The one sentinel filename shared across the system: every reader -
         * LunaAppManager (BootManager), com.palm.service.accounts
         * (createLocalAccount), configurator
         * (ActivityConfigurator::FIRST_USE_FLAG), SettingsService, and
         * webos_firstusesentinelfile in webos_filesystem_paths.bbclass -
         * checks "ran-firstuse". The legacy "ran-first-use" spelling (once
         * read by LunaSysMgr's SystemService::cbGetBootStatus, LunaAppManager
         * and com.palm.service.accounts) is no longer consulted anywhere.
         */
        QFile marker(QStringLiteral("/var/luna/preferences/ran-firstuse"));
        if (marker.open(QIODevice::ReadWrite)) {
            marker.close();
        } else {
            qWarning("firstuse: could not create %s: %s",
                     qPrintable(marker.fileName()),
                     qPrintable(marker.errorString()));
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
