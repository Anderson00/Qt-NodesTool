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
    const QString dir     = QCoreApplication::applicationDirPath();
    const QString iniPath = dir + "/ValkyriSettings.ini";
    const QString jsonPath = settingsFilePath();

    if (QFile::exists(jsonPath) || !QFile::exists(iniPath))
        return;

    QSettings ini(iniPath, QSettings::IniFormat);
    m_debugMode = ini.value("debug/enabled", false).toBool();
    saveProperties();
    qDebug() << "GlobalProperties: migrated from INI to settings.json";
}

// ── Persistence ───────────────────────────────────────────────────────────────

void GlobalProperties::saveProperties() {
    QJsonObject debugObj;
    debugObj["enabled"] = m_debugMode;
    debugObj["showFps"] = m_showFps;

    QJsonObject themeObj;
    themeObj["isDarkMode"] = m_isDarkMode;

    QJsonObject gridObj;
    gridObj["preset"]   = m_gridPreset;
    gridObj["minWgrid"] = m_minWgrid;
    gridObj["pattern"]  = m_gridPattern;

    QJsonObject sessionObj;
    sessionObj["lastWorkspace"] = m_lastWorkspace;
    sessionObj["lastPresetId"]  = m_lastPresetId;

    QJsonObject uiObj;
    uiObj["nodesListPosition"] = m_nodesListPosition;
    uiObj["connectionStyle"]   = m_connectionStyle;

    QJsonObject snapObj;
    snapObj["enabled"]       = m_snapEnabled;
    snapObj["gridSize"]      = m_snapGridSize;
    snapObj["syncToGrid"]    = m_snapSyncToGrid;
    snapObj["mode"]          = m_snapMode;
    snapObj["radius"]        = m_snapRadius;
    snapObj["toNodes"]       = m_snapToNodes;
    snapObj["showCoords"]    = m_snapShowCoords;
    snapObj["resizeEnabled"] = m_snapResizeEnabled;
    snapObj["guideColor"]    = m_snapGuideColor;

    QJsonObject root;
    root["version"] = 1;
    root["debug"]   = debugObj;
    root["theme"]   = themeObj;
    root["grid"]    = gridObj;
    root["session"] = sessionObj;
    root["ui"]      = uiObj;
    root["snap"]    = snapObj;

    QFile file(settingsFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "GlobalProperties: cannot write settings.json";
        return;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
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

    const QJsonObject root      = doc.object();
    const QJsonObject debugObj  = root["debug"].toObject();
    const QJsonObject themeObj  = root["theme"].toObject();
    const QJsonObject gridObj   = root["grid"].toObject();
    const QJsonObject uiObj     = root["ui"].toObject();
    const QJsonObject snapObj   = root["snap"].toObject();

    m_debugMode          = debugObj["enabled"].toBool(false);
    m_showFps            = debugObj["showFps"].toBool(false);
    m_isDarkMode         = themeObj["isDarkMode"].toBool(true);
    m_gridPreset         = gridObj["preset"].toString("normal");
    m_minWgrid           = gridObj["minWgrid"].toInt(20);
    m_gridPattern        = gridObj["pattern"].toString("dots");
    m_lastWorkspace      = root["session"].toObject()["lastWorkspace"].toString();
    m_lastPresetId       = root["session"].toObject()["lastPresetId"].toString();
    m_nodesListPosition  = uiObj["nodesListPosition"].toString("bottom-left");
    m_connectionStyle    = uiObj["connectionStyle"].toString("pills");

    m_snapEnabled        = snapObj["enabled"].toBool(false);
    m_snapGridSize       = snapObj["gridSize"].toInt(20);
    m_snapSyncToGrid     = snapObj["syncToGrid"].toBool(true);
    m_snapMode           = snapObj["mode"].toString("hard");
    m_snapRadius         = snapObj["radius"].toInt(10);
    m_snapToNodes        = snapObj["toNodes"].toBool(false);
    m_snapShowCoords     = snapObj["showCoords"].toBool(true);
    m_snapResizeEnabled  = snapObj["resizeEnabled"].toBool(false);
    m_snapGuideColor     = snapObj["guideColor"].toString("#00e676");
}

// ── Getters ───────────────────────────────────────────────────────────────────

bool    GlobalProperties::debugMode()         const { return m_debugMode; }
bool    GlobalProperties::showFps()           const { return m_showFps; }
bool    GlobalProperties::isDarkMode()        const { return m_isDarkMode; }
QString GlobalProperties::lastWorkspace()     const { return m_lastWorkspace; }
QString GlobalProperties::lastPresetId()      const { return m_lastPresetId; }
QString GlobalProperties::gridPreset()        const { return m_gridPreset; }
int     GlobalProperties::minWgrid()          const { return m_minWgrid; }
QString GlobalProperties::gridPattern()       const { return m_gridPattern; }
QString GlobalProperties::nodesListPosition() const { return m_nodesListPosition; }
QString GlobalProperties::connectionStyle()   const { return m_connectionStyle; }

bool    GlobalProperties::snapEnabled()       const { return m_snapEnabled; }
int     GlobalProperties::snapGridSize()      const { return m_snapGridSize; }
bool    GlobalProperties::snapSyncToGrid()    const { return m_snapSyncToGrid; }
QString GlobalProperties::snapMode()          const { return m_snapMode; }
int     GlobalProperties::snapRadius()        const { return m_snapRadius; }
bool    GlobalProperties::snapToNodes()       const { return m_snapToNodes; }
bool    GlobalProperties::snapShowCoords()    const { return m_snapShowCoords; }
bool    GlobalProperties::snapResizeEnabled() const { return m_snapResizeEnabled; }
QString GlobalProperties::snapGuideColor()    const { return m_snapGuideColor; }

// ── Setters ───────────────────────────────────────────────────────────────────

void GlobalProperties::setDebugMode(bool value) {
    if (m_debugMode != value) { m_debugMode = value; saveProperties(); emit debugModeChanged(); }
}
void GlobalProperties::setShowFps(bool value) {
    if (m_showFps != value) { m_showFps = value; saveProperties(); emit showFpsChanged(); }
}
void GlobalProperties::setIsDarkMode(bool value) {
    if (m_isDarkMode != value) { m_isDarkMode = value; saveProperties(); emit isDarkModeChanged(); }
}
void GlobalProperties::setLastWorkspace(const QString& name) {
    if (m_lastWorkspace != name) { m_lastWorkspace = name; saveProperties(); emit lastWorkspaceChanged(); }
}
void GlobalProperties::setLastPresetId(const QString& id) {
    if (m_lastPresetId != id) { m_lastPresetId = id; saveProperties(); emit lastPresetIdChanged(); }
}
void GlobalProperties::setGridPreset(const QString& preset) {
    if (m_gridPreset != preset) {
        m_gridPreset = preset;
        if      (preset == "compact")     m_minWgrid = 10;
        else if (preset == "normal")      m_minWgrid = 20;
        else if (preset == "comfortable") m_minWgrid = 40;
        else if (preset == "spacious")    m_minWgrid = 60;
        saveProperties();
        emit gridPresetChanged();
        emit minWgridChanged();
    }
}
void GlobalProperties::setMinWgrid(int value) {
    if (m_minWgrid != value) {
        m_minWgrid   = value;
        m_gridPreset = "custom";
        saveProperties();
        emit minWgridChanged();
        emit gridPresetChanged();
    }
}
void GlobalProperties::applyGridPreset(const QString& preset) { setGridPreset(preset); }
void GlobalProperties::setGridPattern(const QString& pattern) {
    if (m_gridPattern != pattern) { m_gridPattern = pattern; saveProperties(); emit gridPatternChanged(); }
}
void GlobalProperties::setNodesListPosition(const QString& position) {
    if (m_nodesListPosition != position) { m_nodesListPosition = position; saveProperties(); emit nodesListPositionChanged(); }
}
void GlobalProperties::setConnectionStyle(const QString& style) {
    if (m_connectionStyle != style) { m_connectionStyle = style; saveProperties(); emit connectionStyleChanged(); }
}

void GlobalProperties::setSnapEnabled(bool value) {
    if (m_snapEnabled != value) { m_snapEnabled = value; saveProperties(); emit snapEnabledChanged(); }
}
void GlobalProperties::setSnapGridSize(int value) {
    if (m_snapGridSize != value) { m_snapGridSize = value; saveProperties(); emit snapGridSizeChanged(); }
}
void GlobalProperties::setSnapSyncToGrid(bool value) {
    if (m_snapSyncToGrid != value) { m_snapSyncToGrid = value; saveProperties(); emit snapSyncToGridChanged(); }
}
void GlobalProperties::setSnapMode(const QString& mode) {
    if (m_snapMode != mode) { m_snapMode = mode; saveProperties(); emit snapModeChanged(); }
}
void GlobalProperties::setSnapRadius(int value) {
    if (m_snapRadius != value) { m_snapRadius = value; saveProperties(); emit snapRadiusChanged(); }
}
void GlobalProperties::setSnapToNodes(bool value) {
    if (m_snapToNodes != value) { m_snapToNodes = value; saveProperties(); emit snapToNodesChanged(); }
}
void GlobalProperties::setSnapShowCoords(bool value) {
    if (m_snapShowCoords != value) { m_snapShowCoords = value; saveProperties(); emit snapShowCoordsChanged(); }
}
void GlobalProperties::setSnapResizeEnabled(bool value) {
    if (m_snapResizeEnabled != value) { m_snapResizeEnabled = value; saveProperties(); emit snapResizeEnabledChanged(); }
}
void GlobalProperties::setSnapGuideColor(const QString& color) {
    if (m_snapGuideColor != color) { m_snapGuideColor = color; saveProperties(); emit snapGuideColorChanged(); }
}
