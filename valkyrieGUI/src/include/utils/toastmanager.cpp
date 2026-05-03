#include "toastmanager.h"
#include <QTimer>
#include <QtQml/QQmlEngine>

ToastManager::ToastManager(QObject* parent)
    : QObject(parent)
{
    m_hideTimer = new QTimer(this);
    m_hideTimer->setInterval(3200);
    m_hideTimer->setSingleShot(true);
    connect(m_hideTimer, &QTimer::timeout, this, &ToastManager::onHideTimeout);
}

ToastManager::~ToastManager() = default;

ToastManager* ToastManager::instance()
{
    static ToastManager* _instance = new ToastManager();
    return _instance;
}

QObject* ToastManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*)
{
    return ToastManager::instance();
}

void ToastManager::show(const QString& msg, const QString& toastType)
{
    if (msg.isEmpty()) return;

    ToastItem item;
    item.message = msg;
    item.type = toastType.isEmpty() ? "info" : toastType;

    m_queue.enqueue(item);

    if (!m_visible) {
        processQueue();
    }
}

void ToastManager::hide()
{
    if (m_visible) {
        m_visible = false;
        m_hideTimer->stop();
        emit visibilityChanged();
        processQueue();
    }
}

void ToastManager::processQueue()
{
    if (m_queue.isEmpty()) {
        m_message = "";
        m_type = "";
        return;
    }

    const ToastItem& item = m_queue.dequeue();

    if (m_message != item.message) {
        m_message = item.message;
        emit messageChanged();
    }

    if (m_type != item.type) {
        m_type = item.type;
        emit typeChanged();
    }

    if (!m_visible) {
        m_visible = true;
        emit visibilityChanged();
        m_hideTimer->start();
    } else {
        m_hideTimer->stop();
        m_hideTimer->start();
    }
}

void ToastManager::onHideTimeout()
{
    m_visible = false;
    emit visibilityChanged();

    if (!m_queue.isEmpty()) {
        QTimer::singleShot(250, this, &ToastManager::processQueue);
    } else {
        m_message = "";
        m_type = "";
        emit messageChanged();
        emit typeChanged();
    }
}
