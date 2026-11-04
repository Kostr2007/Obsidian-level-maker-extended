// SPDX-License-Identifier: GPL-2.0-or-later
#include "configuration.h"
#include <QRegularExpression>

bool Configuration::safeValue(const QString &value) {
    return !value.contains('\n') && !value.contains('\r') && !value.contains(QChar(0));
}

bool Configuration::parse(const QByteArray &data, QString *error) {
    Configuration next;
    QString current;
    const auto lines = QString::fromUtf8(data).split('\n');
    const QRegularExpression assignment("^(@?[A-Za-z0-9_]+)\\s*=\\s*(.*?)\\s*$");
    for (int i = 0; i < lines.size(); ++i) {
        const auto line = lines[i].trimmed();
        if (line.isEmpty() || line.startsWith("--")) continue;
        const auto match = assignment.match(line);
        if (!match.hasMatch() || !safeValue(match.captured(2))) {
            if (error) *error = QString("Invalid configuration at line %1").arg(i + 1);
            return false;
        }
        const auto key = match.captured(1), value = match.captured(2);
        if (key.startsWith('@')) {
            current = key.mid(1);
            next.enabled[current] = value;
        } else if (lines[i].startsWith(' ') || lines[i].startsWith('\t')) {
            if (current.isEmpty()) {
                if (error) *error = QString("Module option without module at line %1").arg(i + 1);
                return false;
            }
            next.modules[current][key] = value;
        } else {
            current.clear();
            next.general[key] = value;
        }
    }
    *this = next;
    return true;
}

QByteArray Configuration::serialize() const {
    QString output = "-- Obsidian Extended / Qt 6 configuration\n";
    const QStringList first = {"engine", "game", "port", "length", "theme", "seed"};
    for (const auto &key : first)
        if (general.contains(key)) output += key + " = " + general[key] + '\n';
    for (auto i = general.cbegin(); i != general.cend(); ++i)
        if (!first.contains(i.key())) output += i.key() + " = " + i.value() + '\n';
    auto flags = enabled;
    for (auto i = modules.cbegin(); i != modules.cend(); ++i)
        if (!flags.contains(i.key())) flags[i.key()] = "0";
    for (auto i = flags.cbegin(); i != flags.cend(); ++i) {
        output += "\n@" + i.key() + " = " + i.value() + '\n';
        const auto values = modules.value(i.key());
        for (auto v = values.cbegin(); v != values.cend(); ++v)
            output += "  " + v.key() + " = " + v.value() + '\n';
    }
    return output.toUtf8();
}

QString Configuration::value(const QString &module, const QString &key) const {
    return module.isEmpty() || module.startsWith("ui")
        ? general.value(key) : modules.value(module).value(key);
}
void Configuration::set(const QString &module, const QString &key, const QString &value) {
    if (module.isEmpty() || module.startsWith("ui")) general[key] = value;
    else modules[module][key] = value;
}
