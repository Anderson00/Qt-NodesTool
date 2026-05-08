#include "randomgeneratorviewer.h"
#include "behaviours/behaviourregistry.h"
#include <random>
#include <cmath>

REGISTER_BEHAVIOUR(RandomGeneratorViewer, "Random Generator", "Multi-mode random value generator with statistics", "common", 9, 4)

// Thread-local RNG so we don't re-seed on every call
static thread_local std::mt19937 s_rng(std::random_device{}());

RandomGeneratorViewer::RandomGeneratorViewer(QObject *parent)
{
    this->setWidth(260);
    this->setHeight(420);
    this->setContentHeight(420);
    this->setQmlBodyUrl("qrc:/behaviours/common/RandomGeneratorViewer.qml");

    // Exclude UI-only and internal signals/slots from the node I/O
    this->addInputOutputExclusion(QList<QString>({
        "genNewNumber(double,double)",
        "modeChanged()",
        "rangeMinChanged()",
        "rangeMaxChanged()",
        "meanChanged()",
        "stddevChanged()",
        "diceSidesChanged()",
        "diceCountChanged()",
        "probabilityChanged()",
        "precisionChanged()",
        "lastValueChanged()",
        "genCountChanged()",
        "statsChanged()",
        "currentNumber(double)"
    }));
}

QMap<QString, QVariant> RandomGeneratorViewer::loadInfos()
{
    return RandomGeneratorViewer::static_infos();
}

QMap<QString, QVariant> RandomGeneratorViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name", "RandomGeneratorViewer"},
        {"type", Behaviours::Type::CPP},
        {"className", "RandomGeneratorViewer"},
        {"desc", "Multi-mode random value generator with statistics"},
        {"inputs_count", "9"},
        {"outputs_count", "4"}
    });
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject RandomGeneratorViewer::saveState() const {
    QJsonObject s;
    s["mode"]        = m_mode;
    s["rangeMin"]    = m_rangeMin;
    s["rangeMax"]    = m_rangeMax;
    s["mean"]        = m_mean;
    s["stddev"]      = m_stddev;
    s["diceSides"]   = m_diceSides;
    s["diceCount"]   = m_diceCount;
    s["probability"] = m_probability;
    s["precision"]   = m_precision;
    return s;
}

void RandomGeneratorViewer::loadState(const QJsonObject& s) {
    if (s.contains("mode"))        setMode(s["mode"].toInt());
    if (s.contains("rangeMin"))    setRangeMin(s["rangeMin"].toDouble());
    if (s.contains("rangeMax"))    setRangeMax(s["rangeMax"].toDouble());
    if (s.contains("mean"))        setMean(s["mean"].toDouble());
    if (s.contains("stddev"))      setStddev(s["stddev"].toDouble());
    if (s.contains("diceSides"))   setDiceSides(s["diceSides"].toInt());
    if (s.contains("diceCount"))   setDiceCount(s["diceCount"].toInt());
    if (s.contains("probability")) setProbability(s["probability"].toDouble());
    if (s.contains("precision"))   setPrecision(s["precision"].toInt());
}

// ── Accessors ────────────────────────────────────────────────────────────────

int    RandomGeneratorViewer::mode()        const { return m_mode; }
double RandomGeneratorViewer::rangeMin()    const { return m_rangeMin; }
double RandomGeneratorViewer::rangeMax()    const { return m_rangeMax; }
double RandomGeneratorViewer::mean()        const { return m_mean; }
double RandomGeneratorViewer::stddev()      const { return m_stddev; }
int    RandomGeneratorViewer::diceSides()   const { return m_diceSides; }
int    RandomGeneratorViewer::diceCount()   const { return m_diceCount; }
double RandomGeneratorViewer::probability() const { return m_probability; }
int    RandomGeneratorViewer::precision()   const { return m_precision; }
double RandomGeneratorViewer::lastValue()   const { return m_lastValue; }
int    RandomGeneratorViewer::genCount()    const { return m_genCount; }
double RandomGeneratorViewer::minSeen()     const { return m_genCount > 0 ? m_minSeen : 0.0; }
double RandomGeneratorViewer::maxSeen()     const { return m_genCount > 0 ? m_maxSeen : 0.0; }
double RandomGeneratorViewer::avgValue()    const { return m_genCount > 0 ? m_sumValues / m_genCount : 0.0; }

// ── Setters ──────────────────────────────────────────────────────────────────

void RandomGeneratorViewer::setMode(int mode) {
    if (m_mode != mode) { m_mode = mode; emit modeChanged(); }
}
void RandomGeneratorViewer::setRangeMin(double min) {
    if (!qFuzzyCompare(m_rangeMin, min)) { m_rangeMin = min; emit rangeMinChanged(); }
}
void RandomGeneratorViewer::setRangeMax(double max) {
    if (!qFuzzyCompare(m_rangeMax, max)) { m_rangeMax = max; emit rangeMaxChanged(); }
}
void RandomGeneratorViewer::setMean(double mean) {
    if (!qFuzzyCompare(m_mean, mean)) { m_mean = mean; emit meanChanged(); }
}
void RandomGeneratorViewer::setStddev(double stddev) {
    if (!qFuzzyCompare(m_stddev, stddev)) { m_stddev = stddev; emit stddevChanged(); }
}
void RandomGeneratorViewer::setDiceSides(int sides) {
    if (m_diceSides != sides) { m_diceSides = qMax(1, sides); emit diceSidesChanged(); }
}
void RandomGeneratorViewer::setDiceCount(int count) {
    if (m_diceCount != count) { m_diceCount = qMax(1, count); emit diceCountChanged(); }
}
void RandomGeneratorViewer::setProbability(double p) {
    p = qBound(0.0, p, 1.0);
    if (!qFuzzyCompare(m_probability, p)) { m_probability = p; emit probabilityChanged(); }
}
void RandomGeneratorViewer::setPrecision(int digits) {
    digits = qBound(0, digits, 10);
    if (m_precision != digits) { m_precision = digits; emit precisionChanged(); }
}

// ── Core generation ──────────────────────────────────────────────────────────

void RandomGeneratorViewer::emitAll(double value) {
    m_lastValue = value;
    m_genCount++;
    m_sumValues += value;
    if (value < m_minSeen) m_minSeen = value;
    if (value > m_maxSeen) m_maxSeen = value;

    emit lastValueChanged();
    emit genCountChanged();
    emit statsChanged();
    emit currentNumber(value);
    emit outputValue(value);
    emit outputInt(static_cast<int>(std::round(value)));
    emit outputBool(value != 0.0);
    emit outputString(QString::number(value, 'f', m_precision));
}

double RandomGeneratorViewer::generate() {
    double value = 0.0;

    switch (static_cast<Mode>(m_mode)) {
    case UniformFloat: {
        std::uniform_real_distribution<double> dist(m_rangeMin, m_rangeMax);
        value = dist(s_rng);
        // Apply precision rounding
        double factor = std::pow(10.0, m_precision);
        value = std::round(value * factor) / factor;
        break;
    }
    case UniformInt: {
        int imin = static_cast<int>(std::ceil(m_rangeMin));
        int imax = static_cast<int>(std::floor(m_rangeMax));
        if (imin > imax) imax = imin;
        std::uniform_int_distribution<int> dist(imin, imax);
        value = dist(s_rng);
        break;
    }
    case Gaussian: {
        std::normal_distribution<double> dist(m_mean, m_stddev);
        value = dist(s_rng);
        // Optionally clamp to range
        double actualMin = qMin(m_rangeMin, m_rangeMax);
        double actualMax = qMax(m_rangeMin, m_rangeMax);
        value = qBound(actualMin, value, actualMax);
        double factor = std::pow(10.0, m_precision);
        value = std::round(value * factor) / factor;
        break;
    }
    case DiceRoll: {
        int total = 0;
        std::uniform_int_distribution<int> dist(1, m_diceSides);
        for (int i = 0; i < m_diceCount; ++i)
            total += dist(s_rng);
        value = total;
        break;
    }
    case Boolean: {
        std::bernoulli_distribution dist(m_probability);
        value = dist(s_rng) ? 1.0 : 0.0;
        break;
    }
    case Sequence: {
        int rangeSize = static_cast<int>(m_rangeMax - m_rangeMin) + 1;
        if (rangeSize <= 0) rangeSize = 1;
        value = m_rangeMin + (m_seqCurrent % rangeSize);
        m_seqCurrent++;
        break;
    }
    }

    emitAll(value);
    return value;
}

double RandomGeneratorViewer::genNewNumber(double min, double max) {
    m_rangeMin = min;
    m_rangeMax = max;
    return generate();
}

void RandomGeneratorViewer::setValue(double value) {
    emitAll(value);
}

void RandomGeneratorViewer::resetStats() {
    m_genCount  = 0;
    m_sumValues = 0.0;
    m_minSeen   = std::numeric_limits<double>::max();
    m_maxSeen   = std::numeric_limits<double>::lowest();
    m_seqCurrent = 0;
    emit genCountChanged();
    emit statsChanged();
}
