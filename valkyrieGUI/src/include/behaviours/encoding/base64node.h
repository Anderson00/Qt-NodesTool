#ifndef BASE64NODE_H
#define BASE64NODE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class Base64Node : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString lastEncoded READ lastEncoded NOTIFY lastEncodedChanged)
    Q_PROPERTY(QString lastDecoded READ lastDecoded NOTIFY lastDecodedChanged)
    Q_PROPERTY(bool    urlSafe     READ urlSafe     WRITE setUrlSafe NOTIFY urlSafeChanged)

public:
    explicit Base64Node(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString lastEncoded() const { return m_lastEncoded; }
    QString lastDecoded() const { return m_lastDecoded; }
    bool    urlSafe()     const { return m_urlSafe; }

    void setUrlSafe(bool safe);

public slots:
    void encode(QString input);
    void decode(QString base64String);
    void setUrlSafe(bool safe);

signals:
    // Node outputs
    void encoded(QString result);
    void decoded(QString result);

    // Internal QML-only signals
    void internalEncoded(QString result);
    void internalDecoded(QString result);

    // Property notifiers
    void lastEncodedChanged();
    void lastDecodedChanged();
    void urlSafeChanged();

private:
    void setLastEncoded(const QString& val);
    void setLastDecoded(const QString& val);

    QString m_lastEncoded;
    QString m_lastDecoded;
    bool    m_urlSafe;
};

#endif // BASE64NODE_H
