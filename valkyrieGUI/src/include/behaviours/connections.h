#ifndef CONNECTIONS_H
#define CONNECTIONS_H

#include <QObject>
#include <QList>
#include <QMetaMethod>
#include <model/connectionmodel.h>

class Behaviours;
class ConnectionModel;

class Connections : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString methodSignature READ methodSignature CONSTANT)
    Q_PROPERTY(ConnMethodType methodType READ methodType CONSTANT)
    Q_PROPERTY(PinType pinType READ pinType WRITE setPinType NOTIFY pinTypeChanged)
public:
    enum ConnMethodType {
        Method = 0, Signal, Slot, Contructor
    };
    Q_ENUM(ConnMethodType)

    /**
     * @brief Semantic type of a pin, used for visual coloring and (optionally)
     *        compatibility validation.
     *
     * AnyType (0) is the backward-compatible default: it accepts connections
     * from/to any other type, preserving the existing behaviour for all nodes
     * that don't declare explicit types.
     *
     * Color map used in ViewComponentRectV2.qml::pinColor():
     *   AnyType    → #888888 (grey)
     *   BoolType   → #ff4444 (red)
     *   IntType    → #44aaff (light blue)
     *   DoubleType → #44ff88 (green)
     *   StringType → #ffaa00 (orange)
     *   Vec2Type   → #9955ff (purple)
     *   Vec3Type   → #ff55cc (pink)
     *   ColorType  → #ffd700 (gold)
     *   ArrayType  → #ffff44 (yellow)
     *   DictType   → #44ffff (cyan)
     *   FlowType   → #ffffff (white)
     */
    enum PinType {
        AnyType    = 0,  ///< grey   — accepts anything (default, backward compat)
        BoolType   = 1,  ///< red    — boolean
        IntType    = 2,  ///< light blue — integer
        DoubleType = 3,  ///< green  — floating-point
        StringType = 4,  ///< orange — string / text
        Vec2Type   = 5,  ///< purple — 2D vector
        Vec3Type   = 6,  ///< pink   — 3D vector
        ColorType  = 7,  ///< gold   — colour value
        ArrayType  = 8,  ///< yellow — array / list
        DictType   = 9,  ///< cyan   — dictionary / map
        FlowType   = 10  ///< white  — execution flow pin
    };
    Q_ENUM(PinType)

    explicit Connections(Behaviours *obj, QMetaMethod metaMethod, QObject *parent = nullptr);
    ~Connections();

    QString methodSignature();
    ConnMethodType methodType();
    QMetaMethod metaMethod();

    PinType pinType() const { return m_pinType; }
    void    setPinType(PinType t) {
        if (m_pinType != t) { m_pinType = t; emit pinTypeChanged(); }
    }

    /**
     * @brief Returns true when the two pins are compatible for connection.
     *
     * Rules:
     *  - If either side is AnyType → always compatible.
     *  - Otherwise both types must be equal.
     *
     * Note: this is an *additional* semantic check on top of the existing
     * Qt method-signature coercion check in Behaviours::isConnectionCompatible().
     */
    static bool arePinTypesCompatible(PinType a, PinType b) {
        return (a == AnyType || b == AnyType || a == b);
    }

public slots:
    ConnectionModel *addConnection(Behaviours *output, QMetaMethod metaMethod);
    ConnectionModel *addConnection(ConnectionModel* conn);
    QList<ConnectionModel *> getAllConnections();

signals:
    void pinTypeChanged();

private:
    Behaviours *m_obj;
    QMetaMethod m_metaMethod;
    QList<ConnectionModel*> m_connections;
    PinType m_pinType = AnyType;
};

#endif // CONNECTIONS_H
