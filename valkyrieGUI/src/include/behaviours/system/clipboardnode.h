#ifndef CLIPBOARDNODE_H
#define CLIPBOARDNODE_H

#include <QObject>
#include <QJsonObject>
#include <QClipboard>
#include <behaviours/behaviours.h>

class ClipboardNode : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString lastText       READ lastText       NOTIFY lastTextChanged)
    Q_PROPERTY(bool    monitorChanges READ monitorChanges WRITE setMonitorChanges NOTIFY monitorChangesChanged)

public:
    explicit ClipboardNode(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QString lastText()       const;
    bool    monitorChanges() const;

    void setMonitorChanges(bool enabled);

public slots:
    void writeText(QString text);
    void readText();

signals:
    // Node output
    void clipboardRead(QString text);

    // Internal QML-only signals
    void internalClipboardChanged(QString text);
    void internalRead(QString text);

    // Property notifiers
    void lastTextChanged();
    void monitorChangesChanged();

private:
    QString m_lastText;
    bool    m_monitorChanges = false;
    QMetaObject::Connection m_clipboardConnection;
};

#endif // CLIPBOARDNODE_H
