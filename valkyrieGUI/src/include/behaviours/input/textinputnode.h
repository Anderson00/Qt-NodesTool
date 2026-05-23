#ifndef TEXTINPUTNODE_H
#define TEXTINPUTNODE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class TextInputNode : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString text     READ text     WRITE setText     NOTIFY textChanged)
    Q_PROPERTY(bool    autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit TextInputNode(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString text()     const;
    bool    autoSend() const;

public slots:
    void send();
    void setText(const QString& value);
    void setAutoSend(bool enabled);

signals:
    void outputString(QString value);  // OUTPUT PORT

    void textChanged();
    void autoSendChanged();

private:
    QString m_text;
    bool    m_autoSend = false;
};

#endif // TEXTINPUTNODE_H
