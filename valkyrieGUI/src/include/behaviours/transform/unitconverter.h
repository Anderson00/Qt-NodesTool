#ifndef UNITCONVERTER_H
#define UNITCONVERTER_H

#include <QObject>
#include <QJsonObject>
#include <QMap>
#include <QStringList>
#include <behaviours/behaviours.h>

class UnitConverter : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString fromUnit  READ fromUnit  WRITE setFromUnit  NOTIFY fromUnitChanged)
    Q_PROPERTY(QString toUnit    READ toUnit    WRITE setToUnit    NOTIFY toUnitChanged)
    Q_PROPERTY(QString category  READ category  WRITE setCategory  NOTIFY categoryChanged)

public:
    explicit UnitConverter(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject &state) override;

    QString fromUnit() const;
    QString toUnit()   const;
    QString category() const;

    void setFromUnit(QString unit);
    void setToUnit(QString unit);
    void setCategory(QString cat);

    Q_INVOKABLE QStringList unitsForCategory(QString cat) const;

public slots:
    void convert(double value);
    void setConversion(QString fromUnit, QString toUnit);

signals:
    // Node output
    void result(double converted, QString unit);

    // Internal QML-only signals
    void internalResult(double converted, QString unit);
    void internalConversionChanged(QString from, QString to, QString category);

    // Property notifiers
    void fromUnitChanged();
    void toUnitChanged();
    void categoryChanged();

private:
    QString m_fromUnit = "m";
    QString m_toUnit   = "km";
    QString m_category = "length";

    static QString detectCategory(const QString &unit);

    // Convert value in fromUnit to base unit
    static double toBase(const QString &unit, double value);
    // Convert base-unit value to toUnit
    static double fromBase(const QString &unit, double value);

    static const QMap<QString, double> &lengthFactors();
    static const QMap<QString, double> &massFactors();
    static const QMap<QString, double> &speedFactors();
};

#endif // UNITCONVERTER_H
