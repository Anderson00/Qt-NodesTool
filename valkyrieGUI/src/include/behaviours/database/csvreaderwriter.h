#ifndef CSVREADERWRITER_H
#define CSVREADERWRITER_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <QStringList>
#include <behaviours/behaviours.h>

class CSVReaderWriter : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString filePath    READ filePath    NOTIFY filePathChanged)
    Q_PROPERTY(int     rowCount    READ rowCount    NOTIFY rowCountChanged)
    Q_PROPERTY(int     columnCount READ columnCount NOTIFY columnCountChanged)
    Q_PROPERTY(QString delimiter   READ delimiter   WRITE setDelimiter  NOTIFY delimiterChanged)
    Q_PROPERTY(bool    hasHeader   READ hasHeader   WRITE setHasHeader  NOTIFY hasHeaderChanged)

public:
    explicit CSVReaderWriter(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString filePath()    const { return m_filePath; }
    int     rowCount()    const { return m_rowCount; }
    int     columnCount() const { return m_columnCount; }
    QString delimiter()   const { return m_delimiter; }
    bool    hasHeader()   const { return m_hasHeader; }

    void setDelimiter(const QString& delim);
    void setHasHeader(bool v);

public slots:
    void readFile(QString path);
    void writeFile(QString path, QVariantList rows);
    void setDelimiterSlot(QString delim);
    void clear();

signals:
    // Node outputs
    void rowsRead(QVariantList rows, QStringList headers);
    void error(QString msg);

    // Internal QML bridge
    void internalRowsRead(QVariantList rows, QStringList headers);
    void internalError(QString msg);
    void internalClear();

    // Property notifiers
    void filePathChanged();
    void rowCountChanged();
    void columnCountChanged();
    void delimiterChanged();
    void hasHeaderChanged();

private:
    QStringList parseLine(const QString& line) const;
    QString     quotedField(const QString& field) const;

    QString m_filePath;
    int     m_rowCount    = 0;
    int     m_columnCount = 0;
    QString m_delimiter   = ",";
    bool    m_hasHeader   = true;
};

#endif // CSVREADERWRITER_H
