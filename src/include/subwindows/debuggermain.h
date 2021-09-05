#ifndef DEBUGGERMAIN_H
#define DEBUGGERMAIN_H

#include <QMainWindow>

#include "qmlwindow.h"
#include "qmlmdisubwindow.h"

class DebuggerMain : public QMLMdiSubWindow
{
    Q_OBJECT

public:
    explicit DebuggerMain(QWidget *parent = nullptr);
    ~DebuggerMain();

    QString whoIAm() override;
};

#endif // DEBUGGERMAIN_H
