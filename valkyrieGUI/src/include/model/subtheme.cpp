#include "subtheme.h"

SubTheme::SubTheme(const QString& name, QObject* parent)
    : AbstractTheme(parent), m_name(name) {}

QString SubTheme::name() const { return m_name; }

void SubTheme::copyFromGlobal(const AbstractTheme* source) {
    setBackgroundColor(source->backgroundColor());
    setSurfaceColor(source->surfaceColor());
    setForegroundColor(source->foregroundColor());
    setBorderColor(source->borderColor());
    setShadowColor(source->shadowColor());
    setPrimaryColor(source->primaryColor());
    setSecondaryColor(source->secondaryColor());
    setAccentColor(source->accentColor());
    setSuccessColor(source->successColor());
    setWarningColor(source->warningColor());
    setDangerColor(source->dangerColor());
    setTextColor(source->textColor());
    setTextSecondaryColor(source->textSecondaryColor());
    setSelectionColor(source->selectionColor());
}
