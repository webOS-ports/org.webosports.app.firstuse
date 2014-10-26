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
#include <QQmlContext>
#include <QFile>
#include "plugin.h"

class FirstUseUtils : public QObject
{
    Q_OBJECT

public:
    static FirstUseUtils* instance()
    {
        static FirstUseUtils* instance = new FirstUseUtils;
        return instance;
    }

    Q_INVOKABLE void markFirstUseDone()
    {
        QFile firstUseMarker("/var/luna/preferences/ran-first-use");
        firstUseMarker.open(QIODevice::ReadWrite);
        firstUseMarker.close();
    }
};

static QObject *firstuseutils_callback(QQmlEngine*, QJSEngine*)
{
    return FirstUseUtils::instance();
}

void FirstUsePlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("firstuse"));
    qmlRegisterSingletonType<FirstUseUtils>(uri, 1, 0, "FirstUseUtils", firstuseutils_callback);
}

#include "plugin.moc"
