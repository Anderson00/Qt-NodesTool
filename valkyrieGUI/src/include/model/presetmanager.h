#ifndef PRESETMANAGER_H
#define PRESETMANAGER_H

#include <QObject>
#include <QList>
#include <QQmlListProperty>
#include <QJSEngine>
#include "colorpreset.h"

class PresetManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<ColorPreset> presets READ presets NOTIFY presetsChanged)
    Q_PROPERTY(int count READ count NOTIFY presetsChanged)

public:
    static PresetManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QQmlListProperty<ColorPreset> presets();
    int count() const;

    Q_INVOKABLE void applyPreset(int index);
    Q_INVOKABLE ColorPreset* presetAt(int index) const;

signals:
    void presetsChanged();

private:
    explicit PresetManager(QObject* parent = nullptr);
    void loadBuiltinPresets();

    QList<ColorPreset*> m_presets;
};

#endif // PRESETMANAGER_H
