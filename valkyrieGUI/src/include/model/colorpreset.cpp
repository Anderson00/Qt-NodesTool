#include "colorpreset.h"

ColorPreset::ColorPreset(QObject* parent) : QObject(parent) {}

ColorPreset* ColorPreset::create(const Data& data, QObject* parent) {
    auto* p = new ColorPreset(parent);
    p->m_data = data;
    return p;
}

const ColorPreset::Data& ColorPreset::data() const { return m_data; }

QString ColorPreset::name()               const { return m_data.name; }
QColor  ColorPreset::backgroundColor()    const { return m_data.backgroundColor; }
QColor  ColorPreset::surfaceColor()       const { return m_data.surfaceColor; }
QColor  ColorPreset::foregroundColor()    const { return m_data.foregroundColor; }
QColor  ColorPreset::borderColor()        const { return m_data.borderColor; }
QColor  ColorPreset::shadowColor()        const { return m_data.shadowColor; }
QColor  ColorPreset::primaryColor()       const { return m_data.primaryColor; }
QColor  ColorPreset::secondaryColor()     const { return m_data.secondaryColor; }
QColor  ColorPreset::accentColor()        const { return m_data.accentColor; }
QColor  ColorPreset::successColor()       const { return m_data.successColor; }
QColor  ColorPreset::warningColor()       const { return m_data.warningColor; }
QColor  ColorPreset::dangerColor()        const { return m_data.dangerColor; }
QColor  ColorPreset::textColor()          const { return m_data.textColor; }
QColor  ColorPreset::textSecondaryColor() const { return m_data.textSecondaryColor; }
QColor  ColorPreset::selectionColor()     const { return m_data.selectionColor; }
