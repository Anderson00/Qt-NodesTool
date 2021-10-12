#ifndef XMLSAVESTATE_H
#define XMLSAVESTATE_H

#include <QObject>
#include <QDateTime>
#include <QTimer>
#include <QKeySequence>
#include <QHash>
#include <QFile>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>
#include "subwindows/qmlmdisubwindow.h"

namespace xml {
const std::function<QHash<QString, QString>(QMLMdiSubWindow*)> defaultLogicToSaveQMLMdiSubWindows = [](QMLMdiSubWindow *subWindow){
    QHash<QString, QString> result;

    result["qmlSource"] = subWindow->source().toString();
    result["posX"] = QString::number(subWindow->x());
    result["posY"] = QString::number(subWindow->y());

    result["width"] = QString::number(subWindow->width());
    result["height"] = QString::number(subWindow->height());

    return result;
};

class XMLSaveState : public QObject
{
    enum Logic{
        Interval, Shortcut, IntervalAndShortcut, NoLogic
    };

    Q_OBJECT

private:
     explicit XMLSaveState(QObject *parent = nullptr);
public:
   ~XMLSaveState();

    static xml::XMLSaveState *instance();

    void setLogic(Logic logic);
    void setQMdiArea(QMdiArea * mdiArea);
    void setSaveInterval(int msecs = 5000);

    QMLMdiSubWindow *addWidgetsToSave(QMLMdiSubWindow *qmlSubWindows, std::function<QHash<QString, QString>(QMLMdiSubWindow*)> saveLogic = defaultLogicToSaveQMLMdiSubWindows);


public slots:
    void onShortcutExecuted(const QKeySequence& shortcutKeys);
    void saveState();

signals:
    void saved(QDateTime lastSave);


private:
    static XMLSaveState *m_instance;

    Logic m_logic;
    QTimer * m_timer;
    QMdiArea *m_mdiArea;
    int m_intervalMsecs;
    QHash<QWidget*, std::function<QHash<QString, QString>(QWidget*)>> m_widgetsAndLogics;
    QHash<QMLMdiSubWindow*, std::function<QHash<QString, QString>(QMLMdiSubWindow*)>> m_qmlSubWindowsAndLogics;
};
};

#endif // XMLSAVESTATE_H
