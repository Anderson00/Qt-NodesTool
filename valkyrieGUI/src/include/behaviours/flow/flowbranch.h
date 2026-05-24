#ifndef FLOWBRANCH_H
#define FLOWBRANCH_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class FlowBranch : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(bool condition READ condition NOTIFY conditionChanged)
    Q_PROPERTY(int  lastPath  READ lastPath  NOTIFY lastPathChanged)

public:
    explicit FlowBranch(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    bool condition() const { return m_condition; }
    int  lastPath()  const { return m_lastPath; }  // 0=none 1=true 2=false

public slots:
    void trigger();
    void setCondition(bool v);

signals:
    void execTrue();
    void execFalse();
    void conditionChanged();
    void lastPathChanged();

private:
    bool m_condition = false;
    int  m_lastPath  = 0;
};

#endif // FLOWBRANCH_H
