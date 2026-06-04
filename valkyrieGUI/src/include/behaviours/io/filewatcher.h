#ifndef FILEWATCHER_H
#define FILEWATCHER_H

#include <QObject>
#include <QJsonObject>
#include <QFileSystemWatcher>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <behaviours/behaviours.h>

class FileWatcher : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString watchedPath  READ watchedPath  NOTIFY watchedPathChanged)
    Q_PROPERTY(bool    isWatching   READ isWatching   NOTIFY isWatchingChanged)
    Q_PROPERTY(int     changeCount  READ changeCount  NOTIFY changeCountChanged)
    Q_PROPERTY(QString lastChange   READ lastChange   NOTIFY lastChangeChanged)

public:
    explicit FileWatcher(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString watchedPath() const { return m_watchedPath; }
    bool    isWatching()  const { return m_isWatching; }
    int     changeCount() const { return m_changeCount; }
    QString lastChange()  const { return m_lastChange; }

public slots:
    void setPath(QString path);
    void start();
    void stop();
    void readFile();

signals:
    // Node outputs
    void fileChanged(QString path);
    void fileCreated(QString path);
    void fileDeleted(QString path);
    void contentRead(QString content);

    // Internal QML-only signals
    void internalFileChanged(QString path, QString timestamp);
    void internalClear();

    // Property notifiers
    void watchedPathChanged();
    void isWatchingChanged();
    void changeCountChanged();
    void lastChangeChanged();

private slots:
    void onFileChanged(const QString& path);
    void onDirectoryChanged(const QString& path);

private:
    void setWatchedPath(const QString& path);
    void setIsWatching(bool watching);
    void setChangeCount(int count);
    void setLastChange(const QString& change);

    QFileSystemWatcher m_watcher;
    QString            m_watchedPath;
    bool               m_isWatching;
    int                m_changeCount;
    QString            m_lastChange;
    QStringList        m_previousDirEntries;
};

#endif // FILEWATCHER_H
