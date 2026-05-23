#include "typecoercions.h"

namespace TypeCoercions {

// ─── extractParams ────────────────────────────────────────────────────────────
QByteArray extractParams(const QByteArray& methodSig)
{
    const int pos = methodSig.indexOf('(');
    return (pos >= 0) ? methodSig.mid(pos) : QByteArray("()");
}

// ─── Relay table ─────────────────────────────────────────────────────────────
struct RelayEntry {
    const char* srcParams;
    const char* dstParams;
    QObject* (*create)(QObject*);
};

#define MAKE(Cls) [](QObject* p) -> QObject* { return new Cls(p); }

static const RelayEntry s_relays[] = {
    // ── 1D ──────────────────────────────────────────────────────────────────
    {"(double)", "(int)",           MAKE(Relay_D_to_I)  },
    {"(int)",    "(double)",        MAKE(Relay_I_to_D)  },
    {"(float)",  "(double)",        MAKE(Relay_F_to_D)  },
    {"(double)", "(float)",         MAKE(Relay_D_to_F)  },
    // ── 2D ──────────────────────────────────────────────────────────────────
    {"(double,double)", "(int,double)",    MAKE(Relay_DD_to_ID) },
    {"(double,double)", "(double,int)",    MAKE(Relay_DD_to_DI) },
    {"(double,double)", "(int,int)",       MAKE(Relay_DD_to_II) },
    {"(int,double)",    "(double,double)", MAKE(Relay_ID_to_DD) },
    {"(int,int)",       "(double,double)", MAKE(Relay_II_to_DD) },
    {"(int,int)",       "(int,double)",    MAKE(Relay_II_to_ID) },
    {"(double,int)",    "(double,double)", MAKE(Relay_DI_to_DD) },
    {"(double,int)",    "(int,double)",    MAKE(Relay_DI_to_ID) },
    // ── 3D ──────────────────────────────────────────────────────────────────
    {"(double,double,double)", "(int,int,int)",          MAKE(Relay_DDD_to_III) },
    {"(int,int,int)",          "(double,double,double)", MAKE(Relay_III_to_DDD) },
};
#undef MAKE

static constexpr int s_count = static_cast<int>(sizeof(s_relays) / sizeof(s_relays[0]));

// ─── isCoercible ─────────────────────────────────────────────────────────────
bool isCoercible(const QByteArray& srcParams, const QByteArray& dstParams)
{
    for (int i = 0; i < s_count; ++i)
        if (srcParams == s_relays[i].srcParams && dstParams == s_relays[i].dstParams)
            return true;
    return false;
}

// ─── createRelay ─────────────────────────────────────────────────────────────
QObject* createRelay(const QByteArray& srcParams, const QByteArray& dstParams, QObject* parent)
{
    for (int i = 0; i < s_count; ++i)
        if (srcParams == s_relays[i].srcParams && dstParams == s_relays[i].dstParams)
            return s_relays[i].create(parent);
    return nullptr;
}

} // namespace TypeCoercions
