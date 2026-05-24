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
    // ── 1D numeric ───────────────────────────────────────────────────────────
    {"(double)", "(int)",           MAKE(Relay_D_to_I)  },
    {"(int)",    "(double)",        MAKE(Relay_I_to_D)  },
    {"(float)",  "(double)",        MAKE(Relay_F_to_D)  },
    {"(double)", "(float)",         MAKE(Relay_D_to_F)  },
    {"(int)",    "(float)",         MAKE(Relay_I_to_F)  },
    {"(float)",  "(int)",           MAKE(Relay_F_to_I)  },
    // ── 1D bool ↔ numeric ────────────────────────────────────────────────────
    {"(bool)",   "(int)",           MAKE(Relay_B_to_I)  },
    {"(int)",    "(bool)",          MAKE(Relay_I_to_B)  },
    {"(bool)",   "(double)",        MAKE(Relay_B_to_D)  },
    {"(double)", "(bool)",          MAKE(Relay_D_to_B)  },
    // ── 1D QString ↔ numeric ─────────────────────────────────────────────────
    {"(QString)", "(double)",       MAKE(Relay_S_to_D)  },
    {"(double)",  "(QString)",      MAKE(Relay_D_to_S)  },
    {"(QString)", "(int)",          MAKE(Relay_S_to_I)  },
    {"(int)",     "(QString)",      MAKE(Relay_I_to_S)  },
    // ── 2D ──────────────────────────────────────────────────────────────────
    {"(double,double)", "(int,double)",    MAKE(Relay_DD_to_ID) },
    {"(double,double)", "(double,int)",    MAKE(Relay_DD_to_DI) },
    {"(double,double)", "(int,int)",       MAKE(Relay_DD_to_II) },
    {"(int,double)",    "(double,double)", MAKE(Relay_ID_to_DD) },
    {"(int,double)",    "(int,int)",       MAKE(Relay_ID_to_II) },
    {"(int,double)",    "(double,int)",    MAKE(Relay_ID_to_DI) },
    {"(int,int)",       "(double,double)", MAKE(Relay_II_to_DD) },
    {"(int,int)",       "(int,double)",    MAKE(Relay_II_to_ID) },
    {"(int,int)",       "(double,int)",    MAKE(Relay_II_to_DI) },
    {"(double,int)",    "(double,double)", MAKE(Relay_DI_to_DD) },
    {"(double,int)",    "(int,double)",    MAKE(Relay_DI_to_ID) },
    {"(double,int)",    "(int,int)",       MAKE(Relay_DI_to_II) },
    // ── 3D ──────────────────────────────────────────────────────────────────
    {"(double,double,double)", "(int,int,int)",          MAKE(Relay_DDD_to_III) },
    {"(int,int,int)",          "(double,double,double)", MAKE(Relay_III_to_DDD) },
    {"(double,double,double)", "(int,double,double)",    MAKE(Relay_DDD_to_IDD) },
    {"(int,double,double)",    "(double,double,double)", MAKE(Relay_IDD_to_DDD) },
    {"(double,double,double)", "(double,double,int)",    MAKE(Relay_DDD_to_DDI) },
    {"(double,double,int)",    "(double,double,double)", MAKE(Relay_DDI_to_DDD) },
    {"(double,double,double)", "(int,int,double)",       MAKE(Relay_DDD_to_IID) },
    {"(int,int,double)",       "(double,double,double)", MAKE(Relay_IID_to_DDD) },
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
