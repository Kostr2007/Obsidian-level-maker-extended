// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <QMap>
#include <QString>

struct Configuration {
    QMap<QString, QString> general;
    QMap<QString, QString> enabled;
    QMap<QString, QMap<QString, QString>> modules;
    bool parse(const QByteArray &data, QString *error);
    QByteArray serialize() const;
    QString value(const QString &module, const QString &key) const;
    void set(const QString &module, const QString &key, const QString &value);
    static bool safeValue(const QString &value);
};
