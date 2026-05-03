#ifndef THEME_H
#define THEME_H

#include "abstracttheme.h"
#include "subtheme.h"
#include <QList>
#include <QQmlListProperty>
#include <QJSEngine>
#include <QPropertyAnimation>

class ThemeManager : public AbstractTheme {
    Q_OBJECT

    Q_PROPERTY(QQmlListProperty<SubTheme> subThemes READ subThemes NOTIFY subThemesChanged)
    Q_PROPERTY(bool isDarkMode READ isDarkMode NOTIFY themeChanged)
    Q_PROPERTY(qreal transitionProgress READ transitionProgress WRITE setTransitionProgress NOTIFY transitionProgressChanged)

public:
    enum class ThemeMode { Light, Dark };
    Q_ENUM(ThemeMode)

    static ThemeManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QQmlListProperty<SubTheme> subThemes();
    bool isDarkMode() const;
    qreal transitionProgress() const;
    void setTransitionProgress(qreal progress);

    Q_INVOKABLE void toggleTheme();
    Q_INVOKABLE void setThemeMode(ThemeMode mode);
    void markInitialized() { m_initialized = true; m_animationEnabled = true; }
    Q_INVOKABLE SubTheme* getSubTheme(const QString& name);
    Q_INVOKABLE void addSubTheme(SubTheme* subTheme);
    Q_INVOKABLE void removeSubTheme(const QString& name);
    bool removeSubTheme(SubTheme* subTheme);

    void applyColorsWithAnimation(const QColor& bgColor, const QColor& surfaceColor,
                                  const QColor& fgColor, const QColor& borderColor,
                                  const QColor& shadowColor, const QColor& primaryColor,
                                  const QColor& secondaryColor, const QColor& accentColor,
                                  const QColor& successColor, const QColor& warningColor,
                                  const QColor& dangerColor, const QColor& textColor,
                                  const QColor& textSecondaryColor, const QColor& selectionColor,
                                  bool animate = true);

    // Override color getters to support smooth transitions
    QColor backgroundColor() const override;
    QColor surfaceColor() const override;
    QColor foregroundColor() const override;
    QColor borderColor() const override;
    QColor shadowColor() const override;
    QColor primaryColor() const override;
    QColor secondaryColor() const override;
    QColor accentColor() const override;
    QColor successColor() const override;
    QColor warningColor() const override;
    QColor dangerColor() const override;
    QColor textColor() const override;
    QColor textSecondaryColor() const override;
    QColor selectionColor() const override;

signals:
    void subThemesChanged();
    void transitionProgressChanged();

private:
    explicit ThemeManager(QObject* parent = nullptr);
    void applyTheme();
    void syncSubThemes();
    void startColorTransition();
    QColor interpolateColor(const QColor& fromColor, const QColor& toColor, qreal progress) const;

    ThemeMode m_currentMode;
    QList<SubTheme*> m_subThemes;
    QPropertyAnimation* m_transitionAnimation;
    qreal m_transitionProgress;
    bool m_initialized = false;
    bool m_animationEnabled = false;

    // Store previous colors for smooth transition
    QColor m_oldBackgroundColor;
    QColor m_oldSurfaceColor;
    QColor m_oldForegroundColor;
    QColor m_oldBorderColor;
    QColor m_oldShadowColor;
    QColor m_oldPrimaryColor;
    QColor m_oldSecondaryColor;
    QColor m_oldAccentColor;
    QColor m_oldSuccessColor;
    QColor m_oldWarningColor;
    QColor m_oldDangerColor;
    QColor m_oldTextColor;
    QColor m_oldTextSecondaryColor;
    QColor m_oldSelectionColor;
};

#endif // THEME_H
