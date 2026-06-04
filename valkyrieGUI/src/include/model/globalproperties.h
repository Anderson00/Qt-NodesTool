#ifndef GLOBALPROPERTIES_H
#define GLOBALPROPERTIES_H

#include <QObject>
#include <QStringList>
#include <QJSEngine>

class QQmlEngine;

class GlobalProperties : public QObject
{
    Q_OBJECT

    // ── Viewport / session ────────────────────────────────────────────────────
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
    Q_PROPERTY(QString wireStyle         READ wireStyle         WRITE setWireStyle         NOTIFY wireStyleChanged)
    Q_PROPERTY(QString wireDash          READ wireDash          WRITE setWireDash          NOTIFY wireDashChanged)
    Q_PROPERTY(QString wireAnim          READ wireAnim          WRITE setWireAnim          NOTIFY wireAnimChanged)

    // ── Snap ─────────────────────────────────────────────────────────────────
    Q_PROPERTY(bool    snapEnabled       READ snapEnabled       WRITE setSnapEnabled       NOTIFY snapEnabledChanged)
    Q_PROPERTY(int     snapGridSize      READ snapGridSize      WRITE setSnapGridSize      NOTIFY snapGridSizeChanged)
    Q_PROPERTY(bool    snapSyncToGrid    READ snapSyncToGrid    WRITE setSnapSyncToGrid    NOTIFY snapSyncToGridChanged)
    Q_PROPERTY(QString snapMode          READ snapMode          WRITE setSnapMode          NOTIFY snapModeChanged)
    Q_PROPERTY(int     snapRadius        READ snapRadius        WRITE setSnapRadius        NOTIFY snapRadiusChanged)
    Q_PROPERTY(bool    snapToNodes       READ snapToNodes       WRITE setSnapToNodes       NOTIFY snapToNodesChanged)
    Q_PROPERTY(bool    snapShowCoords    READ snapShowCoords    WRITE setSnapShowCoords    NOTIFY snapShowCoordsChanged)
    Q_PROPERTY(bool    snapResizeEnabled READ snapResizeEnabled WRITE setSnapResizeEnabled NOTIFY snapResizeEnabledChanged)
    Q_PROPERTY(QString snapGuideColor    READ snapGuideColor    WRITE setSnapGuideColor    NOTIFY snapGuideColorChanged)

    // ── Autosave ──────────────────────────────────────────────────────────────
    Q_PROPERTY(bool    autosaveEnabled     READ autosaveEnabled     WRITE setAutosaveEnabled     NOTIFY autosaveEnabledChanged)
    Q_PROPERTY(int     autosaveIntervalMin READ autosaveIntervalMin WRITE setAutosaveIntervalMin NOTIFY autosaveIntervalMinChanged)

    // ── Locale ───────────────────────────────────────────────────────────────
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)

public:
    static GlobalProperties* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    // ── Getters ───────────────────────────────────────────────────────────────
    bool    debugMode()          const;
    bool    showFps()            const;
    bool    isDarkMode()         const;
    QString lastWorkspace()      const;
    QString lastPresetId()       const;
    QString gridPreset()         const;
    int     minWgrid()           const;
    QString gridPattern()        const;
    QString nodesListPosition()  const;
    QString connectionStyle()    const;
    QString wireStyle()          const;
    QString wireDash()           const;
    QString wireAnim()           const;

    bool    snapEnabled()        const;
    int     snapGridSize()       const;
    bool    snapSyncToGrid()     const;
    QString snapMode()           const;
    int     snapRadius()         const;
    bool    snapToNodes()        const;
    bool    snapShowCoords()     const;
    bool    snapResizeEnabled()  const;
    QString snapGuideColor()     const;
    bool    autosaveEnabled()    const;
    int     autosaveIntervalMin() const;
    QString language()           const;

    // ── Setters ───────────────────────────────────────────────────────────────
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
    void setWireStyle(const QString& style);
    void setWireDash(const QString& dash);
    void setWireAnim(const QString& anim);

    void setSnapEnabled(bool value);
    void setSnapGridSize(int value);
    void setSnapSyncToGrid(bool value);
    void setSnapMode(const QString& mode);
    void setSnapRadius(int value);
    void setSnapToNodes(bool value);
    void setSnapShowCoords(bool value);
    void setSnapResizeEnabled(bool value);
    void setSnapGuideColor(const QString& color);
    void setAutosaveEnabled(bool value);
    void setAutosaveIntervalMin(int value);
    void setLanguage(const QString& code);

    Q_INVOKABLE void saveProperties();
    Q_INVOKABLE void loadProperties();
    Q_INVOKABLE void applyGridPreset(const QString& preset);

    Q_INVOKABLE QStringList gridPresets() const {
        return QStringList() << "compact" << "normal" << "comfortable" << "spacious";
    }
    Q_INVOKABLE int gridPresetValue(const QString& preset) const {
        if (preset == "compact")     return 10;
        if (preset == "normal")      return 20;
        if (preset == "comfortable") return 40;
        if (preset == "spacious")    return 60;
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
    void wireStyleChanged();
    void wireDashChanged();
    void wireAnimChanged();

    void snapEnabledChanged();
    void snapGridSizeChanged();
    void snapSyncToGridChanged();
    void snapModeChanged();
    void snapRadiusChanged();
    void snapToNodesChanged();
    void snapShowCoordsChanged();
    void snapResizeEnabledChanged();
    void snapGuideColorChanged();
    void autosaveEnabledChanged();
    void autosaveIntervalMinChanged();
    void languageChanged();

private:
    explicit GlobalProperties(QObject* parent = nullptr);
    ~GlobalProperties();

    GlobalProperties(const GlobalProperties&) = delete;
    GlobalProperties& operator=(const GlobalProperties&) = delete;

    QString settingsFilePath() const;
    void    migrateFromIni();

    // ── Viewport / session members ────────────────────────────────────────────
    bool    m_debugMode          = false;
    bool    m_showFps            = false;
    bool    m_isDarkMode         = true;
    QString m_lastWorkspace;
    QString m_lastPresetId;
    QString m_gridPreset         = "normal";
    int     m_minWgrid           = 20;
    QString m_gridPattern        = "dots";
    QString m_nodesListPosition  = "bottom-left";
    QString m_connectionStyle    = "pills";
    QString m_wireStyle          = "bezier";
    QString m_wireDash           = "dashed";
    QString m_wireAnim           = "flow";

    // ── Snap members ──────────────────────────────────────────────────────────
    bool    m_snapEnabled        = false;
    int     m_snapGridSize       = 20;
    bool    m_snapSyncToGrid     = true;
    QString m_snapMode           = "hard";
    int     m_snapRadius         = 10;
    bool    m_snapToNodes        = false;
    bool    m_snapShowCoords     = true;
    bool    m_snapResizeEnabled  = false;
    QString m_snapGuideColor     = "#00e676";

    // ── Autosave members ──────────────────────────────────────────────────────
    bool    m_autosaveEnabled     = false;
    int     m_autosaveIntervalMin = 5;

    // ── Locale member ─────────────────────────────────────────────────────────
    QString m_language            = QStringLiteral("en");
};

#endif // GLOBALPROPERTIES_H
