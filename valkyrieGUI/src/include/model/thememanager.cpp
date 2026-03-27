#include "thememanager.h"

ThemeManager* ThemeManager::instance() {
    static ThemeManager* _instance = new ThemeManager();
    _instance->applyTheme();
    return _instance;
}

QObject* ThemeManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    return ThemeManager::instance();
}

ThemeManager::ThemeManager(QObject* parent)
    : AbstractTheme(parent), currentMode(ThemeMode::Dark) {
}

void ThemeManager::applyTheme() {
    if (currentMode == ThemeMode::Light) {
        setBackgroundColor(QColor(224, 224, 224));
        setForegroundColor(QColor(31, 31, 31));
        setPrimaryColor(QColor(60, 179, 113));
        setAccentColor(QColor(60, 179, 113));
        setDangerColor(QColor(244, 0, 0));
        setTextColor(QColor(31, 31, 31));
    } else {
        setBackgroundColor(QColor(31, 31, 31));
        setForegroundColor(QColor(224, 224, 224));
        setPrimaryColor(QColor(60, 179, 113));
        setAccentColor(QColor(60, 179, 113));
        setDangerColor(QColor(244, 0, 0));
        setTextColor(QColor(224, 224, 224));
    }

    for (auto* sub : qAsConst(m_subThemes)) {
        sub->copyFromGlobal(backgroundColor(), foregroundColor(), accentColor());
    }

    emit themeChanged();
}

void ThemeManager::toggleTheme() {
    currentMode = (currentMode == ThemeMode::Light) ? ThemeMode::Dark : ThemeMode::Light;
    applyTheme();
}

QQmlListProperty<SubTheme> ThemeManager::subThemes() {
    return QQmlListProperty<SubTheme>(this, &m_subThemes);
}

void ThemeManager::addSubTheme(SubTheme* subTheme) {
    subTheme->copyFromGlobal(backgroundColor(), foregroundColor(), accentColor());
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

bool ThemeManager::removeSubTheme(SubTheme *subTheme)
{
    return m_subThemes.removeOne(subTheme);
}

SubTheme* ThemeManager::getSubTheme(const QString& name) {
    for (auto* sub : m_subThemes) {
        if (sub->name() == name) return sub;
    }
    return nullptr;
}
