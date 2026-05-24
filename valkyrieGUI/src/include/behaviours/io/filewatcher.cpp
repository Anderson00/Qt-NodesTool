#include "filewatcher.h"
#include "behaviours/behaviourregistry.h"

#include <QFileInfo>
#include <QDir>

REGISTER_BEHAVIOUR(FileWatcher, "File Watcher", "Monitor files and directories for real-time changes", "io", 4, 4)

FileWatcher::FileWatcher(QObject *parent)
    : Behaviours(parent)
    , m_isWatching(false)
    , m_changeCount(0)
{
    this->setWidth(320);
    this->setHeight(260);
    this->setContentHeight(260);
    this->setQmlBodyUrl("qrc:/behaviours/io/FileWatcher.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalFileChanged(QString,QString)",
        "internalClear()"
    }));

    connect(&m_watcher, &QFileSystemWatcher::fileChanged,
            this, &FileWatcher::onFileChanged);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &FileWatcher::onDirectoryChanged);
}

QMap<QString, QVariant> FileWatcher::loadInfos()
{
    return FileWatcher::static_infos();
}

QMap<QString, QVariant> FileWatcher::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "FileWatcher"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "FileWatcher"},
        {"desc",          "Monitor files and directories for real-time changes"},
        {"inputs_count",  "4"},
        {"outputs_count", "4"}
    });
}

void FileWatcher::setWatchedPath(const QString& path)
{
    if (m_watchedPath != path) {
        m_watchedPath = path;
        emit watchedPathChanged();
    }
}

void FileWatcher::setIsWatching(bool watching)
{
    if (m_isWatching != watching) {
        m_isWatching = watching;
        emit isWatchingChanged();
    }
}

void FileWatcher::setChangeCount(int count)
{
    if (m_changeCount != count) {
        m_changeCount = count;
        emit changeCountChanged();
    }
}

void FileWatcher::setLastChange(const QString& change)
{
    if (m_lastChange != change) {
        m_lastChange = change;
        emit lastChangeChanged();
    }
}

void FileWatcher::setPath(QString path)
{
    setWatchedPath(path);

    // Snapshot directory entries for creation/deletion detection
    QFileInfo fi(path);
    if (fi.isDir()) {
        m_previousDirEntries = QDir(path).entryList(QDir::NoDotAndDotDot | QDir::AllEntries);
    }
}

void FileWatcher::start()
{
    if (m_watchedPath.isEmpty()) return;

    if (!m_watcher.files().contains(m_watchedPath) &&
        !m_watcher.directories().contains(m_watchedPath))
    {
        m_watcher.addPath(m_watchedPath);
    }
    setIsWatching(true);
}

void FileWatcher::stop()
{
    if (!m_watchedPath.isEmpty()) {
        m_watcher.removePath(m_watchedPath);
    }
    setIsWatching(false);
}

void FileWatcher::readFile()
{
    QFile file(m_watchedPath);
    if (!file.open(QFile::ReadOnly | QFile::Text)) return;

    QTextStream stream(&file);
    QString content = stream.readAll();
    file.close();

    emit contentRead(content);
}

void FileWatcher::onFileChanged(const QString& path)
{
    if (!m_isWatching) return;

    setChangeCount(m_changeCount + 1);
    QString ts = QDateTime::currentDateTime().toString("HH:mm:ss");
    setLastChange(ts + " " + path);

    QFileInfo fi(path);
    if (!fi.exists()) {
        emit fileDeleted(path);
    } else {
        emit fileChanged(path);
        emit internalFileChanged(path, ts);
    }

    // Re-add path if it was removed (some editors replace files atomically)
    if (fi.exists() && !m_watcher.files().contains(path)) {
        m_watcher.addPath(path);
    }
}

void FileWatcher::onDirectoryChanged(const QString& path)
{
    if (!m_isWatching) return;

    QDir dir(path);
    QStringList currentEntries = dir.entryList(QDir::NoDotAndDotDot | QDir::AllEntries);

    // Detect created entries
    for (const QString& entry : currentEntries) {
        if (!m_previousDirEntries.contains(entry)) {
            QString fullPath = path + "/" + entry;
            emit fileCreated(fullPath);
            setChangeCount(m_changeCount + 1);
            QString ts = QDateTime::currentDateTime().toString("HH:mm:ss");
            setLastChange(ts + " " + fullPath);
            emit internalFileChanged(fullPath, ts);
        }
    }

    // Detect deleted entries
    for (const QString& entry : m_previousDirEntries) {
        if (!currentEntries.contains(entry)) {
            QString fullPath = path + "/" + entry;
            emit fileDeleted(fullPath);
            setChangeCount(m_changeCount + 1);
            QString ts = QDateTime::currentDateTime().toString("HH:mm:ss");
            setLastChange(ts + " " + fullPath);
            emit internalFileChanged(fullPath, ts);
        }
    }

    m_previousDirEntries = currentEntries;
}

QJsonObject FileWatcher::saveState() const
{
    QJsonObject state;
    state["path"] = m_watchedPath;
    return state;
}

void FileWatcher::loadState(const QJsonObject& state)
{
    if (state.contains("path"))
        setPath(state["path"].toString());
}
