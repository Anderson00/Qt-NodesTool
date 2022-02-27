#ifndef TESTCONNECTIONWINDOW_H
#define TESTCONNECTIONWINDOW_H

#include <QObject>
#include "qmlwindow.h"
#include "qmlmdisubwindow.h"
#include "cliente/midclient.h"

class TestConnectionWindow : public QMLMdiSubWindow
{
    Q_OBJECT
public:
    explicit TestConnectionWindow(QWidget *parent = nullptr);
    ~TestConnectionWindow();

    QString whoIAm() override;

signals:

private:
    MidClient *m_client;
    MidClient m_client2;
};

#endif // TESTCONNECTIONWINDOW_H
