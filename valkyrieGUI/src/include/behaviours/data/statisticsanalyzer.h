#ifndef STATISTICSANALYZER_H
#define STATISTICSANALYZER_H

#include <QObject>
#include <QJsonObject>
#include <QVector>
#include <behaviours/behaviours.h>

class StatisticsAnalyzer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(double mean       READ mean       NOTIFY statsChanged)
    Q_PROPERTY(double stddev     READ stddev     NOTIFY statsChanged)
    Q_PROPERTY(double minVal     READ minVal     NOTIFY statsChanged)
    Q_PROPERTY(double maxVal     READ maxVal     NOTIFY statsChanged)
    Q_PROPERTY(int    count      READ count      NOTIFY statsChanged)
    Q_PROPERTY(double p95        READ p95        NOTIFY statsChanged)
    Q_PROPERTY(double p99        READ p99        NOTIFY statsChanged)
    Q_PROPERTY(double median     READ median     NOTIFY statsChanged)
    Q_PROPERTY(int    windowSize READ windowSize WRITE setWindowSize NOTIFY windowSizeChanged)

public:
    explicit StatisticsAnalyzer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double mean()       const;
    double stddev()     const;
    double minVal()     const;
    double maxVal()     const;
    int    count()      const;
    double p95()        const;
    double p99()        const;
    double median()     const;
    int    windowSize() const;
    void   setWindowSize(int size);

public slots:
    void pushValue(double value);
    void reset();

signals:
    // Node outputs
    void statsUpdated(double mean, double stddev, double min, double max);
    void outlierDetected(double value);

    // Internal QML-only signals
    void internalStatsUpdated(double mean, double stddev, double min, double max);
    void internalOutlier(double value);

    // Property notifiers
    void statsChanged();
    void windowSizeChanged();

private:
    void recalculate();

    QVector<double> m_window;
    int    m_windowSize;
    double m_mean;
    double m_stddev;
    double m_minVal;
    double m_maxVal;
    double m_p95;
    double m_p99;
    double m_median;
};

#endif // STATISTICSANALYZER_H
