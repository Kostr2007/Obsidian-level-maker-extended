// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include "configuration.h"
#include <QObject>
#include <QProcess>
#include <QSettings>
#include <QTemporaryDir>
#include <QTimer>
#include <QUrl>
#include <QVariantMap>
#include <memory>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap schema READ schema NOTIFY schemaChanged)
    Q_PROPERTY(int revision READ revision NOTIFY valuesChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY stateChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(double progress READ progress NOTIFY stateChanged)
    Q_PROPERTY(QString log READ log NOTIFY logChanged)
    Q_PROPERTY(QString previewFile READ previewFile NOTIFY resultChanged)
    Q_PROPERTY(QString resultFolder READ resultFolder NOTIFY resultChanged)
    Q_PROPERTY(QString outputFolder READ outputFolder NOTIFY preferencesChanged)
    Q_PROPERTY(bool dark READ dark WRITE setDark NOTIFY preferencesChanged)
    Q_PROPERTY(QString accent READ accent WRITE setAccent NOTIFY preferencesChanged)
public:
    Backend(QString engine, QString dataDir, QString stateDir, QObject *parent = nullptr);
    ~Backend() override;
    QVariantMap schema() const { return m_schema; }
    int revision() const { return m_revision; }
    bool loading() const { return m_loading; }
    bool busy() const { return m_busy; }
    QString status() const { return m_status; }
    double progress() const { return m_progress; }
    QString log() const { return m_log; }
    QString previewFile() const { return m_preview; }
    QString resultFolder() const { return m_result; }
    QString outputFolder() const { return m_output; }
    bool dark() const;
    QString accent() const;
    void setDark(bool dark);
    void setAccent(const QString &accent);
    Q_INVOKABLE QString value(const QString &module, const QString &key) const;
    Q_INVOKABLE void setGeneral(const QString &key, const QString &value);
    Q_INVOKABLE void setOption(const QString &module, const QString &key, const QString &value);
    Q_INVOKABLE void setModuleEnabled(const QString &module, bool enabled);
    Q_INVOKABLE void reload();
    Q_INVOKABLE void importConfig(const QUrl &file);
    Q_INVOKABLE void exportConfig(const QUrl &file);
    Q_INVOKABLE void addAddon(const QUrl &file);
    Q_INVOKABLE void clearAddons();
    Q_INVOKABLE QStringList addons() const { return m_addons; }
    Q_INVOKABLE void chooseOutput(const QUrl &folder);
    Q_INVOKABLE void generate();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void openResult();
signals:
    void schemaChanged();
    void valuesChanged();
    void stateChanged();
    void preferencesChanged();
    void logChanged();
    void resultChanged();
    void generationFinished(bool success);
private:
    QString m_engine, m_dataDir, m_stateDir, m_status = "Загрузка настроек генератора…";
    QString m_log, m_preview, m_result, m_output;
    QStringList m_addons;
    Configuration m_config;
    QVariantMap m_schema;
    std::unique_ptr<QSettings> m_preferences;
    QProcess m_schemaProcess, m_worker;
    QTimer m_reloadTimer, m_schemaTimeout, m_saveTimer;
    std::unique_ptr<QTemporaryDir> m_schemaDir, m_job;
    QByteArray m_pendingOutput;
    bool m_loading = false, m_busy = false, m_cancelled = false, m_pendingReload = false;
    double m_progress = 0;
    int m_revision = 0;
    void requestSchema();
    void schemaFinished(int exitCode, QProcess::ExitStatus status);
    void generationDone(int exitCode, QProcess::ExitStatus status);
    void consumeOutput();
    void appendLog(const QString &text);
    void fail(const QString &error);
    void saveState();
    bool writeConfig(const QString &path);
    QStringList arguments(const QString &directory) const;
};
