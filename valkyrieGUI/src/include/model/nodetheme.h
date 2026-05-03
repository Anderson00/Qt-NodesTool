#ifndef NODETHEME_H
#define NODETHEME_H

#include <QObject>
#include <QColor>
#include <QSet>
#include <QString>

class NodeTheme : public QObject {
    Q_OBJECT

    // When true, each color falls back to the global ThemeManager value
    // unless that color has been explicitly overridden on this node.
    Q_PROPERTY(bool useGlobalTheme  READ useGlobalTheme  WRITE setUseGlobalTheme  NOTIFY changed)

    // Node-specific color roles
    Q_PROPERTY(QColor headerColor     READ headerColor     WRITE setHeaderColor     NOTIFY changed)
    Q_PROPERTY(QColor bodyColor       READ bodyColor       WRITE setBodyColor       NOTIFY changed)
    Q_PROPERTY(QColor borderColor     READ borderColor     WRITE setBorderColor     NOTIFY changed)
    Q_PROPERTY(QColor portInputColor  READ portInputColor  WRITE setPortInputColor  NOTIFY changed)
    Q_PROPERTY(QColor portOutputColor READ portOutputColor WRITE setPortOutputColor NOTIFY changed)
    Q_PROPERTY(QColor titleColor      READ titleColor      WRITE setTitleColor      NOTIFY changed)

public:
    explicit NodeTheme(QObject* parent = nullptr);

    bool   useGlobalTheme()  const;
    QColor headerColor()     const;
    QColor bodyColor()       const;
    QColor borderColor()     const;
    QColor portInputColor()  const;
    QColor portOutputColor() const;
    QColor titleColor()      const;

    void setUseGlobalTheme(bool use);

    // Setters mark the color as overridden (local value wins even when useGlobalTheme=true)
    void setHeaderColor(const QColor& color);
    void setBodyColor(const QColor& color);
    void setBorderColor(const QColor& color);
    void setPortInputColor(const QColor& color);
    void setPortOutputColor(const QColor& color);
    void setTitleColor(const QColor& color);

    // Remove the override for a color so it falls back to the global theme again
    Q_INVOKABLE void resetColor(const QString& colorName);
    // Remove all overrides
    Q_INVOKABLE void resetAllColors();
    // Returns true when the color has a local override
    Q_INVOKABLE bool isOverridden(const QString& colorName) const;
    // Copy current global palette into local storage (useful before setting useGlobalTheme=false)
    Q_INVOKABLE void syncFromGlobal();

signals:
    void changed();

private:
    void connectToGlobal();

    bool m_useGlobalTheme = true;
    QSet<QString> m_overriddenColors;

    QColor m_headerColor;
    QColor m_bodyColor;
    QColor m_borderColor;
    QColor m_portInputColor;
    QColor m_portOutputColor;
    QColor m_titleColor;
};

#endif // NODETHEME_H
