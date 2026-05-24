#ifndef VARIABLEREADER_H
#define VARIABLEREADER_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

// ─────────────────────────────────────────────────────────────────────────────
// VariableReader — reads a NodeVariable from VariableManager and emits its
// value as signals whenever the variable changes. Reactive: automatically
// re-emits when VariableManager::variablesChanged fires.
// ─────────────────────────────────────────────────────────────────────────────
class VariableReader : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString selectedId   READ selectedId   WRITE setSelectedId   NOTIFY selectedIdChanged)
    Q_PROPERTY(QString selectedName READ selectedName                        NOTIFY selectedIdChanged)
    Q_PROPERTY(QString currentValue READ currentValue                        NOTIFY currentValueChanged)
    Q_PROPERTY(QString currentType  READ currentType                         NOTIFY selectedIdChanged)

public:
    explicit VariableReader(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString selectedId()   const { return m_selectedId; }
    QString selectedName() const;
    QString currentValue() const { return m_currentValue; }
    QString currentType()  const;

public slots:
    void setSelectedId(const QString& id);

signals:
    void outputValue(double result);
    void outputText(QString result);
    void outputBool(bool result);

    void selectedIdChanged();
    void currentValueChanged();

private slots:
    void onVariablesChanged();

private:
    void emitCurrentValue();

    QString m_selectedId;
    QString m_currentValue;
};

#endif // VARIABLEREADER_H
