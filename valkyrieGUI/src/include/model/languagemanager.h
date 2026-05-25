#ifndef LANGUAGEMANAGER_H
#define LANGUAGEMANAGER_H

#include <QObject>
#include <QTranslator>
#include <QStringList>
#include <QMap>
#include <QJSEngine>

class QQmlEngine;

/**
 * @brief Manages runtime language switching for the Valkyrie application.
 *
 * Owns a QTranslator, loads .qm files from embedded resources (:/i18n/),
 * and calls QQmlEngine::retranslate() on all registered engines so the
 * UI updates instantly without a restart.
 *
 * Exposed to QML as singleton "App.Language 1.0" / "LanguageManager".
 *
 * Usage from C++:
 *   LanguageManager::instance()->registerEngine(view->engine());
 *   LanguageManager::instance()->loadSavedLanguage();  // in main(), before MainWindow
 *
 * Usage from QML:
 *   import App.Language 1.0
 *   LanguageManager.setLanguage("pt_BR")
 *   LanguageManager.currentLanguage   // "en" | "pt_BR" | "es"
 *   LanguageManager.displayName("pt_BR")  // "Português (Brasil)"
 */
class LanguageManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString currentLanguage
               READ  currentLanguage
               WRITE setLanguage
               NOTIFY languageChanged)

    Q_PROPERTY(QStringList availableLanguages
               READ availableLanguages
               CONSTANT)

public:
    static LanguageManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    // ── Engine management ─────────────────────────────────────────────────────
    /// Register a QQmlEngine so it receives retranslate() on language change.
    /// Automatically deregisters when the engine is destroyed.
    void registerEngine(QQmlEngine* engine);

    // ── Initial load ─────────────────────────────────────────────────────────
    /// Call from main() after registering the singleton but before creating
    /// MainWindow. Installs the saved language translator silently (no
    /// retranslate() call, engines don't exist yet).
    void loadSavedLanguage();

    // ── Properties ────────────────────────────────────────────────────────────
    QString     currentLanguage()    const;
    QStringList availableLanguages() const;

    /// Human-readable display name for a language code.
    Q_INVOKABLE QString displayName(const QString& code) const;

    /// Switch the active language. Reloads the translator, calls retranslate()
    /// on all registered engines, and persists the choice to GlobalProperties.
    Q_INVOKABLE void setLanguage(const QString& code);

signals:
    void languageChanged();

private:
    explicit LanguageManager(QObject* parent = nullptr);

    QString            m_currentLanguage = QStringLiteral("en");
    QTranslator        m_translator;
    QList<QQmlEngine*> m_engines;

    static const QMap<QString, QString>& displayNames();
};

#endif // LANGUAGEMANAGER_H
