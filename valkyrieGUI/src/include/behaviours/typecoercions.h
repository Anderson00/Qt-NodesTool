#ifndef TYPECOERCIONS_H
#define TYPECOERCIONS_H

#include <QObject>
#include <QByteArray>

/**
 * @brief Type-coercion relay classes and factory.
 *
 * Used by ConnectionModel to transparently bridge signal/slot pairs whose
 * C++ types are incompatible but semantically equivalent (e.g. int ↔ double).
 *
 * Each Relay_XY_to_ZW class receives the source signal's parameter types and
 * re-emits with the destination slot's types. The relay is parented to the
 * ConnectionModel so it is destroyed automatically when the connection is torn down.
 *
 * Example: Vec2Input::outputXY(double,double) → BarChartViewer::appendToSet(int,double)
 *   → Relay_DD_to_ID bridges the mismatch invisibly.
 */

// ─── 1D relays ────────────────────────────────────────────────────────────────

class Relay_D_to_I : public QObject {
    Q_OBJECT
public: explicit Relay_D_to_I(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a) { emit fwd(int(a)); }
signals:      void fwd(int a);
};

class Relay_I_to_D : public QObject {
    Q_OBJECT
public: explicit Relay_I_to_D(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a) { emit fwd(double(a)); }
signals:      void fwd(double a);
};

class Relay_F_to_D : public QObject {
    Q_OBJECT
public: explicit Relay_F_to_D(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(float a) { emit fwd(double(a)); }
signals:      void fwd(double a);
};

class Relay_D_to_F : public QObject {
    Q_OBJECT
public: explicit Relay_D_to_F(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a) { emit fwd(float(a)); }
signals:      void fwd(float a);
};

// ─── 2D relays ────────────────────────────────────────────────────────────────

class Relay_DD_to_ID : public QObject {
    Q_OBJECT
public: explicit Relay_DD_to_ID(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b) { emit fwd(int(a), b); }
signals:      void fwd(int a, double b);
};

class Relay_DD_to_DI : public QObject {
    Q_OBJECT
public: explicit Relay_DD_to_DI(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b) { emit fwd(a, int(b)); }
signals:      void fwd(double a, int b);
};

class Relay_DD_to_II : public QObject {
    Q_OBJECT
public: explicit Relay_DD_to_II(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b) { emit fwd(int(a), int(b)); }
signals:      void fwd(int a, int b);
};

class Relay_ID_to_DD : public QObject {
    Q_OBJECT
public: explicit Relay_ID_to_DD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, double b) { emit fwd(double(a), b); }
signals:      void fwd(double a, double b);
};

class Relay_II_to_DD : public QObject {
    Q_OBJECT
public: explicit Relay_II_to_DD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, int b) { emit fwd(double(a), double(b)); }
signals:      void fwd(double a, double b);
};

class Relay_II_to_ID : public QObject {
    Q_OBJECT
public: explicit Relay_II_to_ID(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, int b) { emit fwd(a, double(b)); }
signals:      void fwd(int a, double b);
};

class Relay_DI_to_DD : public QObject {
    Q_OBJECT
public: explicit Relay_DI_to_DD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, int b) { emit fwd(a, double(b)); }
signals:      void fwd(double a, double b);
};

class Relay_DI_to_ID : public QObject {
    Q_OBJECT
public: explicit Relay_DI_to_ID(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, int b) { emit fwd(int(a), double(b)); }
signals:      void fwd(int a, double b);
};

// ─── bool ↔ numeric ──────────────────────────────────────────────────────────

class Relay_B_to_I : public QObject {
    Q_OBJECT
public: explicit Relay_B_to_I(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(bool a) { emit fwd(int(a)); }
signals:      void fwd(int a);
};

class Relay_I_to_B : public QObject {
    Q_OBJECT
public: explicit Relay_I_to_B(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a) { emit fwd(a != 0); }
signals:      void fwd(bool a);
};

class Relay_B_to_D : public QObject {
    Q_OBJECT
public: explicit Relay_B_to_D(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(bool a) { emit fwd(double(a)); }
signals:      void fwd(double a);
};

class Relay_D_to_B : public QObject {
    Q_OBJECT
public: explicit Relay_D_to_B(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a) { emit fwd(a != 0.0); }
signals:      void fwd(bool a);
};

// ─── QString ↔ numeric ───────────────────────────────────────────────────────

class Relay_S_to_D : public QObject {
    Q_OBJECT
public: explicit Relay_S_to_D(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(const QString& a) { emit fwd(a.toDouble()); }
signals:      void fwd(double a);
};

class Relay_D_to_S : public QObject {
    Q_OBJECT
public: explicit Relay_D_to_S(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a) { emit fwd(QString::number(a)); }
signals:      void fwd(QString a);
};

class Relay_S_to_I : public QObject {
    Q_OBJECT
public: explicit Relay_S_to_I(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(const QString& a) { emit fwd(a.toInt()); }
signals:      void fwd(int a);
};

class Relay_I_to_S : public QObject {
    Q_OBJECT
public: explicit Relay_I_to_S(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a) { emit fwd(QString::number(a)); }
signals:      void fwd(QString a);
};

// ─── int ↔ float ─────────────────────────────────────────────────────────────

class Relay_I_to_F : public QObject {
    Q_OBJECT
public: explicit Relay_I_to_F(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a) { emit fwd(float(a)); }
signals:      void fwd(float a);
};

class Relay_F_to_I : public QObject {
    Q_OBJECT
public: explicit Relay_F_to_I(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(float a) { emit fwd(int(a)); }
signals:      void fwd(int a);
};

// ─── 2D additional ───────────────────────────────────────────────────────────

class Relay_ID_to_II : public QObject {
    Q_OBJECT
public: explicit Relay_ID_to_II(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, double b) { emit fwd(a, int(b)); }
signals:      void fwd(int a, int b);
};

class Relay_II_to_DI : public QObject {
    Q_OBJECT
public: explicit Relay_II_to_DI(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, int b) { emit fwd(double(a), b); }
signals:      void fwd(double a, int b);
};

class Relay_DI_to_II : public QObject {
    Q_OBJECT
public: explicit Relay_DI_to_II(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, int b) { emit fwd(int(a), b); }
signals:      void fwd(int a, int b);
};

class Relay_ID_to_DI : public QObject {
    Q_OBJECT
public: explicit Relay_ID_to_DI(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, double b) { emit fwd(double(a), int(b)); }
signals:      void fwd(double a, int b);
};

// ─── 3D relays ────────────────────────────────────────────────────────────────

class Relay_DDD_to_III : public QObject {
    Q_OBJECT
public: explicit Relay_DDD_to_III(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b, double c) { emit fwd(int(a), int(b), int(c)); }
signals:      void fwd(int a, int b, int c);
};

class Relay_III_to_DDD : public QObject {
    Q_OBJECT
public: explicit Relay_III_to_DDD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, int b, int c) { emit fwd(double(a), double(b), double(c)); }
signals:      void fwd(double a, double b, double c);
};

class Relay_IDD_to_DDD : public QObject {
    Q_OBJECT
public: explicit Relay_IDD_to_DDD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, double b, double c) { emit fwd(double(a), b, c); }
signals:      void fwd(double a, double b, double c);
};

class Relay_DDD_to_IDD : public QObject {
    Q_OBJECT
public: explicit Relay_DDD_to_IDD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b, double c) { emit fwd(int(a), b, c); }
signals:      void fwd(int a, double b, double c);
};

class Relay_DDI_to_DDD : public QObject {
    Q_OBJECT
public: explicit Relay_DDI_to_DDD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b, int c) { emit fwd(a, b, double(c)); }
signals:      void fwd(double a, double b, double c);
};

class Relay_DDD_to_DDI : public QObject {
    Q_OBJECT
public: explicit Relay_DDD_to_DDI(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b, double c) { emit fwd(a, b, int(c)); }
signals:      void fwd(double a, double b, int c);
};

class Relay_IID_to_DDD : public QObject {
    Q_OBJECT
public: explicit Relay_IID_to_DDD(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(int a, int b, double c) { emit fwd(double(a), double(b), c); }
signals:      void fwd(double a, double b, double c);
};

class Relay_DDD_to_IID : public QObject {
    Q_OBJECT
public: explicit Relay_DDD_to_IID(QObject* p = nullptr) : QObject(p) {}
public slots: void rcv(double a, double b, double c) { emit fwd(int(a), int(b), c); }
signals:      void fwd(int a, int b, double c);
};

// ─── Factory ─────────────────────────────────────────────────────────────────

namespace TypeCoercions {
    /// Extracts the "(type1,type2,...)" parameter portion from a Qt method signature.
    /// e.g.  "outputXY(double,double)" → "(double,double)"
    QByteArray extractParams(const QByteArray& methodSig);

    /// Returns true if a coercion relay is available for this source→destination pair.
    bool isCoercible(const QByteArray& srcParams, const QByteArray& dstParams);

    /// Creates and returns the appropriate relay object (parented to @p parent),
    /// or nullptr if no coercion relay exists for this combination.
    QObject* createRelay(const QByteArray& srcParams, const QByteArray& dstParams,
                         QObject* parent = nullptr);
}

#endif // TYPECOERCIONS_H
