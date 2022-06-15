#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QHash>
#include <QWidget>
#include "behaviours/behaviours.h"
#include "qmlwindow.h"

class ViewPortWindow : public QMLWindow
{
    Q_OBJECT
    Q_PROPERTY(QHash<QString, Behaviours*> behaviours READ behaviours NOTIFY behaviourAdded)
public:
    explicit ViewPortWindow(QWidget *parent = nullptr);
    ~ViewPortWindow();

    QHash<QString, Behaviours*> behaviours();

public slots:
    void setFullScreen(bool isFull);
    bool addBehaviour(const QString &path, const QJsonObject infos);

signals:
    void fullScreenToogle();
    void behaviourAdded(Behaviours *behaviour);

private:
    //    UUID  , Behaviour
    QHash<QString, Behaviours*> m_behaviours;
};

#endif // VIEWPORTWINDOW_H
