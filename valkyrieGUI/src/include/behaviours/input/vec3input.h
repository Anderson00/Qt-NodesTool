#ifndef VEC3INPUT_H
#define VEC3INPUT_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class Vec3Input : public Behaviours
{
    Q_OBJECT
    // vecX/vecY — NÃO usar x/y: conflito com Behaviours::x()/y()/setX()/setY()
    Q_PROPERTY(double vecX     READ vecX     WRITE setVecX     NOTIFY vecXChanged)
    Q_PROPERTY(double vecY     READ vecY     WRITE setVecY     NOTIFY vecYChanged)
    Q_PROPERTY(double vecZ     READ vecZ     WRITE setVecZ     NOTIFY vecZChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit Vec3Input(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double vecX()     const;
    double vecY()     const;
    double vecZ()     const;
    bool   autoSend() const;

public slots:
    void send();
    void trigger();
    void setVecX(double x);
    void setVecY(double y);
    void setVecZ(double z);
    void setAutoSend(bool enabled);

signals:
    void outputXYZ(double x, double y, double z);  // OUTPUT PORT — (x, y, z) doubles
    void outputString(QString formatted);           // OUTPUT PORT — "(x, y, z)"
    void outputData(QVariantList data);             // OUTPUT PORT — universal [x, y, z]

    void vecXChanged();
    void vecYChanged();
    void vecZChanged();
    void autoSendChanged();

private:
    double m_vecX     = 0.0;
    double m_vecY     = 0.0;
    double m_vecZ     = 0.0;
    bool   m_autoSend = false;
};

#endif // VEC3INPUT_H
