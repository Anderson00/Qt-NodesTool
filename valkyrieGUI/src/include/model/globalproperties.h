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
    Q_PROPERTY(bool    showFps        READ showFps        WRITE setShowFps        NOTIFY showFpsChanged)
    Q_PROPERTY(bool    isDarkMode     READ isDarkMode     WRITE setIsDarkMode     NOTIFY isDarkModeChanged)
    Q_PROPERTY(QString lastWorkspace  READ lastWorkspace  WRITE setLastWorkspace  NOTIFY lastWorkspaceChanged)
    Q_PROPERTY(QString lastPresetId   READ lastPresetId   WRITE setLastPresetId   NOTIFY lastPresetIdChanged)
    Q_PROPERTY(QString gridPreset     READ gridPreset     WRITE setGridPreset     NOTIFY gridPresetChanged)
    Q_PROPERTY(int     minWgrid       READ minWgrid       WRITE setMinWgrid       NOTIFY minWgridChanged)
    Q_PROPERTY(QString gridPattern    READ gridPattern    WRITE setGridPattern    NOTIFY gridPatternChanged)
    Q_PROPERTY(QString nodesListPosition READ nodesListPosition WRITE setNodesListPosition NOTIFY nodesListPositionChanged)
    Q_PROPERTY(QString connectionStyle   READ connectionStyle   WRITE setConnectionStyle   NOTIFY connectionStyleChanged)

public:
    static GlobalProperties* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    bool    debugMode()     const;
    bool    showFps()       const;
    bool    isDarkMode()    const;
    QString lastWorkspace() const;
    QString lastPresetId()  const;
    QString gridPreset()    const;
    int     minWgrid()      const;
    QString gridPattern()   const;
    QString nodesListPosition() const;
    QString connectionStyle() const;

    void setDebugMode(bool value);
    void setShowFps(bool value);
    void setIsDarkMode(bool value);
    void setLastWorkspace(const QString& name);
    void setLastPresetId(const QString& id);
    void setGridPreset(const QString& preset);
    void setMinWgrid(int value);
    void setGridPattern(const QString& pattern);
    void setNodesListPosition(const QString& position);
    void setConnectionStyle(const QString& style);

    Q_INVOKABLE void saveProperties();
    Q_INVOKABLE void loadProperties();
    Q_INVOKABLE void applyGridPreset(const QString& preset);

    // Expose grid presets to QML
    Q_INVOKABLE QStringList gridPresets() const {
        return QStringList() << "compact" << "normal" << "comfortable" << "spacious";
    }
    Q_INVOKABLE int gridPresetValue(const QString& preset) const {
        if (preset == "compact") return 10;
        if (preset == "normal") return 20;
        if (preset == "comfortable") return 40;
        if (preset == "spacious") return 60;
        return 20;
    }

signals:
    void debugModeChanged();
    void showFpsChanged();
    void isDarkModeChanged();
    void lastWorkspaceChanged();
    void lastPresetIdChanged();
    void gridPresetChanged();
    void minWgridChanged();
    void gridPatternChanged();
    void nodesListPositionChanged();
    void connectionStyleChanged();

private:
    explicit GlobalProperties(QObject* parent = nullptr);
    ~GlobalProperties();

    GlobalProperties(const GlobalProperties&) = delete;
    GlobalProperties& operator=(const GlobalProperties&) = delete;

    QString settingsFilePath() const;
    void    migrateFromIni();

    bool    m_debugMode     = false;
    bool    m_showFps       = false;
    bool    m_isDarkMode    = true;
    QString m_lastWorkspace;
    QString m_lastPresetId;
    QString m_gridPreset    = "normal";
    int     m_minWgrid      = 20;
    QString m_gridPattern   = "dots";
    QString m_nodesListPosition = "bottom-left";
    QString m_connectionStyle   = "pills";
};

#endif // GLOBALPROPERTIES_H
