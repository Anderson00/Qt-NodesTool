#include "maprange.h"
#include "behaviours/behaviourregistry.h"
#include <algorithm>
#include <cmath>

REGISTER_BEHAVIOUR(MapRange, "Map Range", "Maps a value from one numeric range to another with optional clamping", "math", 1, 1)

MapRange::MapRange(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(360);
    this->setContentHeight(360);
    this->setQmlBodyUrl("qrc:/behaviours/math/MapRange.qml");
    this->addInputOutputExclusion(QList<QString>({
        "inputValueChanged()",
        "inMinChanged()",
        "inMaxChanged()",
        "outMinChanged()",
        "outMaxChanged()",
        "clampChanged()",
        "mappedValueChanged()"
    }));
}

QMap<QString, QVariant> MapRange::loadInfos()
{
    return MapRange::static_infos();
}

QMap<QString, QVariant> MapRange::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "MapRange"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "MapRange"},
        {"desc",          "Map value from input range to output range"},
        {"inputs_count",  "1"},
        {"outputs_count", "1"}
    });
}

double MapRange::inputValue()  const { return m_inputValue; }
double MapRange::inMin()       const { return m_inMin; }
double MapRange::inMax()       const { return m_inMax; }
double MapRange::outMin()      const { return m_outMin; }
double MapRange::outMax()      const { return m_outMax; }
bool   MapRange::clamp()       const { return m_clamp; }
double MapRange::mappedValue() const { return m_mappedValue; }

void MapRange::setInputValue(double value)
{
    m_inputValue = value;
    emit inputValueChanged();
    compute();
}

void MapRange::setInMin(double v)
{
    if (!qFuzzyCompare(m_inMin, v)) {
        m_inMin = v;
        emit inMinChanged();
        compute();
    }
}

void MapRange::setInMax(double v)
{
    if (!qFuzzyCompare(m_inMax, v)) {
        m_inMax = v;
        emit inMaxChanged();
        compute();
    }
}

void MapRange::setOutMin(double v)
{
    if (!qFuzzyCompare(m_outMin, v)) {
        m_outMin = v;
        emit outMinChanged();
        compute();
    }
}

void MapRange::setOutMax(double v)
{
    if (!qFuzzyCompare(m_outMax, v)) {
        m_outMax = v;
        emit outMaxChanged();
        compute();
    }
}

void MapRange::setClamp(bool c)
{
    if (m_clamp != c) {
        m_clamp = c;
        emit clampChanged();
        compute();
    }
}

void MapRange::compute()
{
    double range = m_inMax - m_inMin;
    double n     = (std::abs(range) < 1e-10) ? 0.0 : (m_inputValue - m_inMin) / range;
    if (m_clamp) n = std::max(0.0, std::min(1.0, n));
    m_mappedValue = m_outMin + n * (m_outMax - m_outMin);
    emit mappedValueChanged();
    emit outputMapped(m_mappedValue);
    emit outputString(QString::number(m_mappedValue));
}

QJsonObject MapRange::saveState() const
{
    QJsonObject s;
    s["inMin"]  = m_inMin;
    s["inMax"]  = m_inMax;
    s["outMin"] = m_outMin;
    s["outMax"] = m_outMax;
    s["clamp"]  = m_clamp;
    return s;
}

void MapRange::loadState(const QJsonObject& s)
{
    if (s.contains("inMin"))  setInMin(s["inMin"].toDouble());
    if (s.contains("inMax"))  setInMax(s["inMax"].toDouble());
    if (s.contains("outMin")) setOutMin(s["outMin"].toDouble());
    if (s.contains("outMax")) setOutMax(s["outMax"].toDouble());
    if (s.contains("clamp"))  setClamp(s["clamp"].toBool());
}
