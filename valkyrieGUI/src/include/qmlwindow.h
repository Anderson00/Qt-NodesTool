#ifndef QMLWINDOW_H
#define QMLWINDOW_H

#include <QMainWindow>
#include <QObject>
#include <QVector>
#include <QQuickView>

class QMLWindow : public QMainWindow
{
    Q_OBJECT
public:
    struct PropertyPair { QString name; QObject *obj; };

    explicit QMLWindow(QWidget *parent = nullptr, const QUrl& qmlUrl = QUrl(""));
    virtual ~QMLWindow();

    //Virtuals
    void changeEvent(QEvent* e);
    void closeEvent(QCloseEvent *event);
    //Virtuals end

    QUrl source();

    void showWindow(const QVector<PropertyPair> &properties = {});
    void setContextProperties(const QVector<PropertyPair> &properties);
    void setContextProperty(const QString &ctx, QObject *obj);

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
    QUrl m_qml_url;
};

#endif // QMLWINDOW_H
