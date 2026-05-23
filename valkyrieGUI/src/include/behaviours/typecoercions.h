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
