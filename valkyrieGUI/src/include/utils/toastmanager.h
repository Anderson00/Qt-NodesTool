#ifndef TOASTMANAGER_H
#define TOASTMANAGER_H

#include <QObject>
#include <QString>
#include <QQueue>
#include <QTimer>

class QQmlEngine;
class QJSEngine;

class ToastManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString message   READ message   NOTIFY messageChanged)
    Q_PROPERTY(QString type      READ type      NOTIFY typeChanged)
    Q_PROPERTY(bool    visible   READ visible   NOTIFY visibilityChanged)

public:
    static ToastManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QString message() const { return m_message; }
    QString type()    const { return m_type; }
    bool    visible() const { return m_visible; }

    Q_INVOKABLE void show(const QString& msg, const QString& toastType = "info");
    Q_INVOKABLE void hide();

signals:
    void messageChanged();
    void typeChanged();
    void visibilityChanged();

private:
    explicit ToastManager(QObject* parent = nullptr);
    ~ToastManager();
    void processQueue();
    void onHideTimeout();

    struct ToastItem {
        QString message;
        QString type;
    };

    QQueue<ToastItem> m_queue;
    QString m_message;
    QString m_type;
    bool m_visible = false;

    QTimer* m_hideTimer = nullptr;
};

#endif // TOASTMANAGER_H
