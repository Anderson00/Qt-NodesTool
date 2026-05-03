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
    debug["showFps"] = m_showFps;

    QJsonObject theme;
    theme["isDarkMode"] = m_isDarkMode;

    QJsonObject session;
    session["lastWorkspace"] = m_lastWorkspace;
    session["lastPresetId"]  = m_lastPresetId;

    QJsonObject root;
    root["version"] = 1;
    root["debug"]   = debug;
    root["theme"]   = theme;
    root["session"] = session;

    QFile file(settingsFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "GlobalProperties: cannot write settings.json";
        return;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[GlobalProperties] Saved -> lastWorkspace:" << m_lastWorkspace
             << "| lastPresetId:" << m_lastPresetId
             << "| debugMode:" << m_debugMode
             << "| showFps:" << m_showFps
             << "| isDarkMode:" << m_isDarkMode;
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
    const QJsonObject debugObj = root["debug"].toObject();
    const QJsonObject themeObj = root["theme"].toObject();
    m_debugMode     = debugObj["enabled"].toBool(false);
    m_showFps       = debugObj["showFps"].toBool(false);
    m_isDarkMode    = themeObj["isDarkMode"].toBool(true);
    m_lastWorkspace = root["session"].toObject()["lastWorkspace"].toString();
    m_lastPresetId  = root["session"].toObject()["lastPresetId"].toString();
    qDebug() << "[GlobalProperties] Loaded -> lastWorkspace:" << m_lastWorkspace
             << "| lastPresetId:" << m_lastPresetId
             << "| debugMode:" << m_debugMode
             << "| showFps:" << m_showFps
             << "| isDarkMode:" << m_isDarkMode;
}

// ── Getters / Setters ─────────────────────────────────────────────────────────

bool    GlobalProperties::debugMode()     const { return m_debugMode; }
bool    GlobalProperties::showFps()       const { return m_showFps; }
bool    GlobalProperties::isDarkMode()    const { return m_isDarkMode; }
QString GlobalProperties::lastWorkspace() const { return m_lastWorkspace; }
QString GlobalProperties::lastPresetId()  const { return m_lastPresetId; }

void GlobalProperties::setDebugMode(bool value) {
    if (m_debugMode != value) {
        m_debugMode = value;
        saveProperties();
        emit debugModeChanged();
    }
}

void GlobalProperties::setShowFps(bool value) {
    if (m_showFps != value) {
        m_showFps = value;
        saveProperties();
        emit showFpsChanged();
    }
}

void GlobalProperties::setIsDarkMode(bool value) {
    if (m_isDarkMode != value) {
        m_isDarkMode = value;
        saveProperties();
        emit isDarkModeChanged();
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
