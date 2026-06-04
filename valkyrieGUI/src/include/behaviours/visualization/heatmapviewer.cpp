#include "heatmapviewer.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonArray>
#include <algorithm>

REGISTER_BEHAVIOUR(HeatMapViewer, "Heat Map", "2D intensity grid with configurable color gradient", "visualization", 4, 1)

HeatMapViewer::HeatMapViewer(QObject *parent)
    : Behaviours(parent)
{
    setWidth(340);
    setHeight(320);
    setContentHeight(320);
    setQmlBodyUrl("qrc:/behaviours/visualization/HeatMapViewer.qml");

    addInputOutputExclusion(QList<QString>({
        "internalSetValue(int,int,double)",
        "internalSetGrid(int,int)",
        "internalSetData(QVariantList)",
        "internalClear()"
    }));

    m_data.resize(m_rows * m_cols, 0.0);
}

void HeatMapViewer::onPinsReady()
{
    // inputs
    setPinTypeForSignature("setValue(int,int,double)",  Connections::AnyType);
    setPinTypeForSignature("setGrid(int,int)",          Connections::AnyType);
    setPinTypeForSignature("setData(QVariantList)",     Connections::ArrayType);
    setPinTypeForSignature("clear()",                   Connections::FlowType);
    // outputs
    setPinTypeForSignature("cellClicked(int,int,double)", Connections::AnyType);
}

QMap<QString, QVariant> HeatMapViewer::loadInfos()
{
    return HeatMapViewer::static_infos();
}

QMap<QString, QVariant> HeatMapViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "HeatMapViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "HeatMapViewer"},
        {"desc",          "2D intensity grid with configurable color gradient"},
        {"inputs_count",  "4"},
        {"outputs_count", "1"}
    });
}

void HeatMapViewer::setColorScheme(const QString& scheme)
{
    if (m_colorScheme != scheme) {
        m_colorScheme = scheme;
        emit colorSchemeChanged();
    }
}

void HeatMapViewer::notifyCellClick(int row, int col)
{
    if (row < 0 || row >= m_rows || col < 0 || col >= m_cols)
        return;
    double val = m_data[row * m_cols + col];
    emit cellClicked(row, col, val);
}

void HeatMapViewer::setValue(int row, int col, double value)
{
    if (row < 0 || row >= m_rows || col < 0 || col >= m_cols)
        return;
    m_data[row * m_cols + col] = value;
    recalcMinMax();
    emit internalSetValue(row, col, value);
}

void HeatMapViewer::setGrid(int rows, int cols)
{
    if (rows <= 0 || cols <= 0)
        return;
    m_rows = rows;
    m_cols = cols;
    m_data.fill(0.0, rows * cols);
    m_minValue = 0.0;
    m_maxValue = 1.0;
    emit rowsChanged();
    emit colsChanged();
    emit minValueChanged();
    emit maxValueChanged();
    emit internalSetGrid(rows, cols);
}

void HeatMapViewer::setData(QVariantList flatData)
{
    int expected = m_rows * m_cols;
    for (int i = 0; i < expected && i < flatData.size(); ++i)
        m_data[i] = flatData[i].toDouble();
    recalcMinMax();
    emit internalSetData(flatData);
}

void HeatMapViewer::clear()
{
    m_data.fill(0.0, m_rows * m_cols);
    m_minValue = 0.0;
    m_maxValue = 1.0;
    emit minValueChanged();
    emit maxValueChanged();
    emit internalClear();
}

void HeatMapViewer::recalcMinMax()
{
    if (m_data.isEmpty())
        return;
    double mn = m_data[0];
    double mx = m_data[0];
    for (double v : m_data) {
        if (v < mn) mn = v;
        if (v > mx) mx = v;
    }
    if (mn != m_minValue) { m_minValue = mn; emit minValueChanged(); }
    if (mx != m_maxValue) { m_maxValue = mx; emit maxValueChanged(); }
}

QJsonObject HeatMapViewer::saveState() const
{
    QJsonObject state;
    state["rows"] = m_rows;
    state["cols"] = m_cols;
    state["colorScheme"] = m_colorScheme;
    QJsonArray dataArr;
    for (double v : m_data)
        dataArr.append(v);
    state["data"] = dataArr;
    return state;
}

void HeatMapViewer::loadState(const QJsonObject& state)
{
    int r = state.value("rows").toInt(8);
    int c = state.value("cols").toInt(8);
    setGrid(r, c);
    if (state.contains("colorScheme"))
        setColorScheme(state["colorScheme"].toString());
    if (state.contains("data")) {
        QJsonArray arr = state["data"].toArray();
        QVariantList vl;
        for (const auto& v : arr)
            vl.append(v.toDouble());
        setData(vl);
    }
}
