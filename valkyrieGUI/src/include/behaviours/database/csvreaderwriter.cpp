#include "csvreaderwriter.h"
#include "behaviours/behaviourregistry.h"

#include <QFile>
#include <QTextStream>

REGISTER_BEHAVIOUR(CSVReaderWriter, "CSV Reader/Writer", "Read and write CSV files with configurable delimiter", "database", 4, 2)

CSVReaderWriter::CSVReaderWriter(QObject *parent)
    : Behaviours(parent)
{
    setWidth(340);
    setHeight(280);
    setContentHeight(280);
    setQmlBodyUrl("qrc:/behaviours/database/CSVReaderWriter.qml");

    addInputOutputExclusion(QList<QString>({
        "internalRowsRead(QVariantList,QStringList)",
        "internalError(QString)",
        "internalClear()"
    }));
}

QMap<QString, QVariant> CSVReaderWriter::loadInfos()
{
    return CSVReaderWriter::static_infos();
}

QMap<QString, QVariant> CSVReaderWriter::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "CSVReaderWriter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "CSVReaderWriter"},
        {"desc",          "Read and write CSV files with configurable delimiter"},
        {"inputs_count",  "4"},
        {"outputs_count", "2"}
    });
}

void CSVReaderWriter::setDelimiter(const QString& delim)
{
    if (m_delimiter != delim) {
        m_delimiter = delim;
        emit delimiterChanged();
    }
}

void CSVReaderWriter::setHasHeader(bool v)
{
    if (m_hasHeader != v) {
        m_hasHeader = v;
        emit hasHeaderChanged();
    }
}

void CSVReaderWriter::setDelimiterSlot(QString delim)
{
    setDelimiter(delim);
}

QStringList CSVReaderWriter::parseLine(const QString& line) const
{
    QStringList fields;
    QString field;
    bool inQuotes = false;
    for (int i = 0; i < line.size(); ++i) {
        QChar ch = line[i];
        if (inQuotes) {
            if (ch == '"') {
                // Check for escaped quote ""
                if (i + 1 < line.size() && line[i + 1] == '"') {
                    field += '"';
                    ++i;
                } else {
                    inQuotes = false;
                }
            } else {
                field += ch;
            }
        } else {
            if (ch == '"') {
                inQuotes = true;
            } else if (QStringView(line).mid(i, m_delimiter.size()) == m_delimiter) {
                fields.append(field);
                field.clear();
                i += m_delimiter.size() - 1;
            } else {
                field += ch;
            }
        }
    }
    fields.append(field);
    return fields;
}

QString CSVReaderWriter::quotedField(const QString& field) const
{
    if (field.contains(m_delimiter) || field.contains('"') || field.contains('\n')) {
        QString escaped = field;
        escaped.replace("\"", "\"\"");
        return "\"" + escaped + "\"";
    }
    return field;
}

void CSVReaderWriter::readFile(QString path)
{
    m_filePath = path;
    emit filePathChanged();

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString msg = "Cannot open file: " + path;
        emit error(msg);
        emit internalError(msg);
        return;
    }

    QTextStream in(&file);
    QStringList headers;
    QVariantList rows;
    bool firstLine = true;

    while (!in.atEnd()) {
        QString line = in.readLine();
        if (line.trimmed().isEmpty())
            continue;

        QStringList fields = parseLine(line);

        if (firstLine && m_hasHeader) {
            headers = fields;
            firstLine = false;
            m_columnCount = headers.size();
            continue;
        }

        if (firstLine) {
            // No header — generate column names
            firstLine = false;
            m_columnCount = fields.size();
            for (int i = 0; i < m_columnCount; ++i)
                headers.append("col" + QString::number(i + 1));
        }

        QVariantMap row;
        for (int i = 0; i < headers.size() && i < fields.size(); ++i)
            row[headers[i]] = fields[i];
        rows.append(row);
    }
    file.close();

    m_rowCount = rows.size();
    emit rowCountChanged();
    emit columnCountChanged();
    emit rowsRead(rows, headers);
    emit internalRowsRead(rows, headers);
}

void CSVReaderWriter::writeFile(QString path, QVariantList rows)
{
    if (rows.isEmpty())
        return;

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QString msg = "Cannot write file: " + path;
        emit error(msg);
        emit internalError(msg);
        return;
    }

    QTextStream out(&file);

    // Collect headers from first row
    QStringList headers;
    if (!rows.isEmpty()) {
        QVariantMap firstRow = rows[0].toMap();
        headers = firstRow.keys();
    }

    if (m_hasHeader) {
        QStringList headerFields;
        for (const QString& h : headers)
            headerFields.append(quotedField(h));
        out << headerFields.join(m_delimiter) << "\n";
    }

    for (const QVariant& rv : rows) {
        QVariantMap row = rv.toMap();
        QStringList fields;
        for (const QString& h : headers)
            fields.append(quotedField(row.value(h).toString()));
        out << fields.join(m_delimiter) << "\n";
    }
    file.close();
}

void CSVReaderWriter::clear()
{
    m_rowCount    = 0;
    m_columnCount = 0;
    m_filePath    = "";
    emit rowCountChanged();
    emit columnCountChanged();
    emit filePathChanged();
    emit internalClear();
}

QJsonObject CSVReaderWriter::saveState() const
{
    QJsonObject state;
    state["filePath"]  = m_filePath;
    state["delimiter"] = m_delimiter;
    state["hasHeader"] = m_hasHeader;
    return state;
}

void CSVReaderWriter::loadState(const QJsonObject& state)
{
    if (state.contains("delimiter")) setDelimiter(state["delimiter"].toString(","));
    if (state.contains("hasHeader")) setHasHeader(state["hasHeader"].toBool(true));
    if (state.contains("filePath")) {
        QString path = state["filePath"].toString();
        if (!path.isEmpty()) {
            m_filePath = path;
            emit filePathChanged();
        }
    }
}
