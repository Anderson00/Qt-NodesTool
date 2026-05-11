#ifndef RANDOMGENERATORVIEWER_H
#define RANDOMGENERATORVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QTimer>
#include <behaviours/behaviours.h>

class RandomGeneratorViewer : public Behaviours
{
    Q_OBJECT

    // ── Mode ─────────────────────────────────────────────────────────────
    Q_PROPERTY(int mode READ mode WRITE setMode NOTIFY modeChanged)

    // ── Parameters ───────────────────────────────────────────────────────
    Q_PROPERTY(double rangeMin    READ rangeMin    WRITE setRangeMin    NOTIFY rangeMinChanged)
    Q_PROPERTY(double rangeMax    READ rangeMax    WRITE setRangeMax    NOTIFY rangeMaxChanged)
    Q_PROPERTY(double mean        READ mean        WRITE setMean        NOTIFY meanChanged)
    Q_PROPERTY(double stddev      READ stddev      WRITE setStddev      NOTIFY stddevChanged)
    Q_PROPERTY(int    diceSides   READ diceSides   WRITE setDiceSides   NOTIFY diceSidesChanged)
    Q_PROPERTY(int    diceCount   READ diceCount   WRITE setDiceCount   NOTIFY diceCountChanged)
    Q_PROPERTY(double probability READ probability WRITE setProbability NOTIFY probabilityChanged)
    Q_PROPERTY(int    precision   READ precision   WRITE setPrecision   NOTIFY precisionChanged)

    // ── Read-only outputs ────────────────────────────────────────────────
    Q_PROPERTY(double lastValue   READ lastValue   NOTIFY lastValueChanged)
    Q_PROPERTY(int    genCount    READ genCount     NOTIFY genCountChanged)
    Q_PROPERTY(double minSeen     READ minSeen     NOTIFY statsChanged)
    Q_PROPERTY(double maxSeen     READ maxSeen     NOTIFY statsChanged)
    Q_PROPERTY(double avgValue    READ avgValue    NOTIFY statsChanged)

public:
    enum Mode {
        UniformFloat = 0,   // min..max continuous
        UniformInt,         // min..max discrete integers
        Gaussian,           // normal distribution (mean, stddev)
        DiceRoll,           // NdS (count x sides)
        Boolean,            // true/false with probability
        Sequence            // cycling 0,1,2,...,max-1
    };
    Q_ENUM(Mode)

    explicit RandomGeneratorViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    // ── Accessors ────────────────────────────────────────────────────────
    int    mode()        const;
    double rangeMin()    const;
    double rangeMax()    const;
    double mean()        const;
    double stddev()      const;
    int    diceSides()   const;
    int    diceCount()   const;
    double probability() const;
    int    precision()   const;
    double lastValue()   const;
    int    genCount()    const;
    double minSeen()     const;
    double maxSeen()     const;
    double avgValue()    const;

public slots:
    // ── Core generation ──────────────────────────────────────────────────

    /// Generate a new value using current mode & parameters.
    double generate();

    /// Generate with explicit range (legacy compat, also connectable)
    double genNewNumber(double min, double max);

    /// Manually set the output value (bypasses RNG)
    void setValue(double value);

    /// Reset statistics (min/max/avg/count)
    void resetStats();

    // ── Parameter setters (connectable from other nodes) ─────────────────
    void setMode(int mode);
    void setRangeMin(double min);
    void setRangeMax(double max);
    void setMean(double mean);
    void setStddev(double stddev);
    void setDiceSides(int sides);
    void setDiceCount(int count);
    void setProbability(double p);
    void setPrecision(int digits);

signals:
    // ── Output signals (connectable to other nodes) ──────────────────────
    void outputValue(double value);
    void outputInt(int value);
    void outputBool(bool value);
    void outputString(QString value);

    // ── Property notifiers ───────────────────────────────────────────────
    void modeChanged();
    void rangeMinChanged();
    void rangeMaxChanged();
    void meanChanged();
    void stddevChanged();
    void diceSidesChanged();
    void diceCountChanged();
    void probabilityChanged();
    void precisionChanged();
    void lastValueChanged();
    void genCountChanged();
    void statsChanged();

    // Legacy compat
    void currentNumber(double value);

private slots:
    void flushStats();

private:
    void emitAll(double value);

    bool   m_statsDirty  = false;

    int    m_mode        = UniformFloat;
    double m_rangeMin    = 0.0;
    double m_rangeMax    = 100.0;
    double m_mean        = 50.0;
    double m_stddev      = 15.0;
    int    m_diceSides   = 6;
    int    m_diceCount   = 1;
    double m_probability = 0.5;
    int    m_precision   = 2;

    double m_lastValue   = 0.0;
    int    m_genCount    = 0;
    double m_minSeen     = std::numeric_limits<double>::max();
    double m_maxSeen     = std::numeric_limits<double>::lowest();
    double m_sumValues   = 0.0;

    int    m_seqCurrent  = 0;   // for Sequence mode
};

#endif // RANDOMGENERATORVIEWER_H
