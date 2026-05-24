#ifndef VARIABLEMANAGER_H
#define VARIABLEMANAGER_H

#include <QObject>
#include <QList>
#include <QVariant>
#include <QQmlListProperty>
#include "nodevariable.h"

class QQmlEngine;
class QJSEngine;

class VariableManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<NodeVariable> variables READ variables NOTIFY variablesChanged)
    Q_PROPERTY(int count READ count NOTIFY variablesChanged)

public:
    static VariableManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QQmlListProperty<NodeVariable> variables();
    int count() const;

    Q_INVOKABLE NodeVariable* addVariable(const QString& name, const QString& type,
                                           const QString& value, bool readOnly = false);
    Q_INVOKABLE NodeVariable* addInt(const QString& name, int value, bool readOnly = false);
    Q_INVOKABLE NodeVariable* addList(const QString& name, const QString& jsonArray, bool readOnly = false);
    Q_INVOKABLE NodeVariable* addDict(const QString& name, const QString& jsonObject, bool readOnly = false);
    Q_INVOKABLE NodeVariable* addVec2(const QString& name, double x, double y, bool readOnly = false);
    Q_INVOKABLE NodeVariable* addVec3(const QString& name, double x, double y, double z, bool readOnly = false);
    Q_INVOKABLE bool          removeVariable(const QString& id);
    Q_INVOKABLE NodeVariable* variableById(const QString& id) const;
    Q_INVOKABLE NodeVariable* variableAt(int index) const;
    Q_INVOKABLE void          setVariableValue(const QString& id, const QString& value);
    Q_INVOKABLE void          setVariableReadOnly(const QString& id, bool readOnly);
    Q_INVOKABLE QVariant      getValue(const QString& id) const;
    Q_INVOKABLE QVariant      getTypedValue(const QString& id) const;

    Q_INVOKABLE void saveToFile();
    Q_INVOKABLE void loadFromFile();

signals:
    void variablesChanged();

private:
    explicit VariableManager(QObject* parent = nullptr);
    QString variablesFilePath() const;
    void autoSave();

    QList<NodeVariable*> m_variables;
};

#endif // VARIABLEMANAGER_H
