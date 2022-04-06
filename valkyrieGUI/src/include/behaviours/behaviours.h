#ifndef BEHAVIOURS_H
#define BEHAVIOURS_H

#include <QMetaMethod>
#include <QObject>
#include <QUuid>
#include <QMap>
#include <QList>
#include <QString>
#include <QUrl>

class Behaviours : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title READ title CONSTANT)
    Q_PROPERTY(QString qmlBodyUrl READ qmlBodyUrl CONSTANT)

public:
    enum Type{
        CPP = 0, DLL, PYTHON
    };
    Q_ENUM(Type)

    explicit Behaviours(QObject *parent = nullptr);

    static QMap<QString, QVariant> static_infos();

    virtual QMap<QString, QVariant> loadInfos() = 0;
    virtual void loadConnections();
    const QString &qmlBodyUrl();
    const QString &title();

    const QMap<QString, QMetaMethod>& inputConns();
    const QMap<QString, QMetaMethod>& outputConns();
    const QList<QString>& listOfExclusions();

    int qtdInputs();
    int qtdOutputs();

    const QMetaMethod* getMetaMethodFromMethodSignature(const QString& signature);

    static const QString &getUuid();

    void setQmlBodyUrl(const QString &newQmlBodyUrl);

public slots:
    void start();

signals:

protected:
    void setInputConns(QMap<QString, QMetaMethod> inputConns);
    void setOutputConns(QMap<QString, QMetaMethod> outputConns);
    void addInputOutputExclusion(const QList<QString>& exclusionConnections);

private:
    void loaderOfInfosInFields();

    QString m_title;
    QString m_qmlBodyUrl;

    QMap<QString, QMetaMethod> m_input_conns;
    QMap<QString, QMetaMethod> m_output_conns;

    QList<QString> m_listOfExclusions;
};

#endif // BEHAVIOURS_H
