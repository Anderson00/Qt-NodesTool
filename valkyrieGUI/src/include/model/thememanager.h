#ifndef THEME_H
#define THEME_H

#include "abstracttheme.h"
#include "subtheme.h"
#include <QList>
#include <QQmlListProperty>
#include <QJSEngine>

class ThemeManager : public AbstractTheme {
    Q_OBJECT

    Q_PROPERTY(QQmlListProperty<SubTheme> subThemes READ subThemes NOTIFY subThemesChanged)
    Q_PROPERTY(bool isDarkMode READ isDarkMode NOTIFY themeChanged)

public:
    enum class ThemeMode { Light, Dark };
    Q_ENUM(ThemeMode)

    static ThemeManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QQmlListProperty<SubTheme> subThemes();
    bool isDarkMode() const;

    Q_INVOKABLE void toggleTheme();
    Q_INVOKABLE void setThemeMode(ThemeMode mode);
    Q_INVOKABLE SubTheme* getSubTheme(const QString& name);
    Q_INVOKABLE void addSubTheme(SubTheme* subTheme);
    Q_INVOKABLE void removeSubTheme(const QString& name);
    bool removeSubTheme(SubTheme* subTheme);

signals:
    void subThemesChanged();

private:
    explicit ThemeManager(QObject* parent = nullptr);
    void applyTheme();
    void syncSubThemes();

    ThemeMode m_currentMode;
    QList<SubTheme*> m_subThemes;
};

#endif // THEME_H
