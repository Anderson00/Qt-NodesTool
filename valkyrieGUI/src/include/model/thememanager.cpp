#include "thememanager.h"
#include "globalproperties.h"

ThemeManager* ThemeManager::instance() {
    static ThemeManager* _instance = []() {
        auto* tm = new ThemeManager();
        tm->applyTheme();
        return tm;
    }();
    return _instance;
}

QObject* ThemeManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    return ThemeManager::instance();
}

ThemeManager::ThemeManager(QObject* parent)
    : AbstractTheme(parent), m_currentMode(ThemeMode::Dark), m_transitionProgress(1.0)
{
    m_transitionAnimation = new QPropertyAnimation(this, "transitionProgress", this);
    m_transitionAnimation->setDuration(300);
    m_transitionAnimation->setEasingCurve(QEasingCurve::InOutQuad);
}

bool ThemeManager::isDarkMode() const {
    return m_currentMode == ThemeMode::Dark;
}

qreal ThemeManager::transitionProgress() const {
    return m_transitionProgress;
}

void ThemeManager::setTransitionProgress(qreal progress) {
    if (m_transitionProgress != progress) {
        m_transitionProgress = progress;
        emit transitionProgressChanged();
        emit themeChanged();
    }
}

QColor ThemeManager::interpolateColor(const QColor& fromColor, const QColor& toColor, qreal progress) const {
    if (progress >= 1.0) return toColor;
    if (progress <= 0.0) return fromColor;

    qreal r = fromColor.redF() + (toColor.redF() - fromColor.redF()) * progress;
    qreal g = fromColor.greenF() + (toColor.greenF() - fromColor.greenF()) * progress;
    qreal b = fromColor.blueF() + (toColor.blueF() - fromColor.blueF()) * progress;
    qreal a = fromColor.alphaF() + (toColor.alphaF() - fromColor.alphaF()) * progress;

    return QColor::fromRgbF(r, g, b, a);
}

QColor ThemeManager::backgroundColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldBackgroundColor, AbstractTheme::backgroundColor(), m_transitionProgress) : AbstractTheme::backgroundColor();
}

QColor ThemeManager::surfaceColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldSurfaceColor, AbstractTheme::surfaceColor(), m_transitionProgress) : AbstractTheme::surfaceColor();
}

QColor ThemeManager::foregroundColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldForegroundColor, AbstractTheme::foregroundColor(), m_transitionProgress) : AbstractTheme::foregroundColor();
}

QColor ThemeManager::borderColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldBorderColor, AbstractTheme::borderColor(), m_transitionProgress) : AbstractTheme::borderColor();
}

QColor ThemeManager::shadowColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldShadowColor, AbstractTheme::shadowColor(), m_transitionProgress) : AbstractTheme::shadowColor();
}

QColor ThemeManager::primaryColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldPrimaryColor, AbstractTheme::primaryColor(), m_transitionProgress) : AbstractTheme::primaryColor();
}

QColor ThemeManager::secondaryColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldSecondaryColor, AbstractTheme::secondaryColor(), m_transitionProgress) : AbstractTheme::secondaryColor();
}

QColor ThemeManager::accentColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldAccentColor, AbstractTheme::accentColor(), m_transitionProgress) : AbstractTheme::accentColor();
}

QColor ThemeManager::successColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldSuccessColor, AbstractTheme::successColor(), m_transitionProgress) : AbstractTheme::successColor();
}

QColor ThemeManager::warningColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldWarningColor, AbstractTheme::warningColor(), m_transitionProgress) : AbstractTheme::warningColor();
}

QColor ThemeManager::dangerColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldDangerColor, AbstractTheme::dangerColor(), m_transitionProgress) : AbstractTheme::dangerColor();
}

QColor ThemeManager::textColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldTextColor, AbstractTheme::textColor(), m_transitionProgress) : AbstractTheme::textColor();
}

QColor ThemeManager::textSecondaryColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldTextSecondaryColor, AbstractTheme::textSecondaryColor(), m_transitionProgress) : AbstractTheme::textSecondaryColor();
}

QColor ThemeManager::selectionColor() const {
    return (m_transitionProgress < 1.0) ? interpolateColor(m_oldSelectionColor, AbstractTheme::selectionColor(), m_transitionProgress) : AbstractTheme::selectionColor();
}

void ThemeManager::startColorTransition() {
    if (!m_animationEnabled) {
        m_transitionProgress = 1.0;
        emit transitionProgressChanged();
        emit themeChanged();
        return;
    }

    m_transitionAnimation->stop();
    m_transitionAnimation->setStartValue(0.0);
    m_transitionAnimation->setEndValue(1.0);
    m_transitionAnimation->start();
}

void ThemeManager::applyColorsWithAnimation(const QColor& bgColor, const QColor& surfaceColor,
                                            const QColor& fgColor, const QColor& borderColor,
                                            const QColor& shadowColor, const QColor& primaryColor,
                                            const QColor& secondaryColor, const QColor& accentColor,
                                            const QColor& successColor, const QColor& warningColor,
                                            const QColor& dangerColor, const QColor& textColor,
                                            const QColor& textSecondaryColor, const QColor& selectionColor,
                                            bool animate) {
    if (animate) {
        m_oldBackgroundColor = AbstractTheme::backgroundColor();
        m_oldSurfaceColor = AbstractTheme::surfaceColor();
        m_oldForegroundColor = AbstractTheme::foregroundColor();
        m_oldBorderColor = AbstractTheme::borderColor();
        m_oldShadowColor = AbstractTheme::shadowColor();
        m_oldPrimaryColor = AbstractTheme::primaryColor();
        m_oldSecondaryColor = AbstractTheme::secondaryColor();
        m_oldAccentColor = AbstractTheme::accentColor();
        m_oldSuccessColor = AbstractTheme::successColor();
        m_oldWarningColor = AbstractTheme::warningColor();
        m_oldDangerColor = AbstractTheme::dangerColor();
        m_oldTextColor = AbstractTheme::textColor();
        m_oldTextSecondaryColor = AbstractTheme::textSecondaryColor();
        m_oldSelectionColor = AbstractTheme::selectionColor();
    } else {
        m_transitionProgress = 1.0;
    }

    AbstractTheme::setBackgroundColor(bgColor);
    AbstractTheme::setSurfaceColor(surfaceColor);
    AbstractTheme::setForegroundColor(fgColor);
    AbstractTheme::setBorderColor(borderColor);
    AbstractTheme::setShadowColor(shadowColor);
    AbstractTheme::setPrimaryColor(primaryColor);
    AbstractTheme::setSecondaryColor(secondaryColor);
    AbstractTheme::setAccentColor(accentColor);
    AbstractTheme::setSuccessColor(successColor);
    AbstractTheme::setWarningColor(warningColor);
    AbstractTheme::setDangerColor(dangerColor);
    AbstractTheme::setTextColor(textColor);
    AbstractTheme::setTextSecondaryColor(textSecondaryColor);
    AbstractTheme::setSelectionColor(selectionColor);

    if (animate) {
        startColorTransition();
    } else {
        emit themeChanged();
    }
}

void ThemeManager::applyTheme() {
    if (m_initialized) {
        GlobalProperties::instance()->setIsDarkMode(m_currentMode == ThemeMode::Dark);
    }

    m_oldBackgroundColor = AbstractTheme::backgroundColor();
    m_oldSurfaceColor = AbstractTheme::surfaceColor();
    m_oldForegroundColor = AbstractTheme::foregroundColor();
    m_oldBorderColor = AbstractTheme::borderColor();
    m_oldShadowColor = AbstractTheme::shadowColor();
    m_oldPrimaryColor = AbstractTheme::primaryColor();
    m_oldSecondaryColor = AbstractTheme::secondaryColor();
    m_oldAccentColor = AbstractTheme::accentColor();
    m_oldSuccessColor = AbstractTheme::successColor();
    m_oldWarningColor = AbstractTheme::warningColor();
    m_oldDangerColor = AbstractTheme::dangerColor();
    m_oldTextColor = AbstractTheme::textColor();
    m_oldTextSecondaryColor = AbstractTheme::textSecondaryColor();
    m_oldSelectionColor = AbstractTheme::selectionColor();

    if (m_currentMode == ThemeMode::Light) {
        // Light — cool blue-gray base, indigo primary
        setBackgroundColor(QColor(240, 242, 245));   // #F0F2F5 — canvas
        setSurfaceColor(QColor(255, 255, 255));       // #FFFFFF — cards / panels
        setForegroundColor(QColor(228, 232, 239));    // #E4E8EF — elevated panels
        setBorderColor(QColor(203, 213, 225));        // #CBD5E1 — subtle dividers
        setShadowColor(QColor(0, 0, 0, 25));          // 10% black

        setPrimaryColor(QColor(91, 106, 240));        // #5B6AF0 — indigo
        setSecondaryColor(QColor(139, 92, 246));      // #8B5CF6 — violet
        setAccentColor(QColor(6, 182, 212));          // #06B6D4 — cyan

        setSuccessColor(QColor(16, 185, 129));        // #10B981 — emerald
        setWarningColor(QColor(245, 158, 11));        // #F59E0B — amber
        setDangerColor(QColor(239, 68, 68));          // #EF4444 — rose

        setTextColor(QColor(26, 26, 46));             // #1A1A2E — near-black
        setTextSecondaryColor(QColor(100, 116, 139)); // #64748B — slate
        setSelectionColor(QColor(91, 106, 240, 51));  // indigo @ 20%
    } else {
        // Dark — deep navy base, lighter indigo primary
        setBackgroundColor(QColor(13, 17, 23));       // #0D1117 — deep navy
        setSurfaceColor(QColor(22, 27, 34));          // #161B22 — elevated surface
        setForegroundColor(QColor(30, 37, 48));       // #1E2530 — panels / drawers
        setBorderColor(QColor(48, 54, 61));           // #30363D — subtle border
        setShadowColor(QColor(0, 0, 0, 120));         // heavy shadow for depth

        setPrimaryColor(QColor(124, 106, 247));       // #7C6AF7 — lighter indigo
        setSecondaryColor(QColor(167, 139, 250));     // #A78BFA — lighter violet
        setAccentColor(QColor(34, 211, 238));         // #22D3EE — bright cyan

        setSuccessColor(QColor(52, 211, 153));        // #34D399 — lighter emerald
        setWarningColor(QColor(251, 191, 36));        // #FBBF24 — lighter amber
        setDangerColor(QColor(248, 113, 113));        // #F87171 — lighter rose

        setTextColor(QColor(230, 237, 243));          // #E6EDF3 — off-white
        setTextSecondaryColor(QColor(139, 148, 158)); // #8B949E — muted gray
        setSelectionColor(QColor(124, 106, 247, 51)); // indigo @ 20%
    }

    syncSubThemes();
    startColorTransition();
}

void ThemeManager::syncSubThemes() {
    for (auto* sub : qAsConst(m_subThemes))
        sub->copyFromGlobal(this);
}

void ThemeManager::toggleTheme() {
    m_currentMode = (m_currentMode == ThemeMode::Light) ? ThemeMode::Dark : ThemeMode::Light;
    applyTheme();
}

void ThemeManager::setThemeMode(ThemeMode mode) {
    if (m_currentMode != mode) {
        m_currentMode = mode;
        applyTheme();
    }
}

QQmlListProperty<SubTheme> ThemeManager::subThemes() {
    return QQmlListProperty<SubTheme>(this, &m_subThemes);
}

void ThemeManager::addSubTheme(SubTheme* subTheme) {
    subTheme->copyFromGlobal(this);
    m_subThemes.append(subTheme);
    emit subThemesChanged();
}

void ThemeManager::removeSubTheme(const QString& name) {
    for (int i = 0; i < m_subThemes.size(); ++i) {
        if (m_subThemes[i]->name() == name) {
            SubTheme* toRemove = m_subThemes.takeAt(i);
            toRemove->deleteLater();
            emit subThemesChanged();
            return;
        }
    }
}

bool ThemeManager::removeSubTheme(SubTheme* subTheme) {
    return m_subThemes.removeOne(subTheme);
}

SubTheme* ThemeManager::getSubTheme(const QString& name) {
    for (auto* sub : m_subThemes) {
        if (sub->name() == name) return sub;
    }
    return nullptr;
}
