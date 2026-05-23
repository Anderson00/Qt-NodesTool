#ifndef COLORINPUT_H
#define COLORINPUT_H

#include <QObject>
#include <QColor>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class ColorInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString colorHex READ colorHex WRITE setColorHex NOTIFY colorHexChanged)
    Q_PROPERTY(bool    autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit ColorInput(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString colorHex() const;
    bool    autoSend() const;

public slots:
    void send();
    void trigger();
    void setColorHex(const QString& hex);
    void setAutoSend(bool enabled);

signals:
    void outputString(QString hexColor);   // OUTPUT PORT — "#RRGGBB"
    void outputRGB(int r, int g, int b);   // OUTPUT PORT — (r, g, b) ints 0-255
    void outputData(QVariantList data);    // OUTPUT PORT — universal [hex, r, g, b]

    void colorHexChanged();
    void autoSendChanged();

private:
    QString m_colorHex = "#FFFFFF";
    bool    m_autoSend = false;
};

#endif // COLORINPUT_H
