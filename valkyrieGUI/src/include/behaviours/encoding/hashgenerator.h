#ifndef HASHGENERATOR_H
#define HASHGENERATOR_H

#include <QObject>
#include <QJsonObject>
#include <QCryptographicHash>
#include <behaviours/behaviours.h>

class HashGenerator : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString algorithm READ algorithm WRITE setAlgorithm NOTIFY algorithmChanged)
    Q_PROPERTY(QString lastHash  READ lastHash                     NOTIFY lastHashChanged)

public:
    explicit HashGenerator(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString algorithm() const { return m_algorithm; }
    QString lastHash()  const { return m_lastHash; }

public slots:
    void hash(QString input);
    void setAlgorithm(QString alg);

signals:
    // Node outputs
    void hashReady(QString hexHash);

    // Internal QML-only signals
    void internalHashReady(QString hexHash);
    void internalAlgorithmChanged(QString alg);

    // Property notifiers
    void algorithmChanged();
    void lastHashChanged();

private:
    void setLastHash(const QString& h);

    QString m_algorithm;
    QString m_lastHash;
};

#endif // HASHGENERATOR_H
