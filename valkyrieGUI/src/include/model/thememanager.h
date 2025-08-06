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

public:
    static ThemeManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QQmlListProperty<SubTheme> subThemes();

    Q_INVOKABLE void toggleTheme();
    Q_INVOKABLE SubTheme* getSubTheme(const QString& name);
    Q_INVOKABLE void addSubTheme(SubTheme* subTheme);
    Q_INVOKABLE void removeSubTheme(const QString& name);
    bool removeSubTheme(SubTheme *subTheme);

signals:
    void subThemesChanged();

private:
    explicit ThemeManager(QObject* parent = nullptr);
    void applyTheme();

    enum class ThemeMode { Light, Dark };
    ThemeMode currentMode;

    QList<SubTheme*> m_subThemes;
};


#endif // THEME_H
