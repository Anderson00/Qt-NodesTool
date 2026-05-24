#include "sqlitequery.h"
#include "behaviours/behaviourregistry.h"

#include <QSqlQuery>
#include <QSqlError>
#include <QSqlRecord>
#include <QUuid>

REGISTER_BEHAVIOUR(SQLiteQuery, "SQLite Query", "Execute SQL queries on a local SQLite database", "database", 3, 2)

SQLiteQuery::SQLiteQuery(QObject *parent)
    : Behaviours(parent)
{
    setWidth(380);
    setHeight(340);
    setContentHeight(340);
    setQmlBodyUrl("qrc:/behaviours/database/SQLiteQuery.qml");

    m_connectionName = "valkyrie_" + QUuid::createUuid().toString(QUuid::WithoutBraces);

    addInputOutputExclusion(QList<QString>({
        "internalRowsFetched(QVariantList,QStringList)",
        "internalError(QString)"
    }));
}

SQLiteQuery::~SQLiteQuery()
{
    if (QSqlDatabase::contains(m_connectionName)) {
        {
            QSqlDatabase db = QSqlDatabase::database(m_connectionName);
            if (db.isOpen())
                db.close();
        }
        QSqlDatabase::removeDatabase(m_connectionName);
    }
}

QMap<QString, QVariant> SQLiteQuery::loadInfos()
{
    return SQLiteQuery::static_infos();
}

QMap<QString, QVariant> SQLiteQuery::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "SQLiteQuery"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "SQLiteQuery"},
        {"desc",          "Execute SQL queries on a local SQLite database"},
        {"inputs_count",  "3"},
        {"outputs_count", "2"}
    });
}

void SQLiteQuery::setLastError(const QString& err)
{
    m_lastError = err;
    emit lastErrorChanged();
    emit error(err);
    emit internalError(err);
}

void SQLiteQuery::setDatabase(QString filePath)
{
    // Close existing connection if open
    if (QSqlDatabase::contains(m_connectionName)) {
        QSqlDatabase db = QSqlDatabase::database(m_connectionName);
        if (db.isOpen())
            db.close();
        QSqlDatabase::removeDatabase(m_connectionName);
    }

    m_dbPath = filePath;
    emit dbPathChanged();

    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", m_connectionName);
    db.setDatabaseName(filePath);
    if (!db.open()) {
        m_isConnected = false;
        emit isConnectedChanged();
        setLastError(db.lastError().text());
        return;
    }
    m_isConnected = true;
    m_lastError   = "";
    emit isConnectedChanged();
    emit lastErrorChanged();
}

QVariantList SQLiteQuery::runQuery(QSqlQuery& q, QStringList& outHeaders)
{
    QVariantList rows;
    outHeaders.clear();

    QSqlRecord rec = q.record();
    int colCount = rec.count();
    for (int i = 0; i < colCount; ++i)
        outHeaders.append(rec.fieldName(i));

    while (q.next()) {
        QVariantMap row;
        for (int i = 0; i < colCount; ++i)
            row[outHeaders[i]] = q.value(i);
        rows.append(row);
    }
    return rows;
}

void SQLiteQuery::execute(QString sql)
{
    if (!m_isConnected) {
        setLastError("No database connected");
        return;
    }
    m_lastSql = sql;

    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (!q.exec(sql)) {
        setLastError(q.lastError().text());
        return;
    }

    QStringList headers;
    QVariantList rows = runQuery(q, headers);
    m_lastRowCount = rows.size();
    m_lastError    = "";
    emit lastRowCountChanged();
    emit lastErrorChanged();
    emit rowsFetched(rows);
    emit internalRowsFetched(rows, headers);
}

void SQLiteQuery::executeWithParams(QString sql, QVariantList params)
{
    if (!m_isConnected) {
        setLastError("No database connected");
        return;
    }
    m_lastSql = sql;

    QSqlDatabase db = QSqlDatabase::database(m_connectionName);
    QSqlQuery q(db);
    if (!q.prepare(sql)) {
        setLastError(q.lastError().text());
        return;
    }
    for (int i = 0; i < params.size(); ++i)
        q.bindValue(i, params[i]);

    if (!q.exec()) {
        setLastError(q.lastError().text());
        return;
    }

    QStringList headers;
    QVariantList rows = runQuery(q, headers);
    m_lastRowCount = rows.size();
    m_lastError    = "";
    emit lastRowCountChanged();
    emit lastErrorChanged();
    emit rowsFetched(rows);
    emit internalRowsFetched(rows, headers);
}

QJsonObject SQLiteQuery::saveState() const
{
    QJsonObject state;
    state["dbPath"]  = m_dbPath;
    state["lastSql"] = m_lastSql;
    return state;
}

void SQLiteQuery::loadState(const QJsonObject& state)
{
    m_lastSql = state.value("lastSql").toString();
    QString path = state.value("dbPath").toString();
    if (!path.isEmpty())
        setDatabase(path);
}
