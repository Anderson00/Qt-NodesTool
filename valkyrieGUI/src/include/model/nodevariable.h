#ifndef NODEVARIABLE_H
#define NODEVARIABLE_H

#include <QObject>
#include <QString>
#include <QJsonObject>

class NodeVariable : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString id       READ id       CONSTANT)
    Q_PROPERTY(QString name     READ name     WRITE setName     NOTIFY nameChanged)
    Q_PROPERTY(QString type     READ type     CONSTANT)
    Q_PROPERTY(QString value    READ value    WRITE setValue    NOTIFY valueChanged)
    Q_PROPERTY(bool    readOnly READ readOnly WRITE setReadOnly NOTIFY readOnlyChanged)

public:
    struct Data {
        QString id;
        QString name;
        QString type;   // "STRING" | "NUMBER" | "BOOLEAN" | "COLOR" | "ARRAY"
        QString value;
        bool    readOnly = false;
    };

    static NodeVariable* create(const Data& d, QObject* parent = nullptr);
    static NodeVariable* fromJson(const QJsonObject& obj, QObject* parent = nullptr);

    QString id()       const { return m_id; }
    QString name()     const { return m_name; }
    QString type()     const { return m_type; }
    QString value()    const { return m_value; }
    bool    readOnly() const { return m_readOnly; }

    void setName(const QString& v);
    void setValue(const QString& v);
    void setReadOnly(bool v);

    QJsonObject toJson() const;

signals:
    void nameChanged();
    void valueChanged();
    void readOnlyChanged();

private:
    explicit NodeVariable(const Data& d, QObject* parent = nullptr);

    QString m_id;
    QString m_name;
    QString m_type;
    QString m_value;
    bool    m_readOnly = false;
};

#endif // NODEVARIABLE_H
