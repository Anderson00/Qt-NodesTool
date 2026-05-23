#ifndef DICTINPUT_H
#define DICTINPUT_H

#include <QObject>
#include <QVariantMap>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class DictInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap dict     READ dict     NOTIFY dictChanged)
    Q_PROPERTY(bool        autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit DictInput(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QVariantMap dict()     const;
    bool        autoSend() const;

public slots:
    void send();
    void trigger();
    Q_INVOKABLE void setEntry(const QString& key, const QString& value);
    Q_INVOKABLE void removeEntry(const QString& key);
    Q_INVOKABLE void clearDict();
    void setAutoSend(bool enabled);

signals:
    void outputDict(QVariantMap dict);      // OUTPUT PORT
    void outputString(QString jsonString);  // OUTPUT PORT (JSON)
    void outputCount(int count);            // OUTPUT PORT

    void dictChanged();
    void autoSendChanged();

private:
    QVariantMap m_dict;
    bool        m_autoSend = false;
};

#endif // DICTINPUT_H
