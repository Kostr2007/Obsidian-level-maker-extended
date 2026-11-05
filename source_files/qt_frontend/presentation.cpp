// SPDX-License-Identifier: GPL-2.0-or-later
#include "presentation.h"
#include <QFile>
#include <QJsonDocument>
#include <QResource>

static QVariantMap catalog() {
    Q_INIT_RESOURCE(studio);
    Q_INIT_RESOURCE(gameplay);
    QFile file(":/studio/studio-catalog.json");
    if (!file.open(QIODevice::ReadOnly)) qFatal("Studio catalog is missing");
    const auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) qFatal("Invalid Studio catalog");
    return doc.toVariant().toMap();
}
QVariantMap studioPresentation(QVariantMap schema) {
    static const auto data = catalog();
    const auto modules = data.value("modules").toMap();
    const auto options = data.value("options").toMap();
    QVariantList decorated;
    for (const auto &entry : schema.value("modules").toList()) {
        auto module = entry.toMap();
        const auto id = module.value("id").toString();
        const auto meta = modules.value(id).toMap();
        const auto category = meta.value("category", "extensions");
        module["category"] = category;
        module["title"] = meta.value("title", module.value("text"));
        QVariantList controls;
        for (const auto &entry : module.value("options").toList()) {
            auto option = entry.toMap();
            const auto info = options.value(id + "/" + option.value("id").toString()).toMap();
            option["category"] = info.value("category",category);
            option["title"] = info.value("title",option.value("text"));
            option["summary"] = info.value("summary",QString());
            option["comparison"] = info.value("comparison",QString());
            option["related"] = info.value("related",QString());
            option["advanced"] = !info.value("basic",false).toBool();
            controls.append(option);
        }
        module["options"] = controls;
        decorated.append(module);
    }
    schema["modules"] = decorated;
    return schema;
}
