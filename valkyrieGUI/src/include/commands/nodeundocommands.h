#pragma once

#include <QUndoCommand>
#include <QString>
#include <QJsonObject>
#include <QList>

class ViewPortWindow;

struct NodeState {
    QString uuid, path, title;
    QJsonObject infos;
    double x = 0, y = 0, w = 0, h = 0;
    QJsonObject state;  // Internal node state (saveState/loadState)
};

struct ConnState {
    QString outputUuid, outputMethod, inputUuid, inputMethod;
};

class AddNodeCommand : public QUndoCommand {
public:
    AddNodeCommand(ViewPortWindow* vp, NodeState data, QUndoCommand* parent = nullptr);
    void undo() override;
    void redo() override;
private:
    ViewPortWindow* m_vp;
    NodeState m_data;
};

class RemoveNodeCommand : public QUndoCommand {
public:
    RemoveNodeCommand(ViewPortWindow* vp, NodeState data, QList<ConnState> conns, QUndoCommand* parent = nullptr);
    void undo() override;
    void redo() override;
private:
    ViewPortWindow* m_vp;
    NodeState m_data;
    QList<ConnState> m_conns;
};

class MoveNodeCommand : public QUndoCommand {
public:
    MoveNodeCommand(ViewPortWindow* vp, QString uuid,
                    double oldX, double oldY, double newX, double newY,
                    QUndoCommand* parent = nullptr);
    void undo() override;
    void redo() override;
    bool mergeWith(const QUndoCommand* other) override;
    int id() const override { return 1001; }
private:
    ViewPortWindow* m_vp;
    QString m_uuid;
    double m_oldX, m_oldY, m_newX, m_newY;
};

class ResizeNodeCommand : public QUndoCommand {
public:
    ResizeNodeCommand(ViewPortWindow* vp, QString uuid,
                      double oldX, double oldY, double oldW, double oldH,
                      double newX, double newY, double newW, double newH,
                      QUndoCommand* parent = nullptr);
    void undo() override;
    void redo() override;
private:
    ViewPortWindow* m_vp;
    QString m_uuid;
    double m_oldX, m_oldY, m_oldW, m_oldH;
    double m_newX, m_newY, m_newW, m_newH;
};

class AddConnectionCommand : public QUndoCommand {
public:
    AddConnectionCommand(ViewPortWindow* vp, ConnState data, QUndoCommand* parent = nullptr);
    void undo() override;
    void redo() override;
private:
    ViewPortWindow* m_vp;
    ConnState m_data;
};

class RemoveConnectionCommand : public QUndoCommand {
public:
    RemoveConnectionCommand(ViewPortWindow* vp, ConnState data, QUndoCommand* parent = nullptr);
    void undo() override;
    void redo() override;
private:
    ViewPortWindow* m_vp;
    ConnState m_data;
};
