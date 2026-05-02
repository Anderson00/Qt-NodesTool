#ifndef PRESETMANAGER_H
#define PRESETMANAGER_H

#include <QObject>
#include <QList>
#include <QQmlListProperty>
#include <QJSEngine>
#include "colorpreset.h"

class QQmlEngine;

class PresetManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<ColorPreset> presets READ presets NOTIFY presetsChanged)
    Q_PROPERTY(int count       READ count       NOTIFY presetsChanged)
    Q_PROPERTY(int customCount READ customCount NOTIFY presetsChanged)

public:
    static PresetManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QQmlListProperty<ColorPreset> presets();
    int count()       const;
    int customCount() const;

    // Apply
    Q_INVOKABLE void applyPreset(int index);

    // CRUD (custom presets only)
    Q_INVOKABLE void saveCurrentAsPreset(const QString& name);
    Q_INVOKABLE bool removePreset(const QString& id);
    Q_INVOKABLE void renamePreset(const QString& id, const QString& newName);

    // Lookup
    Q_INVOKABLE ColorPreset* presetAt(int index) const;
    Q_INVOKABLE ColorPreset* presetById(const QString& id) const;

    // Persistence
    Q_INVOKABLE void saveToFile();
    Q_INVOKABLE void loadFromFile();

signals:
    void presetsChanged();

private:
    explicit PresetManager(QObject* parent = nullptr);
    void loadBuiltinPresets();
    void autoSave();
    QString presetsFilePath() const;

    QList<ColorPreset*> m_presets;
};

#endif // PRESETMANAGER_H
