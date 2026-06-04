#ifndef VARIABLEMONITOR_H
#define VARIABLEMONITOR_H

#include <QObject>
#include <QJsonObject>
#include <QStringList>
#include <behaviours/behaviours.h>

// ─────────────────────────────────────────────────────────────────────────────
// VariableMonitor — dashboard node that displays a user-selected set of
// global variables in real time inside the workspace. No inputs or outputs;
// purely a visual inspection tool.
// ─────────────────────────────────────────────────────────────────────────────
class VariableMonitor : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QStringList watchedIds READ watchedIds NOTIFY watchedIdsChanged)

public:
    explicit VariableMonitor(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QStringList watchedIds() const { return m_watchedIds; }

public slots:
    Q_INVOKABLE void addWatchId(const QString& id);
    Q_INVOKABLE void removeWatchId(const QString& id);
    Q_INVOKABLE void clearWatch();

signals:
    void watchedIdsChanged();

private:
    QStringList m_watchedIds;
};

#endif // VARIABLEMONITOR_H
