#ifndef FLOWSWITCH_H
#define FLOWSWITCH_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class FlowSwitch : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int switchValue READ switchValue NOTIFY switchValueChanged)
    Q_PROPERTY(int lastCase    READ lastCase    NOTIFY lastCaseChanged)

public:
    explicit FlowSwitch(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int switchValue() const { return m_value; }
    int lastCase()    const { return m_lastCase; }  // -1=default 0-3=case

public slots:
    void trigger();
    void setValue(int v);

signals:
    void case0();
    void case1();
    void case2();
    void case3();
    void caseDefault();
    void switchValueChanged();
    void lastCaseChanged();

private:
    int m_value    = 0;
    int m_lastCase = -1;
};

#endif // FLOWSWITCH_H
