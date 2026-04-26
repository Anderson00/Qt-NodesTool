#include "globalproperties.h"
#include <QStandardPaths>
#include <QDir>

GlobalProperties::GlobalProperties(QObject *parent)
    : QObject(parent), m_debugMode(false)
{
    // Create QSettings with app-specific location
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath);
    
    m_settings = new QSettings(
        appDataPath + "/ValkyriSettings.ini",
        QSettings::IniFormat,
        this
    );

    // Load properties from file
    loadProperties();
}

GlobalProperties::~GlobalProperties()
{
    // Save before destruction
    saveProperties();
}

GlobalProperties* GlobalProperties::instance()
{
    static GlobalProperties* _instance = new GlobalProperties();
    return _instance;
}

QObject *GlobalProperties::qmlSingletonProvider(QQmlEngine *, QJSEngine *)
{
    return GlobalProperties::instance();
}

bool GlobalProperties::debugMode() const
{
    return m_debugMode;
}

void GlobalProperties::setDebugMode(bool value)
{
    if (m_debugMode != value) {
        m_debugMode = value;
        saveProperties();
        emit debugModeChanged();
    }
}

void GlobalProperties::saveProperties()
{
    if (!m_settings) return;

    m_settings->setValue("debug/enabled", m_debugMode);
    m_settings->sync();
}

void GlobalProperties::loadProperties()
{
    if (!m_settings) return;

    m_debugMode = m_settings->value("debug/enabled", false).toBool();
    setDebugMode(false);
}
