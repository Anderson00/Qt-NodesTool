#include "colorpreset.h"
#include <QUuid>
#include <QJsonObject>

ColorPreset::ColorPreset(QObject* parent) : QObject(parent) {}

ColorPreset* ColorPreset::create(const Data& data, QObject* parent) {
    auto* p    = new ColorPreset(parent);
    p->m_data  = data;
    if (p->m_data.id.isEmpty())
        p->m_data.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    return p;
}

ColorPreset* ColorPreset::fromJson(const QJsonObject& obj, QObject* parent) {
    Data d;
    d.id      = obj["id"].toString();
    d.name    = obj["name"].toString();
    d.builtin = false; // persisted presets are always user-created

    if (d.id.isEmpty())
        d.id = QUuid::createUuid().toString(QUuid::WithoutBraces);

    const QJsonObject c = obj["colors"].toObject();
    auto col = [&](const char* key) { return QColor(c[key].toString()); };

    d.backgroundColor    = col("backgroundColor");
    d.surfaceColor       = col("surfaceColor");
    d.foregroundColor    = col("foregroundColor");
    d.borderColor        = col("borderColor");
    d.shadowColor        = col("shadowColor");
    d.primaryColor       = col("primaryColor");
    d.secondaryColor     = col("secondaryColor");
    d.accentColor        = col("accentColor");
    d.successColor       = col("successColor");
    d.warningColor       = col("warningColor");
    d.dangerColor        = col("dangerColor");
    d.textColor          = col("textColor");
    d.textSecondaryColor = col("textSecondaryColor");
    d.selectionColor     = col("selectionColor");

    return create(d, parent);
}

QJsonObject ColorPreset::toJson() const {
    auto hex = [](const QColor& c) {
        // HexArgb preserves alpha (important for shadowColor, selectionColor)
        return c.name(QColor::HexArgb);
    };

    QJsonObject colors;
    colors["backgroundColor"]    = hex(m_data.backgroundColor);
    colors["surfaceColor"]       = hex(m_data.surfaceColor);
    colors["foregroundColor"]    = hex(m_data.foregroundColor);
    colors["borderColor"]        = hex(m_data.borderColor);
    colors["shadowColor"]        = hex(m_data.shadowColor);
    colors["primaryColor"]       = hex(m_data.primaryColor);
    colors["secondaryColor"]     = hex(m_data.secondaryColor);
    colors["accentColor"]        = hex(m_data.accentColor);
    colors["successColor"]       = hex(m_data.successColor);
    colors["warningColor"]       = hex(m_data.warningColor);
    colors["dangerColor"]        = hex(m_data.dangerColor);
    colors["textColor"]          = hex(m_data.textColor);
    colors["textSecondaryColor"] = hex(m_data.textSecondaryColor);
    colors["selectionColor"]     = hex(m_data.selectionColor);

    QJsonObject obj;
    obj["id"]     = m_data.id;
    obj["name"]   = m_data.name;
    obj["colors"] = colors;
    return obj;
}

// --- Identity ---
QString ColorPreset::id()      const { return m_data.id; }
bool    ColorPreset::builtin() const { return m_data.builtin; }
QString ColorPreset::name()    const { return m_data.name; }

void ColorPreset::setName(const QString& name) {
    if (m_data.name != name) {
        m_data.name = name;
        emit nameChanged();
    }
}

// --- Colors ---
QColor ColorPreset::backgroundColor()    const { return m_data.backgroundColor; }
QColor ColorPreset::surfaceColor()       const { return m_data.surfaceColor; }
QColor ColorPreset::foregroundColor()    const { return m_data.foregroundColor; }
QColor ColorPreset::borderColor()        const { return m_data.borderColor; }
QColor ColorPreset::shadowColor()        const { return m_data.shadowColor; }
QColor ColorPreset::primaryColor()       const { return m_data.primaryColor; }
QColor ColorPreset::secondaryColor()     const { return m_data.secondaryColor; }
QColor ColorPreset::accentColor()        const { return m_data.accentColor; }
QColor ColorPreset::successColor()       const { return m_data.successColor; }
QColor ColorPreset::warningColor()       const { return m_data.warningColor; }
QColor ColorPreset::dangerColor()        const { return m_data.dangerColor; }
QColor ColorPreset::textColor()          const { return m_data.textColor; }
QColor ColorPreset::textSecondaryColor() const { return m_data.textSecondaryColor; }
QColor ColorPreset::selectionColor()     const { return m_data.selectionColor; }

const ColorPreset::Data& ColorPreset::data() const { return m_data; }
