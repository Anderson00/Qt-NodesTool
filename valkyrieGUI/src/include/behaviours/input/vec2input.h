#ifndef VEC2INPUT_H
#define VEC2INPUT_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class Vec2Input : public Behaviours
{
    Q_OBJECT
    // vecX/vecY — NÃO usar x/y: conflito com Behaviours::x()/y()/setX()/setY()
    Q_PROPERTY(double vecX     READ vecX     WRITE setVecX     NOTIFY vecXChanged)
    Q_PROPERTY(double vecY     READ vecY     WRITE setVecY     NOTIFY vecYChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit Vec2Input(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double vecX()     const;
    double vecY()     const;
    bool   autoSend() const;

public slots:
    void send();
    void trigger();
    void setVecX(double x);
    void setVecY(double y);
    void setAutoSend(bool enabled);

signals:
    void outputXY(double x, double y);     // OUTPUT PORT — (x, y) doubles
    void outputString(QString formatted);  // OUTPUT PORT — "(x, y)"
    void outputData(QVariantList data);    // OUTPUT PORT — universal [x, y]

    void vecXChanged();
    void vecYChanged();
    void autoSendChanged();

private:
    double m_vecX     = 0.0;
    double m_vecY     = 0.0;
    bool   m_autoSend = false;
};

#endif // VEC2INPUT_H
