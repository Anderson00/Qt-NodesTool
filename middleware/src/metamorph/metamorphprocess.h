#ifndef METAMORPHPROCESS_H
#define METAMORPHPROCESS_H

#include <QObject>
#include <QStringList>
#include <QJsonObject>
#include <QProcess>

class MetamorphProcess : public QObject
{
    Q_OBJECT
public:
    explicit MetamorphProcess(QStringList args = {},QObject *parent = nullptr);
    ~MetamorphProcess();

public slots:
    void doRequest(QJsonObject obj);

signals:
    void messageResponse(QJsonObject response);

private:
    QStringList m_args;
    QProcess *m_proc;
};

#endif // METAMORPHPROCESS_H
