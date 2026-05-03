#include "nodeundocommands.h"
#include "viewportwindow.h"
#include "behaviours/behaviours.h"

// ── AddNodeCommand ────────────────────────────────────────────────────────────

AddNodeCommand::AddNodeCommand(ViewPortWindow* vp, NodeState data, QUndoCommand* parent)
    : QUndoCommand(QObject::tr("Add Node"), parent), m_vp(vp), m_data(std::move(data)) {}

void AddNodeCommand::undo() {
    auto* beh = m_vp->searchBehaviourFromUUID(m_data.uuid);
    if (!beh) return;
    // Capture current geometry so redo restores correct position
    m_data.x     = beh->x();
    m_data.y     = beh->y();
    m_data.w     = beh->width();
    m_data.h     = beh->height();
    m_data.title = beh->title();
    m_vp->removeBehaviourObject(beh);
}

void AddNodeCommand::redo() {
    m_vp->addBehaviourWithUuid(m_data.path, m_data.infos, m_data.uuid,
                               m_data.x, m_data.y, m_data.w, m_data.h, m_data.title);
}

// ── RemoveNodeCommand ─────────────────────────────────────────────────────────

RemoveNodeCommand::RemoveNodeCommand(ViewPortWindow* vp, NodeState data, QList<ConnState> conns, QUndoCommand* parent)
    : QUndoCommand(QObject::tr("Remove Node"), parent),
      m_vp(vp), m_data(std::move(data)), m_conns(std::move(conns)) {}

void RemoveNodeCommand::undo() {
    m_vp->addBehaviourWithUuid(m_data.path, m_data.infos, m_data.uuid,
                               m_data.x, m_data.y, m_data.w, m_data.h, m_data.title);
    for (const ConnState& c : std::as_const(m_conns))
        m_vp->addConnectionByUuids(c.outputUuid, c.outputMethod, c.inputUuid, c.inputMethod);
}

void RemoveNodeCommand::redo() {
    auto* beh = m_vp->searchBehaviourFromUUID(m_data.uuid);
    if (beh) m_vp->removeBehaviourObject(beh);
}

// ── MoveNodeCommand ───────────────────────────────────────────────────────────

MoveNodeCommand::MoveNodeCommand(ViewPortWindow* vp, QString uuid,
                                 double oldX, double oldY, double newX, double newY,
                                 QUndoCommand* parent)
    : QUndoCommand(QObject::tr("Move Node"), parent),
      m_vp(vp), m_uuid(std::move(uuid)),
      m_oldX(oldX), m_oldY(oldY), m_newX(newX), m_newY(newY) {}

void MoveNodeCommand::undo() {
    auto* beh = m_vp->searchBehaviourFromUUID(m_uuid);
    if (beh) { beh->setX(m_oldX); beh->setY(m_oldY); }
}

void MoveNodeCommand::redo() {
    auto* beh = m_vp->searchBehaviourFromUUID(m_uuid);
    if (beh) { beh->setX(m_newX); beh->setY(m_newY); }
}

bool MoveNodeCommand::mergeWith(const QUndoCommand* other) {
    if (other->id() != id()) return false;
    const auto* o = static_cast<const MoveNodeCommand*>(other);
    if (o->m_uuid != m_uuid) return false;
    m_newX = o->m_newX;
    m_newY = o->m_newY;
    return true;
}

// ── AddConnectionCommand ──────────────────────────────────────────────────────

AddConnectionCommand::AddConnectionCommand(ViewPortWindow* vp, ConnState data, QUndoCommand* parent)
    : QUndoCommand(QObject::tr("Add Connection"), parent), m_vp(vp), m_data(std::move(data)) {}

void AddConnectionCommand::undo() {
    m_vp->removeConnectionByUuids(m_data.outputUuid, m_data.outputMethod,
                                   m_data.inputUuid,  m_data.inputMethod);
}

void AddConnectionCommand::redo() {
    m_vp->addConnectionByUuids(m_data.outputUuid, m_data.outputMethod,
                                m_data.inputUuid,  m_data.inputMethod);
}

// ── RemoveConnectionCommand ───────────────────────────────────────────────────

RemoveConnectionCommand::RemoveConnectionCommand(ViewPortWindow* vp, ConnState data, QUndoCommand* parent)
    : QUndoCommand(QObject::tr("Remove Connection"), parent), m_vp(vp), m_data(std::move(data)) {}

void RemoveConnectionCommand::undo() {
    m_vp->addConnectionByUuids(m_data.outputUuid, m_data.outputMethod,
                                m_data.inputUuid,  m_data.inputMethod);
}

void RemoveConnectionCommand::redo() {
    m_vp->removeConnectionByUuids(m_data.outputUuid, m_data.outputMethod,
                                   m_data.inputUuid,  m_data.inputMethod);
}
