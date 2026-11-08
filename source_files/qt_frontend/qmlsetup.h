// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <QQmlEngine>

inline void configureStudioQmlImports(QQmlEngine &engine) {
#ifdef OBSIDIAN_QTMACOS
    // Qt-MacOS uses this resource prefix explicitly. It only became a default
    // engine import path in Qt 6.5, so Qt 6.4 consumers must add it themselves.
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
#else
    Q_UNUSED(engine);
#endif
}
