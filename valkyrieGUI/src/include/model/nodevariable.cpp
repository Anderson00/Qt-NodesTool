#include "nodevariable.h"
#include <QUuid>
#include <QJsonDocument>
#include <QJsonArray>
#include <QPointF>

NodeVariable* NodeVariable::create(const Data& d, QObject* parent) {
    Data data = d;
    if (data.id.isEmpty())
        data.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    return new NodeVariable(data, parent);
}

NodeVariable* NodeVariable::fromJson(const QJsonObject& obj, QObject* parent) {
    Data d;
    d.id       = obj["id"].toString();
    d.name     = obj["name"].toString();
    d.type     = obj["type"].toString();
    d.value    = obj["value"].toString();
    d.readOnly = obj["readOnly"].toBool();
    if (d.id.isEmpty() || d.name.isEmpty() || d.type.isEmpty())
        return nullptr;
    return new NodeVariable(d, parent);
}

NodeVariable::NodeVariable(const Data& d, QObject* parent)
    : QObject(parent)
    , m_id(d.id)
    , m_name(d.name)
    , m_type(d.type)
    , m_value(d.value)
    , m_readOnly(d.readOnly)
{}

void NodeVariable::setName(const QString& v) {
    if (m_name == v) return;
    m_name = v;
    emit nameChanged();
}

void NodeVariable::setValue(const QString& v) {
    if (m_readOnly || m_value == v) return;
    m_value = v;
    emit valueChanged();
}

void NodeVariable::setReadOnly(bool v) {
    if (m_readOnly == v) return;
    m_readOnly = v;
    emit readOnlyChanged();
}

QJsonObject NodeVariable::toJson() const {
    QJsonObject obj;
    obj["id"]       = m_id;
    obj["name"]     = m_name;
    obj["type"]     = m_type;
    obj["value"]    = m_value;
    obj["readOnly"] = m_readOnly;
    return obj;
}

QVariant NodeVariable::parsedValue() const {
    if (m_type == "NUMBER")  return QVariant(m_value.toDouble());
    if (m_type == "INT")     return QVariant(m_value.toInt());
    if (m_type == "BOOLEAN") return QVariant(m_value == "true");
    if (m_type == "ARRAY") {
        QList<double> list;
        const auto parts = m_value.split(',', Qt::SkipEmptyParts);
        for (const auto& p : parts) list.append(p.trimmed().toDouble());
        return QVariant::fromValue(list);
    }
    if (m_type == "VEC2") {
        const auto parts = m_value.split(',');
        double x = parts.size() > 0 ? parts[0].trimmed().toDouble() : 0.0;
        double y = parts.size() > 1 ? parts[1].trimmed().toDouble() : 0.0;
        return QVariant::fromValue(QPointF(x, y));
    }
    if (m_type == "VEC3") {
        const auto parts = m_value.split(',');
        QList<double> vec;
        for (int i = 0; i < 3; i++)
            vec.append(parts.size() > i ? parts[i].trimmed().toDouble() : 0.0);
        return QVariant::fromValue(vec);
    }
    // STRING, COLOR, LIST, DICT — return raw string (caller parses JSON if needed)
    return QVariant(m_value);
}

bool NodeVariable::isNumericType() const {
    return m_type == "NUMBER" || m_type == "INT"
        || m_type == "VEC2"   || m_type == "VEC3";
}

bool NodeVariable::isContainerType() const {
    return m_type == "ARRAY" || m_type == "LIST" || m_type == "DICT";
}
