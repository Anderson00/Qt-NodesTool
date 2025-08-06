#include "abstracttheme.h"

AbstractTheme::AbstractTheme(QObject* parent)
    : QObject(parent),
    m_backgroundColor(Qt::white),
    m_foregroundColor(Qt::black),
    m_accentColor(Qt::blue),
    m_dangerColor(Qt::red)
{
}

// Getters
QColor AbstractTheme::backgroundColor() {
    return m_backgroundColor;
}

QColor AbstractTheme::foregroundColor() {
    return m_foregroundColor;
}

QColor AbstractTheme::primaryColor() {
    return m_primaryColor;
}

QColor AbstractTheme::accentColor() {
    return m_accentColor;
}

QColor AbstractTheme::dangerColor() {
    return m_dangerColor;
}

// Setters
void AbstractTheme::setBackgroundColor(const QColor& color) {
    if (m_backgroundColor != color) {
        m_backgroundColor = color;
        emit themeChanged();
    }
}

void AbstractTheme::setForegroundColor(const QColor& color) {
    if (m_foregroundColor != color) {
        m_foregroundColor = color;
        emit themeChanged();
    }
}

void AbstractTheme::setPrimaryColor(const QColor &color)
{
    if (m_primaryColor != color) {
        m_primaryColor = color;
        emit themeChanged();
    }
}

void AbstractTheme::setAccentColor(const QColor& color) {
    if (m_accentColor != color) {
        m_accentColor = color;
        emit themeChanged();
    }
}

void AbstractTheme::setDangerColor(const QColor& color) {
    if (m_dangerColor != color) {
        m_dangerColor = color;
        emit themeChanged();
    }
}
