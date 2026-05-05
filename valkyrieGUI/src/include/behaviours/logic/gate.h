#ifndef GATE_H
#define GATE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class Gate : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(bool   gateOpen   READ gateOpen   WRITE setGate  NOTIFY gateChanged)
    Q_PROPERTY(double lastInput  READ lastInput  NOTIFY lastInputChanged)
    Q_PROPERTY(int    passCount  READ passCount  NOTIFY passCountChanged)
    Q_PROPERTY(int    blockCount READ blockCount NOTIFY blockCountChanged)

public:
    explicit Gate(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    bool   gateOpen()   const;
    double lastInput()  const;
    int    passCount()  const;
    int    blockCount() const;

public slots:
    void setGate(bool open);
    void setInput(double value);
    void toggle();
    void resetCounts();

signals:
    void outputValue(double value);
    void outputBlocked(double value);

    void gateChanged();
    void lastInputChanged();
    void passCountChanged();
    void blockCountChanged();

private:
    bool   m_gateOpen   = true;
    double m_lastInput  = 0.0;
    int    m_passCount  = 0;
    int    m_blockCount = 0;
};

#endif // GATE_H
