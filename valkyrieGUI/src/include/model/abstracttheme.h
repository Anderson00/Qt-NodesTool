#ifndef ABSTRACTTHEME_H
#define ABSTRACTTHEME_H

#include <QObject>
#include <QColor>

class AbstractTheme : public QObject {
    Q_OBJECT
    Q_PROPERTY(QColor backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY themeChanged)
    Q_PROPERTY(QColor foregroundColor READ foregroundColor WRITE setForegroundColor NOTIFY themeChanged)
    Q_PROPERTY(QColor primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY themeChanged)
    Q_PROPERTY(QColor accentColor READ accentColor WRITE setAccentColor NOTIFY themeChanged)
    Q_PROPERTY(QColor dangerColor READ dangerColor WRITE setDangerColor NOTIFY themeChanged)
    Q_PROPERTY(QColor textColor READ textColor WRITE setTextColor NOTIFY themeChanged)

public:
    explicit AbstractTheme(QObject* parent = nullptr);

    QColor backgroundColor();
    QColor foregroundColor();
    QColor primaryColor();
    QColor accentColor();
    QColor dangerColor();
    QColor textColor();

    void setBackgroundColor(const QColor& color);
    void setForegroundColor(const QColor& color);
    void setPrimaryColor(const QColor& color);
    void setAccentColor(const QColor& color);
    void setDangerColor(const QColor& color);
    void setTextColor(const QColor& color);

signals:
    void themeChanged();

protected:
    QColor m_backgroundColor;
    QColor m_foregroundColor;
    QColor m_primaryColor;
    QColor m_accentColor;
    QColor m_dangerColor;
    QColor m_textColor;
};

#endif // ABSTRACTTHEME_H
