#ifndef SQLITEQUERY_H
#define SQLITEQUERY_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <QStringList>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlField>
#include <behaviours/behaviours.h>

class SQLiteQuery : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString dbPath      READ dbPath      NOTIFY dbPathChanged)
    Q_PROPERTY(int     lastRowCount READ lastRowCount NOTIFY lastRowCountChanged)
    Q_PROPERTY(QString lastError   READ lastError   NOTIFY lastErrorChanged)
    Q_PROPERTY(bool    isConnected READ isConnected NOTIFY isConnectedChanged)

public:
    explicit SQLiteQuery(QObject *parent = nullptr);
    ~SQLiteQuery();

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString dbPath()       const { return m_dbPath; }
    int     lastRowCount() const { return m_lastRowCount; }
    QString lastError()    const { return m_lastError; }
    bool    isConnected()  const { return m_isConnected; }

public slots:
    void setDatabase(QString filePath);
    void execute(QString sql);
    void executeWithParams(QString sql, QVariantList params);

signals:
    // Node outputs
    void rowsFetched(QVariantList rows);
    void error(QString msg);

    // Internal QML bridge
    void internalRowsFetched(QVariantList rows, QStringList headers);
    void internalError(QString msg);

    // Property notifiers
    void dbPathChanged();
    void lastRowCountChanged();
    void lastErrorChanged();
    void isConnectedChanged();

private:
    QVariantList runQuery(QSqlQuery& q, QStringList& outHeaders);
    void setLastError(const QString& err);

    QString m_dbPath;
    int     m_lastRowCount = 0;
    QString m_lastError;
    bool    m_isConnected  = false;
    QString m_connectionName;
    QString m_lastSql;
};

#endif // SQLITEQUERY_H
