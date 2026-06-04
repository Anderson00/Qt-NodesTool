#ifndef FLOWSTART_H
#define FLOWSTART_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class FlowStart : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(bool autoStart  READ autoStart  WRITE setAutoStart  NOTIFY autoStartChanged)
    Q_PROPERTY(int  runCount   READ runCount                       NOTIFY runCountChanged)

public:
    explicit FlowStart(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    bool autoStart() const { return m_autoStart; }
    int  runCount()  const { return m_runCount; }

public slots:
    void trigger();
    void setAutoStart(bool v);

signals:
    void execOut();
    void autoStartChanged();
    void runCountChanged();

private:
    bool m_autoStart = false;
    int  m_runCount  = 0;
};

#endif // FLOWSTART_H
