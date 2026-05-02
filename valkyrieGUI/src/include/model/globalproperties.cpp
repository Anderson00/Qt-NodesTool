#include "globalproperties.h"
#include <QtQml/QQmlEngine>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QFile>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

GlobalProperties::GlobalProperties(QObject* parent) : QObject(parent) {
    migrateFromIni();
    loadProperties();
}

GlobalProperties::~GlobalProperties() {
    saveProperties();
}

GlobalProperties* GlobalProperties::instance() {
    static GlobalProperties* _instance = new GlobalProperties();
    return _instance;
}

QObject* GlobalProperties::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    return GlobalProperties::instance();
}

// ── File path ─────────────────────────────────────────────────────────────────

QString GlobalProperties::settingsFilePath() const {
    const QString dir = QCoreApplication::applicationDirPath();
    QDir().mkpath(dir);
    return dir + "/settings.json";
}

// ── Migration from legacy INI ─────────────────────────────────────────────────

void GlobalProperties::migrateFromIni() {
    const QString dir    = QCoreApplication::applicationDirPath();
    const QString iniPath = dir + "/ValkyriSettings.ini";
    const QString jsonPath = settingsFilePath();

    if (QFile::exists(jsonPath) || !QFile::exists(iniPath))
        return;

    QSettings ini(iniPath, QSettings::IniFormat);
    m_debugMode = ini.value("debug/enabled", false).toBool();
    saveProperties(); // write as JSON
    qDebug() << "GlobalProperties: migrated from INI to settings.json";
}

// ── Persistence ───────────────────────────────────────────────────────────────

void GlobalProperties::saveProperties() {
    QJsonObject debug;
    debug["enabled"] = m_debugMode;

    QJsonObject session;
    session["lastWorkspace"] = m_lastWorkspace;
    session["lastPresetId"]  = m_lastPresetId;

    QJsonObject root;
    root["version"] = 1;
    root["debug"]   = debug;
    root["session"] = session;

    QFile file(settingsFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "GlobalProperties: cannot write settings.json";
        return;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[GlobalProperties] Saved -> lastWorkspace:" << m_lastWorkspace
             << "| lastPresetId:" << m_lastPresetId
             << "| debugMode:" << m_debugMode;
}

void GlobalProperties::loadProperties() {
    QFile file(settingsFilePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly))
        return;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (doc.isNull() || !doc.isObject()) {
        qWarning() << "GlobalProperties: malformed settings.json";
        return;
    }

    const QJsonObject root = doc.object();
    m_debugMode     = root["debug"].toObject()["enabled"].toBool(false);
    m_lastWorkspace = root["session"].toObject()["lastWorkspace"].toString();
    m_lastPresetId  = root["session"].toObject()["lastPresetId"].toString();
    qDebug() << "[GlobalProperties] Loaded -> lastWorkspace:" << m_lastWorkspace
             << "| lastPresetId:" << m_lastPresetId
             << "| debugMode:" << m_debugMode;
}

// ── Getters / Setters ─────────────────────────────────────────────────────────

bool    GlobalProperties::debugMode()     const { return m_debugMode; }
QString GlobalProperties::lastWorkspace() const { return m_lastWorkspace; }
QString GlobalProperties::lastPresetId()  const { return m_lastPresetId; }

void GlobalProperties::setDebugMode(bool value) {
    if (m_debugMode != value) {
        m_debugMode = value;
        saveProperties();
        emit debugModeChanged();
    }
}

void GlobalProperties::setLastWorkspace(const QString& name) {
    if (m_lastWorkspace != name) {
        m_lastWorkspace = name;
        saveProperties();
        emit lastWorkspaceChanged();
    }
}

void GlobalProperties::setLastPresetId(const QString& id) {
    if (m_lastPresetId != id) {
        m_lastPresetId = id;
        saveProperties();
        emit lastPresetIdChanged();
    }
}
