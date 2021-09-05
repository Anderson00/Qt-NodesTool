#ifndef QMLMDISUBWINDOW_H
#define QMLMDISUBWINDOW_H

#include <QMdiSubWindow>
#include <QSettings>

#include "../qmlwindow.h"

class QMLMdiSubWindow : public QMdiSubWindow
{
    Q_OBJECT

public:
    explicit QMLMdiSubWindow(QWidget *parent = nullptr, const QUrl& source = QUrl(""));
    ~QMLMdiSubWindow();

    void setPrevSaveState(std::function<void(QSettings&)> logic);
    void setPrevLoadState(std::function<void(QSettings&)> logic);

    QUrl source();

    virtual QString whoIAm() = 0;

private slots:
    void saveState();
    void loadState();

private:
    QMLWindow* m_window;
};

#endif // QMLMDISUBWINDOW_H
