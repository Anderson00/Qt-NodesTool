#include "subtheme.h"

SubTheme::SubTheme(const QString& name, QObject* parent)
    : AbstractTheme(parent), m_name(name) {}

QString SubTheme::name() const { return m_name; }

void SubTheme::copyFromGlobal(const QColor& bg, const QColor& fg, const QColor& accent) {
    setBackgroundColor(bg);
    setForegroundColor(fg);
    setAccentColor(accent);
}
