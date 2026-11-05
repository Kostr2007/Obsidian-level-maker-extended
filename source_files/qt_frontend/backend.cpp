// SPDX-License-Identifier: GPL-2.0-or-later
#include "backend.h"
#include "presentation.h"
#include "wadpreview.h"
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>
#include <cmath>

Backend::Backend(QString engine, QString dataDir, QString stateDir, QObject *parent)
    : QObject(parent), m_engine(std::move(engine)), m_dataDir(std::move(dataDir)), m_stateDir(std::move(stateDir)) {
    QDir().mkpath(m_stateDir);
    m_preferences = std::make_unique<QSettings>(m_stateDir + "/interface.ini", QSettings::IniFormat);
    m_output = m_preferences->value("output", QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/Obsidian").toString();
    m_addons = m_preferences->value("addons").toStringList();
    QFile saved(m_stateDir + "/CONFIG.txt"); QString error;
    if (saved.open(QIODevice::ReadOnly)) {
        if (!m_config.parse(saved.readAll(), &error)) appendLog(error);
    }
    if (m_config.general.isEmpty()) {
        m_config.general = {{"engine","idtech_1"},{"game","doom2"},{"port","boom"},{"length","single"},{"theme","original"}};
        m_config.enabled["compress_output"] = "0";
    }
    m_saveTimer.setSingleShot(true); m_saveTimer.setInterval(250);
    connect(&m_saveTimer, &QTimer::timeout, this, [this] { writeConfig(m_stateDir + "/CONFIG.txt"); });
    m_reloadTimer.setSingleShot(true); m_reloadTimer.setInterval(120);
    connect(&m_reloadTimer, &QTimer::timeout, this, &Backend::requestSchema);
    m_schemaTimeout.setSingleShot(true); m_schemaTimeout.setInterval(30000);
    connect(&m_schemaTimeout, &QTimer::timeout, this, [this] {
        appendLog("Истекло время получения схемы настроек."); m_schemaProcess.kill();
    });
    connect(&m_schemaProcess, qOverload<int,QProcess::ExitStatus>(&QProcess::finished), this, &Backend::schemaFinished);
    connect(&m_schemaProcess, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) { m_schemaTimeout.stop(); m_loading = false; fail("Не удалось запустить генератор: " + m_schemaProcess.errorString()); }
    });
    m_worker.setProcessChannelMode(QProcess::MergedChannels);
    connect(&m_worker, &QProcess::readyReadStandardOutput, this, &Backend::consumeOutput);
    connect(&m_worker, qOverload<int,QProcess::ExitStatus>(&QProcess::finished), this, &Backend::generationDone);
    connect(&m_worker, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            m_busy = false; m_job.reset(); fail("Не удалось запустить генератор: " + m_worker.errorString());
            emit generationFinished(false);
        }
    });
    QTimer::singleShot(0, this, &Backend::reload);
}
Backend::~Backend() {
    if (m_saveTimer.isActive()) { m_saveTimer.stop(); writeConfig(m_stateDir + "/CONFIG.txt"); }
    for (auto *process : {&m_schemaProcess, &m_worker})
        if (process->state() != QProcess::NotRunning) { process->kill(); process->waitForFinished(2000); }
}
bool Backend::dark() const { return m_preferences->value("dark",true).toBool(); }
QString Backend::accent() const { return m_preferences->value("accent","#72a7ff").toString(); }
void Backend::setDark(bool value) { m_preferences->setValue("dark",value); emit preferencesChanged(); }
void Backend::setAccent(const QString &value) {
    if (!QColor(value).isValid()) return;
    m_preferences->setValue("accent",value); emit preferencesChanged();
}
QString Backend::value(const QString &module, const QString &key) const { return m_config.value(module,key); }
void Backend::appendLog(const QString &text) { m_log = (m_log + text + '\n').right(200000); emit logChanged(); }
void Backend::fail(const QString &error) { m_status = error; appendLog(error); emit stateChanged(); }
bool Backend::writeConfig(const QString &path) {
    QSaveFile file(path);
    const auto data = m_config.serialize();
    if (!file.open(QIODevice::WriteOnly) || file.write(data) != data.size() || !file.commit()) {
        fail("Не удалось сохранить конфигурацию: " + file.errorString()); return false;
    }
    return true;
}
void Backend::saveState() {
    ++m_revision; emit valuesChanged(); m_saveTimer.start();
}
QStringList Backend::arguments(const QString &directory) const {
    QStringList args = {"--keep","--data-dir",m_dataDir,"--config",directory+"/CONFIG.txt","--options",directory+"/OPTIONS.txt","--log",directory+"/LOGS.txt"};
    if (!m_addons.isEmpty()) { args << "--addon"; args << m_addons; }
    return args;
}
void Backend::reload() {
    if (m_busy) return;
    m_loading = true; emit stateChanged(); m_reloadTimer.start();
}
void Backend::requestSchema() {
    if (m_schemaProcess.state() != QProcess::NotRunning) { m_pendingReload = true; return; }
    m_pendingReload = false;
    m_schemaDir = std::make_unique<QTemporaryDir>();
    if (!m_schemaDir->isValid() || !writeConfig(m_schemaDir->path()+"/CONFIG.txt")) {
        m_loading = false; fail("Не удалось создать временные файлы настроек."); return;
    }
    m_schemaProcess.setWorkingDirectory(m_dataDir);
    m_schemaProcess.start(m_engine, arguments(m_schemaDir->path()) << "--export-ui" << m_schemaDir->path()+"/schema.json");
    m_schemaTimeout.start();
}
void Backend::schemaFinished(int code, QProcess::ExitStatus status) {
    m_schemaTimeout.stop();
    if (m_pendingReload) { requestSchema(); return; }
    m_loading = false;
    QFile file(m_schemaDir->path()+"/schema.json"); QJsonParseError error;
    const auto doc = file.open(QIODevice::ReadOnly) ? QJsonDocument::fromJson(file.readAll(), &error) : QJsonDocument();
    if (code || status != QProcess::NormalExit || !doc.isObject() || doc.object()["protocol"].toInt() != 1) {
        appendLog(QString::fromUtf8(m_schemaProcess.readAllStandardError()));
        QFile logs(m_schemaDir->path()+"/LOGS.txt"); if (logs.open(QIODevice::ReadOnly)) appendLog(QString::fromUtf8(logs.readAll()).right(20000));
        fail("Не удалось получить настройки генератора. Подробности в журнале."); return;
    }
    m_schema = studioPresentation(doc.object().toVariantMap());
    const auto general = doc.object()["config"].toObject();
    for (auto i = general.begin(); i != general.end(); ++i) m_config.general[i.key()] = i.value().toString();
    for (const auto &entry : doc.object()["modules"].toArray()) {
        const auto module = entry.toObject(); const auto id = module["id"].toString();
        if (!module["isUi"].toBool()) m_config.enabled[id] = module["enabled"].toBool() ? "1" : "0";
        for (const auto &option : module["options"].toArray()) {
            const auto o = option.toObject();
            if (o["kind"].toString() != "header") m_config.set(id,o["id"].toString(),o["value"].toString());
        }
    }
    saveState(); m_status = "Готов к созданию карты"; emit schemaChanged(); emit stateChanged();
}
void Backend::setGeneral(const QString &key, const QString &value) {
    if (m_busy || m_loading || !Configuration::safeValue(value)) return;
    if (key != "seed") {
        bool valid = false;
        for (const auto &choice : m_schema.value("choices").toMap().value(key).toList())
            if (choice.toMap().value("id").toString() == value) valid = true;
        if (!valid) return;
    }
    m_config.general[key] = value; saveState();
    if (key == "engine" || key == "game" || key == "port") reload();
}
void Backend::setOption(const QString &module, const QString &key, const QString &value) {
    if (m_busy || m_loading || !Configuration::safeValue(value)) return;
    bool valid = false;
    for (const auto &entry : m_schema.value("modules").toList()) {
        const auto m = entry.toMap();
        if (m.value("id").toString() != module || !m.value("available").toBool()) continue;
        for (const auto &option : m.value("options").toList()) {
            const auto o = option.toMap(); if (o.value("id").toString() != key) continue;
            if (o.value("kind") == "boolean") valid = value == "0" || value == "1";
            else if (o.value("kind") == "choice") {
                for (const auto &c : o.value("choices").toList()) if (c.toMap().value("id").toString() == value) valid = true;
            } else if (o.value("kind") == "slider") {
                bool ok; const double n = value.toDouble(&ok);
                valid = (ok && std::isfinite(n) && n >= o.value("min").toDouble() && n <= o.value("max").toDouble()) || o.value("nan").toStringList().contains(value);
            }
        }
    }
    if (!valid) { fail("Недопустимое значение параметра " + key); ++m_revision; emit valuesChanged(); return; }
    m_config.set(module,key,value); saveState();
}
void Backend::setModuleEnabled(const QString &module, bool enabled) {
    if (m_busy || m_loading) return;
    for (const auto &entry : m_schema.value("modules").toList()) {
        const auto m = entry.toMap();
        if (m.value("id").toString() == module && m.value("available").toBool() && !m.value("isUi").toBool()) {
            m_config.enabled[module] = enabled ? "1" : "0"; saveState(); reload(); return;
        }
    }
}
void Backend::importConfig(const QUrl &url) {
    if (m_busy || m_loading || !url.isLocalFile()) return;
    QFile file(url.toLocalFile()); QString error; Configuration next;
    if (!file.open(QIODevice::ReadOnly)) { fail(file.errorString()); return; }
    if (file.size() > 4*1024*1024 || !next.parse(file.readAll(), &error)) { fail(error.isEmpty() ? "Слишком большая конфигурация" : error); return; }
    m_config = next; saveState(); reload();
}
void Backend::exportConfig(const QUrl &url) { if (!m_busy && !m_loading && url.isLocalFile()) writeConfig(url.toLocalFile()); }
void Backend::addAddon(const QUrl &url) {
    if (m_busy || m_loading || !url.isLocalFile()) return;
    const auto path = url.toLocalFile();
    if (QFileInfo(path).isFile() && !m_addons.contains(path)) {
        m_addons << path; m_preferences->setValue("addons",m_addons); emit preferencesChanged(); reload();
    }
}
void Backend::clearAddons() { if (!m_busy && !m_loading) { m_addons.clear(); m_preferences->setValue("addons",m_addons); emit preferencesChanged(); reload(); } }
void Backend::chooseOutput(const QUrl &url) {
    if (!m_busy && url.isLocalFile()) { m_output = url.toLocalFile(); m_preferences->setValue("output",m_output); emit preferencesChanged(); }
}
void Backend::generate() {
    if (m_busy || m_loading || m_schema.isEmpty()) return;
    if (!QDir().mkpath(m_output)) { fail("Не удалось создать папку результата."); return; }
    m_job = std::make_unique<QTemporaryDir>(m_output + "/.obsidian-building-XXXXXX");
    if (!m_job->isValid()) { m_job.reset(); fail("Папка результата недоступна для записи."); return; }
    if (m_config.general.value("seed").isEmpty() || m_config.general.value("seed") == "0")
        m_config.general["seed"] = QString::number(QRandomGenerator::global()->generate64());
    saveState();
    if (!writeConfig(m_job->path()+"/CONFIG.txt")) { m_job.reset(); return; }
    m_busy = true; m_cancelled = false; m_progress = 0; m_log.clear(); m_pendingOutput.clear();
    m_status = "Начинаем генерацию…"; emit logChanged(); emit stateChanged();
    m_worker.setWorkingDirectory(m_dataDir);
    const auto format = m_schema.value("format").toString();
    const auto extension = format.startsWith("quake") ? "pak" : format == "nukem" ? "grp" : "wad";
    m_worker.start(m_engine, arguments(m_job->path()) << "--batch" << m_job->path()+"/level."+extension << "--qt-events" << "--verbose");
}
void Backend::consumeOutput() {
    m_pendingOutput += m_worker.readAllStandardOutput();
    QStringList lines;
    bool progressChanged = false;
    int end;
    while ((end = m_pendingOutput.indexOf('\n')) >= 0) {
        const auto line = QString::fromUtf8(m_pendingOutput.left(end)).trimmed();
        m_pendingOutput.remove(0,end+1);
        if (line.startsWith("@@OBSIDIAN level ")) {
            const auto fields = line.split(' '); bool ok1,ok2;
            const int index = fields.value(2).toInt(&ok1), total = fields.value(3).toInt(&ok2);
            if (ok1 && ok2 && total > 0) { m_progress = double(index-1)/total; m_status = QString("Создаём карту %1 из %2").arg(index).arg(total); progressChanged = true; }
        } else if (line.startsWith("@@OBSIDIAN step ")) {
            m_status = "Генерация: " + line.mid(16); progressChanged = true;
        } else if (!line.isEmpty()) lines << line;
    }
    if (!lines.isEmpty()) appendLog(lines.join('\n'));
    if (progressChanged) emit stateChanged();
    if (m_pendingOutput.size() > 1024*1024) { appendLog(QString::fromUtf8(m_pendingOutput)); m_pendingOutput.clear(); }
}
void Backend::cancel() {
    if (!m_busy) return;
    m_cancelled = true; m_status = "Отменяем генерацию…"; emit stateChanged();
    m_worker.terminate();
    QTimer::singleShot(2000, &m_worker, [this] { if (m_busy && m_cancelled) m_worker.kill(); });
}
void Backend::generationDone(int code, QProcess::ExitStatus exitStatus) {
    consumeOutput();
    if (!m_pendingOutput.isEmpty()) { appendLog(QString::fromUtf8(m_pendingOutput)); m_pendingOutput.clear(); }
    bool success = !m_cancelled && code == 0 && exitStatus == QProcess::NormalExit;
    QString error;
    QString preview;
    QStringList outputs;
    if (success) {
        QDirIterator files(m_job->path(),QDir::Files,QDirIterator::Subdirectories);
        while (files.hasNext()) {
            auto name = files.next(); const auto ext = QFileInfo(name).suffix().toLower();
            if (ext == "wad" || ext == "pk3" || ext == "pak" || ext == "map" || ext == "grp" || (QFileInfo(name).baseName().compare("GAMEMAPS",Qt::CaseInsensitive) == 0 || QFileInfo(name).baseName().compare("MAPTEMP",Qt::CaseInsensitive) == 0)) {
                outputs << name;
                if (ext == "wad") {
                    const auto geometry = MapGeometry::read(name);
                    if (geometry.lines.isEmpty()) { success = false; error = "WAD создан, но геометрия не прошла проверку: " + geometry.error; }
                    else preview = QDir(m_job->path()).relativeFilePath(name);
                }
            }
        }
        if (outputs.isEmpty()) { success = false; error = "Генератор завершился без выходного файла."; }
    }
    if (success) {
        const auto destination = m_output + "/Obsidian-" + QDateTime::currentDateTime().toString("yyyyMMdd-hhmmss") + "-" + QUuid::createUuid().toString(QUuid::Id128).left(6);
        const auto source = m_job->path();
        if (!QDir().rename(source,destination)) { success = false; error = "Не удалось сохранить папку результата."; }
        else {
            m_job->setAutoRemove(false); m_result = destination;
            m_preview = preview.isEmpty() ? QString() : destination + '/' + preview;
            m_progress = 1; m_status = "Карта готова. Можно открыть папку результата."; emit resultChanged();
        }
    }
    if (!success) {
        m_status = m_cancelled ? "Генерация отменена. Предыдущие результаты сохранены." : (error.isEmpty() ? "Ошибка генерации. Откройте журнал." : error);
        if (m_job) {
            QFile log(m_job->path()+"/LOGS.txt");
            if (log.open(QIODevice::ReadOnly)) appendLog(QString::fromUtf8(log.readAll()).right(30000));
        }
        appendLog(m_status);
    }
    m_job.reset(); m_busy = false; emit stateChanged(); emit generationFinished(success);
}
void Backend::openResult() { if (!m_result.isEmpty()) QDesktopServices::openUrl(QUrl::fromLocalFile(m_result)); }
