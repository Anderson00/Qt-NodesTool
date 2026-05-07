#include "filter.h"
#include "behaviours/behaviourregistry.h"
#include <algorithm>
#include <numeric>

REGISTER_BEHAVIOUR(Filter, "Filter", "Signal filter: moving average, EMA, median, or low-pass", "math", 1, 1)

Filter::Filter(QObject *parent) : Behaviours(parent)
{
    this->setWidth(280);
    this->setHeight(400);
    this->setContentHeight(400);
    this->setQmlBodyUrl("qrc:/behaviours/math/Filter.qml");
    this->addInputOutputExclusion(QList<QString>({
        "filterModeChanged()",
        "windowSizeChanged()",
        "alphaChanged()",
        "rawValueChanged()",
        "filtValueChanged()",
        "internalSetInput(double)"
    }));
}

QMap<QString, QVariant> Filter::loadInfos()
{
    return Filter::static_infos();
}

QMap<QString, QVariant> Filter::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "Filter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "Filter"},
        {"desc",          "Moving average / EMA / Median / Low-pass filter"},
        {"inputs_count",  "1"},
        {"outputs_count", "1"}
    });
}

int    Filter::filterMode() const { return m_filterMode; }
int    Filter::windowSize() const { return m_windowSize; }
double Filter::alpha()      const { return m_alpha; }
double Filter::rawValue()   const { return m_rawValue; }
double Filter::filtValue()  const { return m_filtValue; }

void Filter::setInputValue(double rawVal)
{
    m_rawValue = rawVal;
    emit rawValueChanged();
    emit internalSetInput(rawVal);
    // C++ applies filter, QML shows preview via internalSetInput
    applyFilter(rawVal);
}

void Filter::applyFilter(double raw)
{
    double out = raw;
    switch (static_cast<FilterMode>(m_filterMode)) {
    case MovingAverage:
        m_buffer.append(raw);
        while (m_buffer.size() > m_windowSize) m_buffer.removeFirst();
        out = std::accumulate(m_buffer.begin(), m_buffer.end(), 0.0) / m_buffer.size();
        break;
    case EMA:
        out = m_filtValue + m_alpha * (raw - m_filtValue);
        break;
    case Median: {
        m_buffer.append(raw);
        while (m_buffer.size() > m_windowSize) m_buffer.removeFirst();
        QList<double> sorted = m_buffer;
        std::sort(sorted.begin(), sorted.end());
        int mid = sorted.size() / 2;
        out = (sorted.size() % 2 == 0) ? (sorted[mid - 1] + sorted[mid]) / 2.0 : sorted[mid];
        break;
    }
    case LowPass:
        out = m_filtValue + m_alpha * (raw - m_filtValue);
        break;
    }
    m_filtValue = out;
    emit filtValueChanged();
    emit outputFiltered(out);
    emit outputString(QString::number(out));
}

void Filter::setFilterMode(int mode)
{
    if (m_filterMode != mode) {
        m_filterMode = mode;
        m_buffer.clear();
        emit filterModeChanged();
    }
}

void Filter::setWindowSize(int size)
{
    if (m_windowSize != size) {
        m_windowSize = std::max(2, size);
        m_buffer.clear();
        emit windowSizeChanged();
    }
}

void Filter::setAlpha(double alpha)
{
    if (!qFuzzyCompare(m_alpha, alpha)) {
        m_alpha = std::max(0.001, std::min(1.0, alpha));
        emit alphaChanged();
    }
}

void Filter::resetFilter()
{
    m_buffer.clear();
    m_filtValue = m_rawValue;
    emit filtValueChanged();
}

void Filter::emitFiltered(double value)
{
    emit outputFiltered(value);
    emit outputString(QString::number(value));
}

QJsonObject Filter::saveState() const
{
    QJsonObject s;
    s["filterMode"] = m_filterMode;
    s["windowSize"] = m_windowSize;
    s["alpha"]      = m_alpha;
    return s;
}

void Filter::loadState(const QJsonObject& s)
{
    if (s.contains("filterMode")) setFilterMode(s["filterMode"].toInt());
    if (s.contains("windowSize")) setWindowSize(s["windowSize"].toInt());
    if (s.contains("alpha"))      setAlpha(s["alpha"].toDouble());
}
