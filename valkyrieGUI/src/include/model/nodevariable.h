#ifndef NODEVARIABLE_H
#define NODEVARIABLE_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QVariant>

// ─────────────────────────────────────────────────────────────────────────────
// NodeVariable — single typed variable managed by VariableManager.
//
// Supported type strings (value always stored as serialised QString):
//   "STRING"  → any text             serialised as-is
//   "NUMBER"  → double               serialised as decimal string
//   "INT"     → integer              serialised as integer string
//   "BOOLEAN" → true / false         serialised as "true"/"false"
//   "COLOR"   → #RRGGBB hex          serialised as hex string
//   "ARRAY"   → list of doubles      serialised as CSV  "1,2,3"
//   "LIST"    → heterogeneous list   serialised as JSON array  "[1,\"a\",true]"
//   "DICT"    → key-value map        serialised as JSON object "{\"k\":\"v\"}"
//   "VEC2"    → 2D vector            serialised as "x,y"
//   "VEC3"    → 3D vector            serialised as "x,y,z"
// ─────────────────────────────────────────────────────────────────────────────
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
        QString type = "STRING";
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

    // Returns the value parsed into the appropriate Qt variant type.
    // STRING  → QVariant(QString)
    // NUMBER  → QVariant(double)    INT → QVariant(int)
    // BOOLEAN → QVariant(bool)
    // ARRAY   → QVariant(QList<double>)
    // LIST    → QVariant(QJsonArray stored as QString — caller parses)
    // DICT    → QVariant(QJsonObject stored as QString — caller parses)
    // VEC2    → QVariant(QPointF)   VEC3 → QVariant(QVector3D — stored as QList<double>)
    // COLOR   → QVariant(QString)   (hex string, unchanged)
    Q_INVOKABLE QVariant parsedValue() const;

    // Returns true for NUMBER, INT, VEC2, VEC3
    Q_INVOKABLE bool isNumericType() const;
    // Returns true for ARRAY, LIST, DICT
    Q_INVOKABLE bool isContainerType() const;

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
