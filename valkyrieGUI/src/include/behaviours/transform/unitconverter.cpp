#include "unitconverter.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(UnitConverter, "Unit Converter", "Convert between length, mass, temperature, and speed units", "transform", 2, 1)

// ---------------------------------------------------------------------------
// Static factor tables (value = metres / kilograms / (m/s) per 1 unit)
// ---------------------------------------------------------------------------

const QMap<QString, double> &UnitConverter::lengthFactors()
{
    static const QMap<QString, double> t = {
        {"m",   1.0},
        {"km",  1000.0},
        {"cm",  0.01},
        {"mm",  0.001},
        {"ft",  0.3048},
        {"in",  0.0254},
        {"mi",  1609.344},
        {"yd",  0.9144}
    };
    return t;
}

const QMap<QString, double> &UnitConverter::massFactors()
{
    static const QMap<QString, double> t = {
        {"kg", 1.0},
        {"g",  0.001},
        {"lb", 0.453592},
        {"oz", 0.028350},
        {"t",  1000.0}
    };
    return t;
}

const QMap<QString, double> &UnitConverter::speedFactors()
{
    static const QMap<QString, double> t = {
        {"m/s",  1.0},
        {"km/h", 1.0 / 3.6},
        {"mph",  0.44704},
        {"knot", 0.514444}
    };
    return t;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QString UnitConverter::detectCategory(const QString &unit)
{
    if (lengthFactors().contains(unit))  return "length";
    if (massFactors().contains(unit))    return "mass";
    if (speedFactors().contains(unit))   return "speed";
    if (unit == "C" || unit == "F" || unit == "K") return "temperature";
    return "length";
}

double UnitConverter::toBase(const QString &unit, double value)
{
    if (unit == "C") return value + 273.15;
    if (unit == "F") return (value + 459.67) * 5.0 / 9.0;
    if (unit == "K") return value;

    if (lengthFactors().contains(unit)) return value * lengthFactors().value(unit);
    if (massFactors().contains(unit))   return value * massFactors().value(unit);
    if (speedFactors().contains(unit))  return value * speedFactors().value(unit);
    return value;
}

double UnitConverter::fromBase(const QString &unit, double baseValue)
{
    if (unit == "K") return baseValue;
    if (unit == "C") return baseValue - 273.15;
    if (unit == "F") return baseValue * 9.0 / 5.0 - 459.67;

    if (lengthFactors().contains(unit)) return baseValue / lengthFactors().value(unit);
    if (massFactors().contains(unit))   return baseValue / massFactors().value(unit);
    if (speedFactors().contains(unit))  return baseValue / speedFactors().value(unit);
    return baseValue;
}

// ---------------------------------------------------------------------------
// Constructor / registration
// ---------------------------------------------------------------------------

UnitConverter::UnitConverter(QObject *parent) : Behaviours(parent)
{
    setWidth(300);
    setHeight(240);
    setContentHeight(240);
    setQmlBodyUrl("qrc:/behaviours/transform/UnitConverter.qml");
    addInputOutputExclusion(QList<QString>({
        "internalResult(double,QString)",
        "internalConversionChanged(QString,QString,QString)",
        "fromUnitChanged()",
        "toUnitChanged()",
        "categoryChanged()"
    }));
}

QMap<QString, QVariant> UnitConverter::loadInfos() { return UnitConverter::static_infos(); }

QMap<QString, QVariant> UnitConverter::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "UnitConverter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "UnitConverter"},
        {"desc",          "Convert between length, mass, temperature, and speed units"},
        {"inputs_count",  "2"},
        {"outputs_count", "1"}
    });
}

// ---------------------------------------------------------------------------
// Property accessors
// ---------------------------------------------------------------------------

QString UnitConverter::fromUnit() const { return m_fromUnit; }
QString UnitConverter::toUnit()   const { return m_toUnit; }
QString UnitConverter::category() const { return m_category; }

void UnitConverter::setFromUnit(QString unit)
{
    if (m_fromUnit == unit) return;
    m_fromUnit = unit;
    emit fromUnitChanged();
}

void UnitConverter::setToUnit(QString unit)
{
    if (m_toUnit == unit) return;
    m_toUnit = unit;
    emit toUnitChanged();
}

void UnitConverter::setCategory(QString cat)
{
    if (m_category == cat) return;
    m_category = cat;
    emit categoryChanged();
}

// ---------------------------------------------------------------------------
// Q_INVOKABLE
// ---------------------------------------------------------------------------

QStringList UnitConverter::unitsForCategory(QString cat) const
{
    if (cat == "length")      return lengthFactors().keys();
    if (cat == "mass")        return massFactors().keys();
    if (cat == "speed")       return speedFactors().keys();
    if (cat == "temperature") return QStringList({"C", "F", "K"});
    return QStringList();
}

// ---------------------------------------------------------------------------
// Slots
// ---------------------------------------------------------------------------

void UnitConverter::convert(double value)
{
    double base      = toBase(m_fromUnit, value);
    double converted = fromBase(m_toUnit, base);
    emit result(converted, m_toUnit);
    emit internalResult(converted, m_toUnit);
}

void UnitConverter::setConversion(QString fromUnit, QString toUnit)
{
    QString cat = detectCategory(fromUnit);
    setFromUnit(fromUnit);
    setToUnit(toUnit);
    setCategory(cat);
    emit internalConversionChanged(fromUnit, toUnit, cat);
}

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

QJsonObject UnitConverter::saveState() const
{
    return {{"fromUnit", m_fromUnit}, {"toUnit", m_toUnit}, {"category", m_category}};
}

void UnitConverter::loadState(const QJsonObject &state)
{
    if (state.contains("category")) setCategory(state["category"].toString());
    if (state.contains("fromUnit")) setFromUnit(state["fromUnit"].toString());
    if (state.contains("toUnit"))   setToUnit(state["toUnit"].toString());
}
