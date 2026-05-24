#include "statisticsanalyzer.h"
#include "behaviours/behaviourregistry.h"

#include <algorithm>
#include <cmath>

REGISTER_BEHAVIOUR(StatisticsAnalyzer, "Statistics Analyzer", "Real-time descriptive statistics with outlier detection", "data", 2, 2)

StatisticsAnalyzer::StatisticsAnalyzer(QObject *parent)
    : Behaviours(parent)
    , m_windowSize(100)
    , m_mean(0.0)
    , m_stddev(0.0)
    , m_minVal(0.0)
    , m_maxVal(0.0)
    , m_p95(0.0)
    , m_p99(0.0)
    , m_median(0.0)
{
    this->setWidth(320);
    this->setHeight(300);
    this->setContentHeight(300);
    this->setQmlBodyUrl("qrc:/behaviours/data/StatisticsAnalyzer.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalStatsUpdated(double,double,double,double)",
        "internalOutlier(double)"
    }));
}

QMap<QString, QVariant> StatisticsAnalyzer::loadInfos()
{
    return StatisticsAnalyzer::static_infos();
}

QMap<QString, QVariant> StatisticsAnalyzer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "StatisticsAnalyzer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "StatisticsAnalyzer"},
        {"desc",          "Real-time descriptive statistics with outlier detection"},
        {"inputs_count",  "2"},
        {"outputs_count", "2"}
    });
}

double StatisticsAnalyzer::mean()       const { return m_mean;       }
double StatisticsAnalyzer::stddev()     const { return m_stddev;     }
double StatisticsAnalyzer::minVal()     const { return m_minVal;     }
double StatisticsAnalyzer::maxVal()     const { return m_maxVal;     }
int    StatisticsAnalyzer::count()      const { return m_window.size(); }
double StatisticsAnalyzer::p95()        const { return m_p95;        }
double StatisticsAnalyzer::p99()        const { return m_p99;        }
double StatisticsAnalyzer::median()     const { return m_median;     }
int    StatisticsAnalyzer::windowSize() const { return m_windowSize; }

void StatisticsAnalyzer::setWindowSize(int size)
{
    if (size < 1) size = 1;
    if (m_windowSize != size) {
        m_windowSize = size;
        // Trim window if needed
        while (m_window.size() > m_windowSize)
            m_window.removeFirst();
        recalculate();
        emit windowSizeChanged();
    }
}

void StatisticsAnalyzer::pushValue(double value)
{
    // Append, trim to window size
    m_window.append(value);
    if (m_window.size() > m_windowSize)
        m_window.removeFirst();

    recalculate();

    // Outlier detection: |v - mean| > 2 * stddev, only if count >= 10
    if (m_window.size() >= 10 && m_stddev > 0.0) {
        if (std::abs(value - m_mean) > 2.0 * m_stddev) {
            emit outlierDetected(value);
            emit internalOutlier(value);
        }
    }

    emit statsUpdated(m_mean, m_stddev, m_minVal, m_maxVal);
    emit internalStatsUpdated(m_mean, m_stddev, m_minVal, m_maxVal);
    emit statsChanged();
}

void StatisticsAnalyzer::reset()
{
    m_window.clear();
    m_mean   = 0.0;
    m_stddev = 0.0;
    m_minVal = 0.0;
    m_maxVal = 0.0;
    m_p95    = 0.0;
    m_p99    = 0.0;
    m_median = 0.0;
    emit statsChanged();
}

void StatisticsAnalyzer::recalculate()
{
    int n = m_window.size();
    if (n == 0) {
        m_mean = m_stddev = m_minVal = m_maxVal = m_p95 = m_p99 = m_median = 0.0;
        return;
    }

    // Mean
    double sum = 0.0;
    for (double v : m_window) sum += v;
    m_mean = sum / n;

    // Stddev
    double sumSq = 0.0;
    for (double v : m_window) sumSq += v * v;
    double variance = (sumSq / n) - (m_mean * m_mean);
    m_stddev = variance > 0.0 ? std::sqrt(variance) : 0.0;

    // Sorted copy for min/max/percentiles/median
    QVector<double> sorted = m_window;
    std::sort(sorted.begin(), sorted.end());

    m_minVal = sorted.first();
    m_maxVal = sorted.last();

    // Median
    if (n % 2 == 0) {
        m_median = (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0;
    } else {
        m_median = sorted[n / 2];
    }

    // Percentiles (nearest rank)
    auto percentile = [&](double pct) -> double {
        int idx = static_cast<int>(std::ceil(pct / 100.0 * n)) - 1;
        if (idx < 0) idx = 0;
        if (idx >= n) idx = n - 1;
        return sorted[idx];
    };

    m_p95 = percentile(95.0);
    m_p99 = percentile(99.0);
}

QJsonObject StatisticsAnalyzer::saveState() const
{
    QJsonObject state;
    state["windowSize"] = m_windowSize;
    return state;
}

void StatisticsAnalyzer::loadState(const QJsonObject& state)
{
    if (state.contains("windowSize"))
        setWindowSize(state["windowSize"].toInt(100));
}
