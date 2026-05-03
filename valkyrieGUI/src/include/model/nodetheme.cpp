#include "nodetheme.h"
#include "thememanager.h"

NodeTheme::NodeTheme(QObject* parent)
    : QObject(parent)
{
    connectToGlobal();
}

void NodeTheme::connectToGlobal() {
    connect(ThemeManager::instance(), &ThemeManager::themeChanged,
            this, [this]() {
                if (m_useGlobalTheme)
                    emit changed();
            });
}

// --- Getters (fall back to global when not overridden) ---

bool NodeTheme::useGlobalTheme() const { return m_useGlobalTheme; }

QColor NodeTheme::headerColor() const {
    if (!m_useGlobalTheme || m_overriddenColors.contains("headerColor"))
        return m_headerColor;
    return ThemeManager::instance()->primaryColor();
}

QColor NodeTheme::bodyColor() const {
    if (!m_useGlobalTheme || m_overriddenColors.contains("bodyColor"))
        return m_bodyColor;
    return ThemeManager::instance()->surfaceColor();
}

QColor NodeTheme::borderColor() const {
    if (!m_useGlobalTheme || m_overriddenColors.contains("borderColor"))
        return m_borderColor;
    return ThemeManager::instance()->borderColor();
}

QColor NodeTheme::portInputColor() const {
    if (!m_useGlobalTheme || m_overriddenColors.contains("portInputColor"))
        return m_portInputColor;
    return ThemeManager::instance()->accentColor();
}

QColor NodeTheme::portOutputColor() const {
    if (!m_useGlobalTheme || m_overriddenColors.contains("portOutputColor"))
        return m_portOutputColor;
    return ThemeManager::instance()->successColor();
}

QColor NodeTheme::titleColor() const {
    if (!m_useGlobalTheme || m_overriddenColors.contains("titleColor"))
        return m_titleColor;
    return ThemeManager::instance()->textColor();
}

// --- Setters ---

void NodeTheme::setUseGlobalTheme(bool use) {
    if (m_useGlobalTheme != use) {
        m_useGlobalTheme = use;
        emit changed();
    }
}

#define OVERRIDE_COLOR(key, member) \
    m_overriddenColors.insert(key); \
    if (member != color) { member = color; emit changed(); }

void NodeTheme::setHeaderColor(const QColor& color)     { OVERRIDE_COLOR("headerColor",     m_headerColor) }
void NodeTheme::setBodyColor(const QColor& color)       { OVERRIDE_COLOR("bodyColor",       m_bodyColor) }
void NodeTheme::setBorderColor(const QColor& color)     { OVERRIDE_COLOR("borderColor",     m_borderColor) }
void NodeTheme::setPortInputColor(const QColor& color)  { OVERRIDE_COLOR("portInputColor",  m_portInputColor) }
void NodeTheme::setPortOutputColor(const QColor& color) { OVERRIDE_COLOR("portOutputColor", m_portOutputColor) }
void NodeTheme::setTitleColor(const QColor& color)      { OVERRIDE_COLOR("titleColor",      m_titleColor) }

#undef OVERRIDE_COLOR

// --- Override management ---

void NodeTheme::resetColor(const QString& colorName) {
    if (m_overriddenColors.remove(colorName))
        emit changed();
}

void NodeTheme::resetAllColors() {
    if (!m_overriddenColors.isEmpty()) {
        m_overriddenColors.clear();
        emit changed();
    }
}

bool NodeTheme::isOverridden(const QString& colorName) const {
    return m_overriddenColors.contains(colorName);
}

void NodeTheme::syncFromGlobal() {
    ThemeManager* tm = ThemeManager::instance();
    m_headerColor     = tm->primaryColor();
    m_bodyColor       = tm->surfaceColor();
    m_borderColor     = tm->borderColor();
    m_portInputColor  = tm->accentColor();
    m_portOutputColor = tm->successColor();
    m_titleColor      = tm->textColor();
    emit changed();
}
