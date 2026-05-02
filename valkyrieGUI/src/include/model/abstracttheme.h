#ifndef ABSTRACTTHEME_H
#define ABSTRACTTHEME_H

#include <QObject>
#include <QColor>

class AbstractTheme : public QObject {
    Q_OBJECT

    // --- Structural ---
    Q_PROPERTY(QColor backgroundColor    READ backgroundColor    WRITE setBackgroundColor    NOTIFY themeChanged)
    Q_PROPERTY(QColor surfaceColor       READ surfaceColor       WRITE setSurfaceColor       NOTIFY themeChanged)
    Q_PROPERTY(QColor foregroundColor    READ foregroundColor    WRITE setForegroundColor    NOTIFY themeChanged)
    Q_PROPERTY(QColor borderColor        READ borderColor        WRITE setBorderColor        NOTIFY themeChanged)
    Q_PROPERTY(QColor shadowColor        READ shadowColor        WRITE setShadowColor        NOTIFY themeChanged)

    // --- Brand / Actions ---
    Q_PROPERTY(QColor primaryColor       READ primaryColor       WRITE setPrimaryColor       NOTIFY themeChanged)
    Q_PROPERTY(QColor secondaryColor     READ secondaryColor     WRITE setSecondaryColor     NOTIFY themeChanged)
    Q_PROPERTY(QColor accentColor        READ accentColor        WRITE setAccentColor        NOTIFY themeChanged)

    // --- Semantic States ---
    Q_PROPERTY(QColor successColor       READ successColor       WRITE setSuccessColor       NOTIFY themeChanged)
    Q_PROPERTY(QColor warningColor       READ warningColor       WRITE setWarningColor       NOTIFY themeChanged)
    Q_PROPERTY(QColor dangerColor        READ dangerColor        WRITE setDangerColor        NOTIFY themeChanged)

    // --- Typography ---
    Q_PROPERTY(QColor textColor          READ textColor          WRITE setTextColor          NOTIFY themeChanged)
    Q_PROPERTY(QColor textSecondaryColor READ textSecondaryColor WRITE setTextSecondaryColor NOTIFY themeChanged)

    // --- Interactive ---
    Q_PROPERTY(QColor selectionColor     READ selectionColor     WRITE setSelectionColor     NOTIFY themeChanged)

public:
    explicit AbstractTheme(QObject* parent = nullptr);

    QColor backgroundColor()    const;
    QColor surfaceColor()       const;
    QColor foregroundColor()    const;
    QColor borderColor()        const;
    QColor shadowColor()        const;
    QColor primaryColor()       const;
    QColor secondaryColor()     const;
    QColor accentColor()        const;
    QColor successColor()       const;
    QColor warningColor()       const;
    QColor dangerColor()        const;
    QColor textColor()          const;
    QColor textSecondaryColor() const;
    QColor selectionColor()     const;

    void setBackgroundColor(const QColor& color);
    void setSurfaceColor(const QColor& color);
    void setForegroundColor(const QColor& color);
    void setBorderColor(const QColor& color);
    void setShadowColor(const QColor& color);
    void setPrimaryColor(const QColor& color);
    void setSecondaryColor(const QColor& color);
    void setAccentColor(const QColor& color);
    void setSuccessColor(const QColor& color);
    void setWarningColor(const QColor& color);
    void setDangerColor(const QColor& color);
    void setTextColor(const QColor& color);
    void setTextSecondaryColor(const QColor& color);
    void setSelectionColor(const QColor& color);

signals:
    void themeChanged();

protected:
    QColor m_backgroundColor;
    QColor m_surfaceColor;
    QColor m_foregroundColor;
    QColor m_borderColor;
    QColor m_shadowColor;
    QColor m_primaryColor;
    QColor m_secondaryColor;
    QColor m_accentColor;
    QColor m_successColor;
    QColor m_warningColor;
    QColor m_dangerColor;
    QColor m_textColor;
    QColor m_textSecondaryColor;
    QColor m_selectionColor;
};

#endif // ABSTRACTTHEME_H
