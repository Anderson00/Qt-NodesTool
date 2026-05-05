#include "stringformat.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(StringFormat, "String Format", "Formats values into a string using {A}, {B}, {C} placeholders", "logic", 4, 1)

StringFormat::StringFormat(QObject *parent) : Behaviours(parent)
{
    setWidth(260);
    setHeight(180);
    setContentHeight(180);
    setQmlBodyUrl("qrc:/behaviours/logic/StringFormat.qml");
    addInputOutputExclusion({"templateChanged()","resultChanged()","precisionChanged()"});
}

QMap<QString, QVariant> StringFormat::loadInfos() { return static_infos(); }

QMap<QString, QVariant> StringFormat::static_infos() {
    return {{"name","StringFormat"},{"type",Behaviours::Type::CPP},{"className","StringFormat"},{"desc","Formats values using template placeholders"},{"inputs_count","4"},{"outputs_count","1"}};
}

QString StringFormat::templateStr() const { return m_template; }
QString StringFormat::resultStr()   const { return m_result; }
int     StringFormat::precision()   const { return m_precision; }

void StringFormat::setA(double a) { m_a = a; compute(); }
void StringFormat::setB(double b) { m_b = b; compute(); }
void StringFormat::setC(double c) { m_c = c; compute(); }

void StringFormat::setTemplate(const QString& tmpl) {
    if(m_template!=tmpl){ m_template=tmpl; emit templateChanged(); compute(); }
}

void StringFormat::setPrecision(int digits) {
    digits = qBound(0, digits, 10);
    if(m_precision!=digits){ m_precision=digits; emit precisionChanged(); compute(); }
}

void StringFormat::compute() {
    QString r = m_template;
    r.replace("{A}", QString::number(m_a, 'f', m_precision));
    r.replace("{B}", QString::number(m_b, 'f', m_precision));
    r.replace("{C}", QString::number(m_c, 'f', m_precision));
    m_result = r;
    emit resultChanged();
    emit outputString(r);
}

QJsonObject StringFormat::saveState() const {
    return {{"template",m_template},{"precision",m_precision}};
}

void StringFormat::loadState(const QJsonObject& s) {
    if(s.contains("template"))  setTemplate(s["template"].toString());
    if(s.contains("precision")) setPrecision(s["precision"].toInt(2));
}
