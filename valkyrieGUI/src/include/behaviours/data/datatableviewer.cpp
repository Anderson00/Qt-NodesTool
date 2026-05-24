#include "datatableviewer.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonDocument>

REGISTER_BEHAVIOUR(DataTableViewer, "Data Table Viewer", "Dynamic table with sort, filter, and row click events", "data", 4, 2)

DataTableViewer::DataTableViewer(QObject *parent)
    : Behaviours(parent)
{
    this->setWidth(400);
    this->setHeight(340);
    this->setContentHeight(340);
    this->setQmlBodyUrl("qrc:/behaviours/data/DataTableViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalAddRow(QVariantList)",
        "internalSetHeaders(QStringList)",
        "internalClear()",
        "internalRemoveRow(int)"
    }));
}

QMap<QString, QVariant> DataTableViewer::loadInfos()
{
    return DataTableViewer::static_infos();
}

QMap<QString, QVariant> DataTableViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "DataTableViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "DataTableViewer"},
        {"desc",          "Dynamic table with sort, filter, and row click events"},
        {"inputs_count",  "4"},
        {"outputs_count", "2"}
    });
}

int DataTableViewer::rowCount() const
{
    return m_rows.size();
}

int DataTableViewer::columnCount() const
{
    if (!m_headers.isEmpty()) return m_headers.size();
    if (!m_rows.isEmpty())    return m_rows.first().size();
    return 0;
}

QString DataTableViewer::filterText() const
{
    return m_filterText;
}

void DataTableViewer::setFilterText(const QString& text)
{
    if (m_filterText != text) {
        m_filterText = text;
        emit filterTextChanged();
    }
}

void DataTableViewer::addRow(QVariantList row)
{
    m_rows.append(row);
    emit internalAddRow(row);
    emit tableChanged();
}

void DataTableViewer::setHeaders(QStringList headers)
{
    m_headers = headers;
    emit internalSetHeaders(headers);
    emit tableChanged();
}

void DataTableViewer::clear()
{
    m_rows.clear();
    m_headers.clear();
    emit internalClear();
    emit tableChanged();
}

void DataTableViewer::removeRow(int index)
{
    if (index >= 0 && index < m_rows.size()) {
        m_rows.removeAt(index);
        emit internalRemoveRow(index);
        emit tableChanged();
    }
}

QJsonObject DataTableViewer::saveState() const
{
    QJsonObject state;

    QJsonArray headersArr;
    for (const QString& h : m_headers)
        headersArr.append(h);
    state["headers"] = headersArr;

    // Save up to 500 rows
    QJsonArray rowsArr;
    int limit = qMin(m_rows.size(), 500);
    for (int i = 0; i < limit; ++i) {
        QJsonArray rowArr;
        for (const QVariant& cell : m_rows[i])
            rowArr.append(QJsonValue::fromVariant(cell));
        rowsArr.append(rowArr);
    }
    state["rows"] = rowsArr;

    return state;
}

void DataTableViewer::loadState(const QJsonObject& state)
{
    if (state.contains("headers")) {
        m_headers.clear();
        QJsonArray headersArr = state["headers"].toArray();
        for (const QJsonValue& v : headersArr)
            m_headers.append(v.toString());
    }

    if (state.contains("rows")) {
        m_rows.clear();
        QJsonArray rowsArr = state["rows"].toArray();
        for (const QJsonValue& rowVal : rowsArr) {
            QJsonArray rowArr = rowVal.toArray();
            QVariantList row;
            for (const QJsonValue& cell : rowArr)
                row.append(cell.toVariant());
            m_rows.append(row);
        }
    }

    emit internalSetHeaders(m_headers);
    for (const QVariantList& row : m_rows)
        emit internalAddRow(row);
    emit tableChanged();
}
