// SPDX-License-Identifier: GPL-2.0-or-later
#include "backend.h"
#include "qmlsetup.h"
#ifdef OBSIDIAN_QTMACOS
#include <QtQml/QQmlExtensionPlugin>
Q_IMPORT_QML_PLUGIN(QtMacOSPlugin)
#endif
#include "wadpreview.h"
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <cstring>

static QString enginePath() {
#ifdef Q_OS_WIN
    return QCoreApplication::applicationDirPath() + "/obsidian-engine.exe";
#else
    return QCoreApplication::applicationDirPath() + "/obsidian-engine";
#endif
}
int main(int argc, char **argv) {
    // Keep the established batch CLI usable without a display or loading the QML interface.
    bool batch = false;
    for (int i = 1; i < argc; ++i)
        if (!std::strcmp(argv[i],"--batch") || !std::strcmp(argv[i],"-b") ||
            !std::strcmp(argv[i],"--export-ui") || !std::strcmp(argv[i],"--printref") || !std::strcmp(argv[i],"--printref-json")) batch = true;
    if (batch) {
        QCoreApplication app(argc,argv); QProcess process;
        process.setProcessChannelMode(QProcess::ForwardedChannels);
        process.start(enginePath(), app.arguments().mid(1));
        if (!process.waitForStarted(10000)) { qCritical("Cannot start obsidian-engine"); return 1; }
        process.waitForFinished(-1);
        return process.exitStatus() == QProcess::NormalExit ? process.exitCode() : 1;
    }
    QGuiApplication app(argc,argv);
    app.setOrganizationName("ObsidianExtended"); app.setApplicationName("ObsidianExtended"); app.setApplicationVersion(QStringLiteral(OBSIDIAN_EXTENDED_VERSION));
    QCommandLineParser parser; parser.setApplicationDescription("Obsidian Extended — Qt 6 level maker");
    parser.addHelpOption(); parser.addVersionOption();
    parser.addOption({"engine","Path to the console worker","file"});
    parser.addOption({"data-dir","Directory containing scripts, games and data","directory",QCoreApplication::applicationDirPath()});
    parser.addOption({"state-dir","Directory for Qt settings and autosaved configuration","directory"});
    parser.addOption({"design-preview","Launch the isolated macOS-inspired design sample"});
    parser.addOption({"smoke-output","Generate one map, write a report and exit (uses isolated settings)","directory"});
    parser.process(app);
    std::unique_ptr<QTemporaryDir> smokeState;
    QString state = parser.value("state-dir");
    if (state.isEmpty()) {
        if (parser.isSet("smoke-output")) { smokeState = std::make_unique<QTemporaryDir>(); state = smokeState->path(); }
        else state = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + (parser.isSet("design-preview") ? "/design-preview" : "");
    }
    if (parser.isSet("design-preview") && !QFile::exists(state + "/interface.ini")) {
        QDir().mkpath(state);
        QSettings preferences(state + "/interface.ini", QSettings::IniFormat);
        preferences.setValue("dark", false);
    }
    QQuickStyle::setStyle("Fusion");
    qmlRegisterType<WadPreview>("Obsidian",1,0,"WadView");
    Backend backend(parser.isSet("engine") ? parser.value("engine") : enginePath(),parser.value("data-dir"),state);
    QQmlApplicationEngine qml;
    configureStudioQmlImports(qml);
    qml.rootContext()->setContextProperty("backend",&backend);
    QObject::connect(&qml,&QQmlApplicationEngine::objectCreated,&app,[&app](QObject *object,const QUrl &) { if (!object) app.exit(1); },Qt::QueuedConnection);
    if (parser.isSet("smoke-output")) {
        const auto output = QDir(parser.value("smoke-output")).absolutePath();
        QObject::connect(&backend,&Backend::schemaChanged,&app,[&backend,output,started=false]() mutable {
            if (started) return;
            started = true;
            backend.chooseOutput(QUrl::fromLocalFile(output));
            backend.setGeneral("seed","12345");
            backend.generate();
        });
        QObject::connect(&backend,&Backend::generationFinished,&app,[&app,&backend,output](bool success) {
            QFile report(output+"/qt-smoke.json");
            if (!report.open(QIODevice::WriteOnly)) { app.exit(1); return; }
            report.write(QJsonDocument(QJsonObject{{"success",success},{"qt",qVersion()},
                {"result",backend.resultFolder()},{"preview",backend.previewFile()},
                {"modules",backend.schema().value("modules").toList().size()}}).toJson());
            app.exit(success ? 0 : 1);
        });
        QObject::connect(&backend,&Backend::stateChanged,&app,[&app,&backend] {
            if (!backend.loading() && backend.schema().isEmpty()) app.exit(1);
        });
        QTimer::singleShot(120000,&app,[&app] { app.exit(1); });
    }
    qml.load(QUrl(parser.isSet("design-preview") ? "qrc:/ui/prototype/Preview.qml" : "qrc:/ui/Main.qml"));
    if (qml.rootObjects().isEmpty()) return 1;
    return app.exec();
}
