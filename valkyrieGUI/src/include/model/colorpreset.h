#ifndef COLORPRESET_H
#define COLORPRESET_H

#include <QObject>
#include <QColor>
#include <QString>

class ColorPreset : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString name              READ name              CONSTANT)
    Q_PROPERTY(QColor  backgroundColor   READ backgroundColor   CONSTANT)
    Q_PROPERTY(QColor  surfaceColor      READ surfaceColor      CONSTANT)
    Q_PROPERTY(QColor  foregroundColor   READ foregroundColor   CONSTANT)
    Q_PROPERTY(QColor  borderColor       READ borderColor       CONSTANT)
    Q_PROPERTY(QColor  shadowColor       READ shadowColor       CONSTANT)
    Q_PROPERTY(QColor  primaryColor      READ primaryColor      CONSTANT)
    Q_PROPERTY(QColor  secondaryColor    READ secondaryColor    CONSTANT)
    Q_PROPERTY(QColor  accentColor       READ accentColor       CONSTANT)
    Q_PROPERTY(QColor  successColor      READ successColor      CONSTANT)
    Q_PROPERTY(QColor  warningColor      READ warningColor      CONSTANT)
    Q_PROPERTY(QColor  dangerColor       READ dangerColor       CONSTANT)
    Q_PROPERTY(QColor  textColor         READ textColor         CONSTANT)
    Q_PROPERTY(QColor  textSecondaryColor READ textSecondaryColor CONSTANT)
    Q_PROPERTY(QColor  selectionColor    READ selectionColor    CONSTANT)

public:
    struct Data {
        QString name;
        QColor backgroundColor, surfaceColor, foregroundColor, borderColor, shadowColor;
        QColor primaryColor, secondaryColor, accentColor;
        QColor successColor, warningColor, dangerColor;
        QColor textColor, textSecondaryColor, selectionColor;
    };

    static ColorPreset* create(const Data& data, QObject* parent = nullptr);

    QString name()              const;
    QColor  backgroundColor()   const;
    QColor  surfaceColor()      const;
    QColor  foregroundColor()   const;
    QColor  borderColor()       const;
    QColor  shadowColor()       const;
    QColor  primaryColor()      const;
    QColor  secondaryColor()    const;
    QColor  accentColor()       const;
    QColor  successColor()      const;
    QColor  warningColor()      const;
    QColor  dangerColor()       const;
    QColor  textColor()         const;
    QColor  textSecondaryColor() const;
    QColor  selectionColor()    const;

    const Data& data() const;

private:
    explicit ColorPreset(QObject* parent = nullptr);
    Data m_data;
};

#endif // COLORPRESET_H
