#ifndef VARIABLEWRITER_H
#define VARIABLEWRITER_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

// ─────────────────────────────────────────────────────────────────────────────
// VariableWriter — writes an incoming value into a VariableManager variable.
// Accepts double, string, and bool inputs; converts to the variable's type.
// ─────────────────────────────────────────────────────────────────────────────
class VariableWriter : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString selectedId   READ selectedId  WRITE setSelectedId  NOTIFY selectedIdChanged)
    Q_PROPERTY(QString selectedName READ selectedName                      NOTIFY selectedIdChanged)
    Q_PROPERTY(QString lastValue    READ lastValue                         NOTIFY lastValueChanged)
    Q_PROPERTY(QString currentType  READ currentType                       NOTIFY selectedIdChanged)

public:
    explicit VariableWriter(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString selectedId()   const { return m_selectedId; }
    QString selectedName() const;
    QString lastValue()    const { return m_lastValue; }
    QString currentType()  const;

public slots:
    void setSelectedId(const QString& id);
    void setInput(double value);
    void setText(const QString& value);
    void setBool(bool value);

signals:
    void selectedIdChanged();
    void lastValueChanged();

private:
    void writeValue(const QString& serialised);

    QString m_selectedId;
    QString m_lastValue;
};

#endif // VARIABLEWRITER_H
