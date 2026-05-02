#include "presetmanager.h"
#include "thememanager.h"

PresetManager* PresetManager::instance() {
    static PresetManager* _instance = new PresetManager();
    return _instance;
}

QObject* PresetManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    return PresetManager::instance();
}

PresetManager::PresetManager(QObject* parent) : QObject(parent) {
    loadBuiltinPresets();
}

void PresetManager::loadBuiltinPresets() {
    using D = ColorPreset::Data;

    auto add = [&](D d) {
        m_presets.append(ColorPreset::create(d, this));
    };

    add({ "Valkyrie Dark",
          QColor("#0D1117"), QColor("#161B22"), QColor("#1E2530"),
          QColor("#30363D"), QColor(13, 17, 23, 120),
          QColor("#7C6AF7"), QColor("#A78BFA"), QColor("#22D3EE"),
          QColor("#34D399"), QColor("#FBBF24"), QColor("#F87171"),
          QColor("#E6EDF3"), QColor("#8B949E"), QColor(124, 106, 247, 51) });

    add({ "Valkyrie Light",
          QColor("#F0F2F5"), QColor("#FFFFFF"), QColor("#E4E8EF"),
          QColor("#CBD5E1"), QColor(13, 17, 23, 25),
          QColor("#5B6AF0"), QColor("#8B5CF6"), QColor("#06B6D4"),
          QColor("#10B981"), QColor("#F59E0B"), QColor("#EF4444"),
          QColor("#1A1A2E"), QColor("#64748B"), QColor(91, 106, 240, 51) });

    add({ "Dracula",
          QColor("#282A36"), QColor("#21222C"), QColor("#343746"),
          QColor("#6272A4"), QColor(0, 0, 0, 153),
          QColor("#BD93F9"), QColor("#FF79C6"), QColor("#8BE9FD"),
          QColor("#50FA7B"), QColor("#FFB86C"), QColor("#FF5555"),
          QColor("#F8F8F2"), QColor("#6272A4"), QColor(189, 147, 249, 51) });

    add({ "Nord",
          QColor("#2E3440"), QColor("#3B4252"), QColor("#434C5E"),
          QColor("#4C566A"), QColor(0, 0, 0, 153),
          QColor("#88C0D0"), QColor("#81A1C1"), QColor("#5E81AC"),
          QColor("#A3BE8C"), QColor("#EBCB8B"), QColor("#BF616A"),
          QColor("#ECEFF4"), QColor("#D8DEE9"), QColor(136, 192, 208, 51) });

    add({ "Cyberpunk",
          QColor("#0D0D0D"), QColor("#1A1A1A"), QColor("#141414"),
          QColor("#333333"), QColor(0, 0, 0, 204),
          QColor("#FFE600"), QColor("#FF2D78"), QColor("#00F5FF"),
          QColor("#00FF9C"), QColor("#FF8C00"), QColor("#FF2D78"),
          QColor("#FFFFFF"), QColor("#888888"), QColor(255, 230, 0, 51) });

    add({ "Ocean",
          QColor("#0A1628"), QColor("#112240"), QColor("#1A3A5C"),
          QColor("#233554"), QColor(0, 0, 0, 170),
          QColor("#64FFDA"), QColor("#7F5AF0"), QColor("#38BDF8"),
          QColor("#2CB67D"), QColor("#FFCF40"), QColor("#FF6B6B"),
          QColor("#CCD6F6"), QColor("#8892B0"), QColor(100, 255, 218, 51) });

    add({ "Sunset",
          QColor("#1A1025"), QColor("#241533"), QColor("#2D1B42"),
          QColor("#3D2856"), QColor(0, 0, 0, 170),
          QColor("#FF6B35"), QColor("#FF4D6D"), QColor("#FFD166"),
          QColor("#06D6A0"), QColor("#FFD166"), QColor("#EF233C"),
          QColor("#F8EDEB"), QColor("#B8B5B9"), QColor(255, 107, 53, 51) });

    add({ "Forest",
          QColor("#1A2318"), QColor("#1E2B1C"), QColor("#243322"),
          QColor("#344A31"), QColor(0, 0, 0, 170),
          QColor("#4CAF50"), QColor("#8BC34A"), QColor("#00BCD4"),
          QColor("#4CAF50"), QColor("#FFC107"), QColor("#F44336"),
          QColor("#E8F5E9"), QColor("#A5C8A0"), QColor(76, 175, 80, 51) });

    add({ "Rose Pinheiro",
          QColor("#191724"), QColor("#1F1D2E"), QColor("#26233A"),
          QColor("#403D52"), QColor(0, 0, 0, 170),
          QColor("#EBBCBA"), QColor("#C4A7E7"), QColor("#9CCFD8"),
          QColor("#31748F"), QColor("#F6C177"), QColor("#EB6F92"),
          QColor("#E0DEF4"), QColor("#908CAA"), QColor(235, 188, 186, 51) });
}

QQmlListProperty<ColorPreset> PresetManager::presets() {
    return QQmlListProperty<ColorPreset>(this, &m_presets);
}

int PresetManager::count() const {
    return m_presets.size();
}

ColorPreset* PresetManager::presetAt(int index) const {
    if (index < 0 || index >= m_presets.size()) return nullptr;
    return m_presets.at(index);
}

void PresetManager::applyPreset(int index) {
    if (index < 0 || index >= m_presets.size()) return;
    const ColorPreset* p = m_presets.at(index);
    ThemeManager* tm = ThemeManager::instance();
    tm->setBackgroundColor(p->backgroundColor());
    tm->setSurfaceColor(p->surfaceColor());
    tm->setForegroundColor(p->foregroundColor());
    tm->setBorderColor(p->borderColor());
    tm->setShadowColor(p->shadowColor());
    tm->setPrimaryColor(p->primaryColor());
    tm->setSecondaryColor(p->secondaryColor());
    tm->setAccentColor(p->accentColor());
    tm->setSuccessColor(p->successColor());
    tm->setWarningColor(p->warningColor());
    tm->setDangerColor(p->dangerColor());
    tm->setTextColor(p->textColor());
    tm->setTextSecondaryColor(p->textSecondaryColor());
    tm->setSelectionColor(p->selectionColor());
}
