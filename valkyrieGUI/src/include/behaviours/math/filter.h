#ifndef FILTER_H
#define FILTER_H

#include <QObject>
#include <QJsonObject>
#include <QList>
#include <behaviours/behaviours.h>

class Filter : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int    filterMode READ filterMode NOTIFY filterModeChanged)
    Q_PROPERTY(int    windowSize READ windowSize NOTIFY windowSizeChanged)
    Q_PROPERTY(double alpha      READ alpha      NOTIFY alphaChanged)
    Q_PROPERTY(double rawValue   READ rawValue   NOTIFY rawValueChanged)
    Q_PROPERTY(double filtValue  READ filtValue  NOTIFY filtValueChanged)

public:
    enum FilterMode { MovingAverage = 0, EMA, Median, LowPass };
    Q_ENUM(FilterMode)

    explicit Filter(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int    filterMode() const;
    int    windowSize() const;
    double alpha()      const;
    double rawValue()   const;
    double filtValue()  const;

public slots:
    void setInputValue(double rawVal);
    void setFilterMode(int mode);
    void setWindowSize(int size);
    void setAlpha(double alpha);
    void resetFilter();

public:
    Q_INVOKABLE void emitFiltered(double value);

signals:
    void internalSetInput(double rawValue);

    void outputFiltered(double value);
    void outputString(QString value);

    void filterModeChanged();
    void windowSizeChanged();
    void alphaChanged();
    void rawValueChanged();
    void filtValueChanged();

private:
    void applyFilter(double raw);

    int         m_filterMode = MovingAverage;
    int         m_windowSize = 5;
    double      m_alpha      = 0.1;
    double      m_rawValue   = 0.0;
    double      m_filtValue  = 0.0;
    QList<double> m_buffer;
};

#endif // FILTER_H
