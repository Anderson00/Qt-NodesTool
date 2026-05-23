#ifndef BARCHARTVIEWER_H
#define BARCHARTVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class BarChartViewer : public Behaviours
{
    Q_OBJECT

public:
    explicit BarChartViewer(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

public slots:
    void appendToSet(int setIndex, double value);
    void addSet(const QString& name);
    void clearChart();
    // Universal input — [setIndex, value] or [value] (uses index 0)
    void setInputData(const QVariantList& data);

signals:
    void internalAppendToSet(int setIndex, double value);
    void internalAddSet(const QString& name);
    void internalClearChart();
};

#endif // BARCHARTVIEWER_H
