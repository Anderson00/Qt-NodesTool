#include "logmanager.h"
#include <QDateTime>
#include <QMetaObject>
#include <QThread>
#include <QCoreApplication>

static LogManager* s_instance = nullptr;

LogManager* LogManager::instance() {
    if (!s_instance)
        s_instance = new LogManager();
    return s_instance;
}

QObject* LogManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    return instance();
}

LogManager::LogManager(QObject* parent) : QObject(parent) {}

void LogManager::addEntry(const QString& message, const QString& type) {
    // Message handler may be called from any thread — marshal to main thread.
    if (QCoreApplication::instance() &&
        QThread::currentThread() != QCoreApplication::instance()->thread())
    {
        QMetaObject::invokeMethod(this, "log", Qt::QueuedConnection,
                                  Q_ARG(QString, message),
                                  Q_ARG(QString, type));
        return;
    }
    log(message, type);
}

void LogManager::log(const QString& message, const QString& type) {
    m_lastMessage = message;
    m_lastType    = type;
    m_lastTime    = QDateTime::currentDateTime().toString("HH:mm:ss");
    if (type == "warning")                    m_warnCount++;
    else if (type == "error" || type == "fatal") m_errorCount++;
    emit newEntry();
}

void LogManager::clear() {
    m_lastMessage = "";
    m_lastType    = "info";
    m_lastTime    = "";
    m_warnCount   = 0;
    m_errorCount  = 0;
    emit newEntry();
}
