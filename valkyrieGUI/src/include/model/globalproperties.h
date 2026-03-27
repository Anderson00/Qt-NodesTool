#ifndef GLOBALPROPERTIES_H
#define GLOBALPROPERTIES_H

#include <QObject>
#include <QSettings>
#include <QQmlListProperty>
#include <QJSEngine>

class GlobalProperties : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool debugMode READ debugMode WRITE setDebugMode NOTIFY debugModeChanged)

public:
    static GlobalProperties* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    // Debug Mode
    bool debugMode() const;
    void setDebugMode(bool value);

    // Save and Load
    void saveProperties();
    void loadProperties();

signals:
    void debugModeChanged();

private:
    explicit GlobalProperties(QObject *parent = nullptr);
    ~GlobalProperties();

    // Prevent copying
    GlobalProperties(const GlobalProperties&) = delete;
    GlobalProperties& operator=(const GlobalProperties&) = delete;

    QSettings* m_settings;
    bool m_debugMode;
};

#endif // GLOBALPROPERTIES_H
