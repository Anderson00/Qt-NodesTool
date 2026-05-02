#ifndef GLOBALPROPERTIES_H
#define GLOBALPROPERTIES_H

#include <QObject>
#include <QStringList>
#include <QJSEngine>

class QQmlEngine;

class GlobalProperties : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool    debugMode      READ debugMode      WRITE setDebugMode      NOTIFY debugModeChanged)
    Q_PROPERTY(QString lastWorkspace  READ lastWorkspace  WRITE setLastWorkspace  NOTIFY lastWorkspaceChanged)
    Q_PROPERTY(QString lastPresetId   READ lastPresetId   WRITE setLastPresetId   NOTIFY lastPresetIdChanged)

public:
    static GlobalProperties* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    bool    debugMode()     const;
    QString lastWorkspace() const;
    QString lastPresetId()  const;

    void setDebugMode(bool value);
    void setLastWorkspace(const QString& name);
    void setLastPresetId(const QString& id);

    Q_INVOKABLE void saveProperties();
    Q_INVOKABLE void loadProperties();

signals:
    void debugModeChanged();
    void lastWorkspaceChanged();
    void lastPresetIdChanged();

private:
    explicit GlobalProperties(QObject* parent = nullptr);
    ~GlobalProperties();

    GlobalProperties(const GlobalProperties&) = delete;
    GlobalProperties& operator=(const GlobalProperties&) = delete;

    QString settingsFilePath() const;
    void    migrateFromIni();

    bool    m_debugMode     = false;
    QString m_lastWorkspace;
    QString m_lastPresetId;
};

#endif // GLOBALPROPERTIES_H
