#ifndef HEATMAPVIEWER_H
#define HEATMAPVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>
#include <behaviours/behaviours.h>

class HeatMapViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     rows        READ rows        NOTIFY rowsChanged)
    Q_PROPERTY(int     cols        READ cols        NOTIFY colsChanged)
    Q_PROPERTY(double  minValue    READ minValue    NOTIFY minValueChanged)
    Q_PROPERTY(double  maxValue    READ maxValue    NOTIFY maxValueChanged)
    Q_PROPERTY(QString colorScheme READ colorScheme WRITE setColorScheme NOTIFY colorSchemeChanged)

public:
    explicit HeatMapViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int     rows()        const { return m_rows; }
    int     cols()        const { return m_cols; }
    double  minValue()    const { return m_minValue; }
    double  maxValue()    const { return m_maxValue; }
    QString colorScheme() const { return m_colorScheme; }
    void    setColorScheme(const QString& scheme);

    Q_INVOKABLE void notifyCellClick(int row, int col);

public slots:
    void setValue(int row, int col, double value);
    void setGrid(int rows, int cols);
    void setData(QVariantList flatData);
    void clear();

signals:
    // Node output
    void cellClicked(int row, int col, double value);

    // Internal QML bridge
    void internalSetValue(int row, int col, double val);
    void internalSetGrid(int rows, int cols);
    void internalSetData(QVariantList data);
    void internalClear();

    // Property notifiers
    void rowsChanged();
    void colsChanged();
    void minValueChanged();
    void maxValueChanged();
    void colorSchemeChanged();

private:
    void recalcMinMax();

    int              m_rows        = 8;
    int              m_cols        = 8;
    double           m_minValue    = 0.0;
    double           m_maxValue    = 1.0;
    QString          m_colorScheme = "heat";
    QVector<double>  m_data;
};

#endif // HEATMAPVIEWER_H
