#include "abstracttheme.h"

AbstractTheme::AbstractTheme(QObject* parent)
    : QObject(parent)
    , m_backgroundColor(Qt::white)
    , m_surfaceColor(Qt::white)
    , m_foregroundColor(QColor(240, 242, 245))
    , m_borderColor(QColor(203, 213, 225))
    , m_shadowColor(QColor(0, 0, 0, 30))
    , m_primaryColor(QColor(91, 106, 240))
    , m_secondaryColor(QColor(139, 92, 246))
    , m_accentColor(QColor(6, 182, 212))
    , m_successColor(QColor(16, 185, 129))
    , m_warningColor(QColor(245, 158, 11))
    , m_dangerColor(QColor(239, 68, 68))
    , m_textColor(QColor(26, 26, 46))
    , m_textSecondaryColor(QColor(100, 116, 139))
    , m_selectionColor(QColor(91, 106, 240, 51))
{}

QColor AbstractTheme::backgroundColor()    const { return m_backgroundColor; }
QColor AbstractTheme::surfaceColor()       const { return m_surfaceColor; }
QColor AbstractTheme::foregroundColor()    const { return m_foregroundColor; }
QColor AbstractTheme::borderColor()        const { return m_borderColor; }
QColor AbstractTheme::shadowColor()        const { return m_shadowColor; }
QColor AbstractTheme::primaryColor()       const { return m_primaryColor; }
QColor AbstractTheme::secondaryColor()     const { return m_secondaryColor; }
QColor AbstractTheme::accentColor()        const { return m_accentColor; }
QColor AbstractTheme::successColor()       const { return m_successColor; }
QColor AbstractTheme::warningColor()       const { return m_warningColor; }
QColor AbstractTheme::dangerColor()        const { return m_dangerColor; }
QColor AbstractTheme::textColor()          const { return m_textColor; }
QColor AbstractTheme::textSecondaryColor() const { return m_textSecondaryColor; }
QColor AbstractTheme::selectionColor()     const { return m_selectionColor; }

#define SET_COLOR(member, signal) \
    if (member != color) { member = color; emit signal(); }

void AbstractTheme::setBackgroundColor(const QColor& color)    { SET_COLOR(m_backgroundColor,    themeChanged) }
void AbstractTheme::setSurfaceColor(const QColor& color)       { SET_COLOR(m_surfaceColor,       themeChanged) }
void AbstractTheme::setForegroundColor(const QColor& color)    { SET_COLOR(m_foregroundColor,    themeChanged) }
void AbstractTheme::setBorderColor(const QColor& color)        { SET_COLOR(m_borderColor,        themeChanged) }
void AbstractTheme::setShadowColor(const QColor& color)        { SET_COLOR(m_shadowColor,        themeChanged) }
void AbstractTheme::setPrimaryColor(const QColor& color)       { SET_COLOR(m_primaryColor,       themeChanged) }
void AbstractTheme::setSecondaryColor(const QColor& color)     { SET_COLOR(m_secondaryColor,     themeChanged) }
void AbstractTheme::setAccentColor(const QColor& color)        { SET_COLOR(m_accentColor,        themeChanged) }
void AbstractTheme::setSuccessColor(const QColor& color)       { SET_COLOR(m_successColor,       themeChanged) }
void AbstractTheme::setWarningColor(const QColor& color)       { SET_COLOR(m_warningColor,       themeChanged) }
void AbstractTheme::setDangerColor(const QColor& color)        { SET_COLOR(m_dangerColor,        themeChanged) }
void AbstractTheme::setTextColor(const QColor& color)          { SET_COLOR(m_textColor,          themeChanged) }
void AbstractTheme::setTextSecondaryColor(const QColor& color) { SET_COLOR(m_textSecondaryColor, themeChanged) }
void AbstractTheme::setSelectionColor(const QColor& color)     { SET_COLOR(m_selectionColor,     themeChanged) }

#undef SET_COLOR
