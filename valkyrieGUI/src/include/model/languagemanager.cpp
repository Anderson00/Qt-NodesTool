#include "languagemanager.h"
#include "globalproperties.h"
#include <behaviours/behaviourregistry.h>

#include <QQmlEngine>
#include <QCoreApplication>
#include <QDebug>

// ── Display names map ─────────────────────────────────────────────────────────

const QMap<QString, QString>& LanguageManager::displayNames()
{
    static const QMap<QString, QString> s_map = {
        { QStringLiteral("en"),    QStringLiteral("English")             },
        { QStringLiteral("pt_BR"), QStringLiteral("Português (Brasil)")  },
        { QStringLiteral("es"),    QStringLiteral("Español")             },
    };
    return s_map;
}

// ── Singleton ─────────────────────────────────────────────────────────────────

LanguageManager* LanguageManager::instance()
{
    static LanguageManager* s_instance = new LanguageManager();
    return s_instance;
}

QObject* LanguageManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*)
{
    return LanguageManager::instance();
}

LanguageManager::LanguageManager(QObject* parent) : QObject(parent) {}

// ── Engine registration ───────────────────────────────────────────────────────

void LanguageManager::registerEngine(QQmlEngine* engine)
{
    if (!engine || m_engines.contains(engine))
        return;

    m_engines.append(engine);

    // Auto-remove when the engine is destroyed (e.g. sub-window closed)
    connect(engine, &QObject::destroyed, this, [this, engine]() {
        m_engines.removeAll(engine);
    });
}

// ── Initial load (before engines exist) ──────────────────────────────────────

void LanguageManager::loadSavedLanguage()
{
    const QString saved = GlobalProperties::instance()->language();
    if (saved.isEmpty() || saved == QLatin1String("en"))
        return;

    const QString qmPath = QStringLiteral(":/i18n/Debugger_%1.qm").arg(saved);
    if (m_translator.load(qmPath)) {
        QCoreApplication::installTranslator(&m_translator);
        m_currentLanguage = saved;
        qInfo() << "LanguageManager: loaded language" << saved;
    } else {
        qWarning() << "LanguageManager: failed to load" << qmPath;
    }
}

// ── setLanguage ───────────────────────────────────────────────────────────────

void LanguageManager::setLanguage(const QString& code)
{
    if (code == m_currentLanguage)
        return;

    // 1. Remove current translator
    QCoreApplication::removeTranslator(&m_translator);

    if (code != QLatin1String("en")) {
        const QString qmPath = QStringLiteral(":/i18n/Debugger_%1.qm").arg(code);
        if (!m_translator.load(qmPath)) {
            qWarning() << "LanguageManager: failed to load" << qmPath;
            return;
        }
        QCoreApplication::installTranslator(&m_translator);
    }

    m_currentLanguage = code;

    // 2. Retranslate all registered QML engines
    for (QQmlEngine* engine : std::as_const(m_engines)) {
        if (engine)
            engine->retranslate();
    }

    // 3. Invalidate BehaviourRegistry cache so next discoverAll() re-translates
    BehaviourRegistry::instance().markDirty();

    // 4. Persist the choice
    GlobalProperties::instance()->setLanguage(code);

    emit languageChanged();
    qInfo() << "LanguageManager: language changed to" << code;
}

// ── Getters ───────────────────────────────────────────────────────────────────

QString LanguageManager::currentLanguage() const
{
    return m_currentLanguage;
}

QStringList LanguageManager::availableLanguages() const
{
    return displayNames().keys();
}

QString LanguageManager::displayName(const QString& code) const
{
    return displayNames().value(code, code);
}
