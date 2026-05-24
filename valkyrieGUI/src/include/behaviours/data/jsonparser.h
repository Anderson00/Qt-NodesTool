#ifndef JSONPARSER_H
#define JSONPARSER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QStringList>
#include <behaviours/behaviours.h>

class JSONParser : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentPathChanged)
    Q_PROPERTY(QString lastResult  READ lastResult  NOTIFY lastResultChanged)
    Q_PROPERTY(QString lastError   READ lastError   NOTIFY lastErrorChanged)

public:
    explicit JSONParser(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString currentPath() const;
    QString lastResult() const;
    QString lastError() const;

public slots:
    void parse(QString json);
    void setPath(QString dotPath);

signals:
    // Node outputs
    void valueExtracted(QString value);
    void error(QString msg);
    void allKeys(QStringList keys);

    // Internal QML-only signals
    void internalResult(QString path, QString value);
    void internalError(QString msg);
    void internalKeys(QStringList keys);

    // Property notifiers
    void currentPathChanged();
    void lastResultChanged();
    void lastErrorChanged();

private:
    QString extractPath(const QJsonValue& root, const QStringList& parts) const;
    void processJson(const QString& json, const QString& path);

    QString m_currentPath;
    QString m_lastResult;
    QString m_lastError;
    QString m_lastJson;
};

#endif // JSONPARSER_H
