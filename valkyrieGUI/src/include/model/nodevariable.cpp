#include "nodevariable.h"
#include <QUuid>

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
