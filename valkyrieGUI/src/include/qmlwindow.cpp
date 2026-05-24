#include "qmlwindow.h"
#include <QQuickView>
#include <QMessageBox>
#include <QGuiApplication>
#include <QSettings>
#include <QtQuickWidgets/QQuickWidget>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlComponent>
#include <QtQml/QQmlNetworkAccessManagerFactory>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUuid>

// Intercepts all QML network requests and sets a proper User-Agent so that
// tile servers (OSM, CartoDB, etc.) do not block the app.
namespace {

class ValkyrieNetworkManager : public QNetworkAccessManager {
public:
    explicit ValkyrieNetworkManager(QObject *parent = nullptr)
        : QNetworkAccessManager(parent) {}

protected:
    QNetworkReply *createRequest(Operation op,
                                 const QNetworkRequest &req,
                                 QIODevice *data) override
    {
        QNetworkRequest modified = req;
        modified.setHeader(QNetworkRequest::UserAgentHeader,
                           QByteArray("Valkyrie/1.0 (Qt debug tool; https://github.com/your-repo)"));
        return QNetworkAccessManager::createRequest(op, modified, data);
    }
};

class ValkyrieNetworkFactory : public QQmlNetworkAccessManagerFactory {
public:
    QNetworkAccessManager *create(QObject *parent) override {
        return new ValkyrieNetworkManager(parent);
    }
};

} // namespace
#include "model/thememanager.h"
#include "model/subtheme.h"
#include "model/globalproperties.h"
#include "model/presetmanager.h"
#include "model/colorpreset.h"
#include "model/nodevariable.h"
#include "model/variablemanager.h"
#include "utils/workspacemanager.h"
#include "utils/desktopmanager.h"

QMLWindow::QMLWindow(QWidget *parent, const QUrl& qmlUrl) : QMainWindow(parent),
    m_qml_url(qmlUrl)
{
    this->m_view = new QQuickView(this->windowHandle());

    // Must be set before any QML is loaded so tile/network requests get the UA.
    static ValkyrieNetworkFactory s_networkFactory;
    this->m_view->engine()->setNetworkAccessManagerFactory(&s_networkFactory);

    if(qmlUrl.isValid()){

        qmlRegisterSingletonType<ThemeManager>(
            "App.Theme",
            1, 0,
            "ThemeManager",
            ThemeManager::qmlSingletonProvider
        );

        qmlRegisterSingletonType<ThemeManager>(
            "App.Properties",
            1, 0,
            "GlobalProperties",
            GlobalProperties::qmlSingletonProvider
            );

        qmlRegisterSingletonType<PresetManager>(
            "App.Presets",
            1, 0,
            "PresetManager",
            PresetManager::qmlSingletonProvider
            );

        qmlRegisterUncreatableType<ColorPreset>(
            "App.Presets",
            1, 0,
            "ColorPreset",
            "ColorPreset is created by PresetManager"
            );

        qmlRegisterSingletonType<WorkspaceManager>(
            "App.Workspace",
            1, 0,
            "WorkspaceManager",
            WorkspaceManager::qmlSingletonProvider
            );

        qmlRegisterSingletonType<DesktopManager>(
            "App.Desktop",
            1, 0,
            "DesktopManager",
            DesktopManager::qmlSingletonProvider
            );

        qmlRegisterSingletonType<VariableManager>(
            "App.Variables",
            1, 0,
            "VariableManager",
            VariableManager::qmlSingletonProvider
            );

        qmlRegisterUncreatableType<NodeVariable>(
            "App.Variables",
            1, 0,
            "NodeVariable",
            "NodeVariable is created by VariableManager"
            );

        qmlRegisterSingletonType(
            QUrl("qrc:/components/Icons.qml"),
            "App.Icons", 1, 0,
            "Icons"
        );

        m_subTheme = new SubTheme(QUuid::createUuid().toString(QUuid::WithoutBraces));
        ThemeManager::instance()->addSubTheme(m_subTheme);

        this->view()->rootContext()->setContextProperty("theme", m_subTheme);
        this->view()->rootContext()->setContextProperty("window", this);        
        this->view()->engine()->addImportPath("qrc:///");
        this->view()->engine()->addImportPath("components");
        this->view()->engine()->rootContext()->setContextProperty("appDirPath", QCoreApplication::applicationDirPath());
    }

    this->setCentralWidget(QWidget::createWindowContainer(this->m_view, this));
    this->setContentsMargins(0, 0, 0, 0);
    this->setMinimumSize(50, 50);
}

QMLWindow::~QMLWindow()
{
    ThemeManager::instance()->removeSubTheme(m_subTheme);
    delete m_subTheme;
    destroyView();
}

void QMLWindow::destroyView()
{
    if (m_view) {
        delete m_view;
        m_view = nullptr;
    }
}

void QMLWindow::changeEvent(QEvent *e)
{
    static Qt::WindowStates prevWinState = Qt::WindowNoState;
    if (e->type() == QEvent::WindowStateChange)
    {

        if(prevWinState != windowState()){
            if(windowState() & Qt::WindowMaximized){
                emit windowMaximizing(true);
            }else if(windowState() & Qt::WindowMinimized){
                emit windowMinimizing(true);
            }else if(windowState() & Qt::WindowFullScreen){
                emit windowFullScreen(true);
            }else{
                if((prevWinState == Qt::WindowMaximized)){
                    emit windowMaximizing(false);
                }else if((prevWinState == Qt::WindowMinimized)){
                    emit windowMinimizing(false);
                }else if((prevWinState == Qt::WindowFullScreen)){
                    emit windowFullScreen(false);
                }
            }
        }

        prevWinState = windowState();
    }

    QWidget::changeEvent(e);
}

void QMLWindow::closeEvent(QCloseEvent *event)
{
    emit closeWindow();
    QMainWindow::closeEvent(event);
}

QUrl QMLWindow::source()
{
    return this->m_view->source();
}

void QMLWindow::showWindow(const QVector<PropertyPair> &properties)
{
    setContextProperties(properties);
}

void QMLWindow::setContextProperties(const QVector<PropertyPair> &properties)
{
    for(const PropertyPair& pair : properties){
        this->view()->rootContext()->setContextProperty(pair.name, pair.obj);
    }
    setQMLSourceUrl(this->m_qml_url);
}

void QMLWindow::setContextProperty(const QString &ctx, QObject *obj)
{
    this->m_view->rootContext()->setContextProperty(ctx, obj);
    setQMLSourceUrl(this->m_qml_url);
}

void QMLWindow::setQMLSourceUrl(const QUrl &url)
{
    this->m_qml_url = url;
    this->m_view->setSource(url);
}

QQuickView *QMLWindow::view()
{
    return this->m_view;
}
