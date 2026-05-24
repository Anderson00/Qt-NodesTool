#ifndef PIECHARTVIEWER_H
#define PIECHARTVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class PieChartViewer : public Behaviours
{
    Q_OBJECT

public:
    explicit PieChartViewer(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

public slots:
    void addSlice(const QString& label, double value);
    void setSliceValue(int index, double value);
    void clearSlices();
    void removeSlice(int index);
    // Universal input — [label, value] or [value]
    void setInputData(const QVariantList& data);

signals:
    void internalAddSlice(const QString& label, double value);
    void internalSetSliceValue(int index, double value);
    void internalClearSlices();
    void internalRemoveSlice(int index);
};

#endif // PIECHARTVIEWER_H
