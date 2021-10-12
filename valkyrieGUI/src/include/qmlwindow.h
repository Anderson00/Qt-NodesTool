#ifndef QMLWINDOW_H
#define QMLWINDOW_H

#include <QMainWindow>
#include <QObject>
#include <QQuickView>

class QMLWindow : public QMainWindow
{
    Q_OBJECT
public:
    explicit QMLWindow(QWidget *parent = nullptr, const QUrl& qmlUrl = QUrl(""));
    virtual ~QMLWindow();

    //Virtuals
    void changeEvent(QEvent* e);
    void closeEvent(QCloseEvent *event);
    //Virtuals end

    QUrl source();

protected:
    void setQMLSourceUrl(const QUrl& url);
    QQuickView *view();

signals:
    void closeWindow();
    void windowMaximizing(bool isMaximizing);
    void windowMinimizing(bool isMinimizing);
    void windowFullScreen(bool isFullScreen);

private:
    QQuickView *m_view;
};

#endif // QMLWINDOW_H
