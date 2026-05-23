#include "colorinput.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(ColorInput, "Color Input", "Sends a selected color as hex string or RGB values to connected nodes", "input", 0, 2)

ColorInput::ColorInput(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(180);
    this->setContentHeight(180);
    this->setQmlBodyUrl("qrc:/behaviours/input/ColorInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setColorHex(QString)",
        "setAutoSend(bool)",
        "colorHexChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> ColorInput::loadInfos()
{
    return ColorInput::static_infos();
}

QMap<QString, QVariant> ColorInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "ColorInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "ColorInput"},
        {"desc",          "Sends a color as hex string or RGB values"},
        {"inputs_count",  "0"},
        {"outputs_count", "2"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString ColorInput::colorHex() const { return m_colorHex; }
bool    ColorInput::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void ColorInput::setColorHex(const QString& hex) {
    const QString normalized = hex.toUpper().trimmed();
    if (m_colorHex != normalized && QColor::isValidColor(normalized)) {
        m_colorHex = normalized;
        emit colorHexChanged();
        if (m_autoSend) send();
    }
}

void ColorInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void ColorInput::send() {
    QColor c(m_colorHex);
    emit outputString(m_colorHex);
    emit outputRGB(c.red(), c.green(), c.blue());
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject ColorInput::saveState() const {
    QJsonObject s;
    s["colorHex"] = m_colorHex;
    s["autoSend"] = m_autoSend;
    return s;
}

void ColorInput::loadState(const QJsonObject& s) {
    if (s.contains("colorHex")) setColorHex(s["colorHex"].toString());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
