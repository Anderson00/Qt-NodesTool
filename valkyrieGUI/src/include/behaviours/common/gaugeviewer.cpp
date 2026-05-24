#include "gaugeviewer.h"
#include "behaviours/behaviourregistry.h"
#include <QVariantList>

REGISTER_BEHAVIOUR(GaugeViewer, "Gauge", "Circular gauge with configurable color zones and digital readout", "Visualization", 1, 0)

GaugeViewer::GaugeViewer(QObject *parent) : Behaviours(parent)
{
    this->setWidth(280);
    this->setHeight(380);
    this->setContentHeight(380);
    this->setQmlBodyUrl("qrc:/behaviours/common/GaugeViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
        "inputValueChanged()",
        "gaugeMinChanged()",
        "gaugeMaxChanged()",
        "warnThreshChanged()",
        "critThreshChanged()",
        "unitLabelChanged()",
        "internalSetValue(double)",
        "internalSetMin(double)",
        "internalSetMax(double)",
        "internalSetWarn(double)",
        "internalSetCrit(double)",
        "internalSetUnit(QString)"
    }));
}

QMap<QString, QVariant> GaugeViewer::loadInfos()
{
    return GaugeViewer::static_infos();
}

QMap<QString, QVariant> GaugeViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "GaugeViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "GaugeViewer"},
        {"desc",          "Circular gauge with color zones"},
        {"inputs_count",  "1"},
        {"outputs_count", "0"}
    });
}

double  GaugeViewer::inputValue() const { return m_inputValue; }
double  GaugeViewer::gaugeMin()   const { return m_gaugeMin; }
double  GaugeViewer::gaugeMax()   const { return m_gaugeMax; }
double  GaugeViewer::warnThresh() const { return m_warnThresh; }
double  GaugeViewer::critThresh() const { return m_critThresh; }
QString GaugeViewer::unitLabel()  const { return m_unitLabel; }

void GaugeViewer::setInputValue(double value)
{
    m_inputValue = value;
    emit inputValueChanged();
    emit internalSetValue(value);
}

void GaugeViewer::setMin(double v)
{
    if (!qFuzzyCompare(m_gaugeMin, v)) {
        m_gaugeMin = v;
        emit gaugeMinChanged();
        emit internalSetMin(v);
    }
}

void GaugeViewer::setMax(double v)
{
    if (!qFuzzyCompare(m_gaugeMax, v)) {
        m_gaugeMax = v;
        emit gaugeMaxChanged();
        emit internalSetMax(v);
    }
}

void GaugeViewer::setWarn(double v)
{
    if (!qFuzzyCompare(m_warnThresh, v)) {
        m_warnThresh = v;
        emit warnThreshChanged();
        emit internalSetWarn(v);
    }
}

void GaugeViewer::setCrit(double v)
{
    if (!qFuzzyCompare(m_critThresh, v)) {
        m_critThresh = v;
        emit critThreshChanged();
        emit internalSetCrit(v);
    }
}

void GaugeViewer::setUnit(const QString& unit)
{
    if (m_unitLabel != unit) {
        m_unitLabel = unit;
        emit unitLabelChanged();
        emit internalSetUnit(unit);
    }
}

void GaugeViewer::setInputData(const QVariantList& data)
{
    if (data.isEmpty()) return;
    setInputValue(data[0].toDouble());
    if (data.size() >= 3) {
        setMin(data[1].toDouble());
        setMax(data[2].toDouble());
    }
}

QJsonObject GaugeViewer::saveState() const
{
    QJsonObject s;
    s["gaugeMin"]   = m_gaugeMin;
    s["gaugeMax"]   = m_gaugeMax;
    s["warnThresh"] = m_warnThresh;
    s["critThresh"] = m_critThresh;
    s["unitLabel"]  = m_unitLabel;
    return s;
}

void GaugeViewer::loadState(const QJsonObject& s)
{
    if (s.contains("gaugeMin"))   setMin(s["gaugeMin"].toDouble());
    if (s.contains("gaugeMax"))   setMax(s["gaugeMax"].toDouble());
    if (s.contains("warnThresh")) setWarn(s["warnThresh"].toDouble());
    if (s.contains("critThresh")) setCrit(s["critThresh"].toDouble());
    if (s.contains("unitLabel"))  setUnit(s["unitLabel"].toString());
}
