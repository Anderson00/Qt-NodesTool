#ifndef RADARCHARTVIEWER_H
#define RADARCHARTVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QStringList>
#include <QList>
#include <QPair>
#include <QVariantList>
#include <behaviours/behaviours.h>

class RadarChartViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int    seriesCount  READ seriesCount  NOTIFY seriesCountChanged)
    Q_PROPERTY(double maxValue     READ maxValue     NOTIFY maxValueChanged)
    Q_PROPERTY(bool   showGrid     READ showGrid     WRITE setShowGrid     NOTIFY showGridChanged)
    Q_PROPERTY(double fillOpacity  READ fillOpacity  WRITE setFillOpacity  NOTIFY fillOpacityChanged)

public:
    explicit RadarChartViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int    seriesCount() const { return m_series.size(); }
    double maxValue()    const { return m_maxValue; }
    bool   showGrid()    const { return m_showGrid; }
    double fillOpacity() const { return m_fillOpacity; }

    void setShowGrid(bool v);
    void setFillOpacity(double v);

    Q_INVOKABLE QVariantList getSeriesData()  const;
    Q_INVOKABLE QStringList  getLabels()      const;

public slots:
    void setValues(QVariantList values);
    void setLabels(QStringList labels);
    void addSeries(QString name, QVariantList values);
    void clear();

signals:
    // Node output
    void seriesClicked(QString name);

    // Internal QML bridge
    void internalDataChanged();
    void internalClear();

    // Property notifiers
    void seriesCountChanged();
    void maxValueChanged();
    void showGridChanged();
    void fillOpacityChanged();

private:
    void recalcMax();

    QList<QPair<QString, QVariantList>> m_series;
    QStringList                         m_labels;
    double                              m_maxValue    = 1.0;
    bool                                m_showGrid    = true;
    double                              m_fillOpacity = 0.3;
};

#endif // RADARCHARTVIEWER_H
