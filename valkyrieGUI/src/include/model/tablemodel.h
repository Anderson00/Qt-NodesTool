#ifndef TABLEMODEL_H
#define TABLEMODEL_H

#include <QObject>
#include <QVariant>
#include <QByteArray>
#include <QAbstractTableModel>
#include <QList>
#include <QHash>
#include <QPair>
#include <QModelIndex>

class TableModel : public QAbstractTableModel
{
    Q_OBJECT

public:
    TableModel(QObject *parent = 0);
    TableModel(QList<QPair<QString, QString> > listofPairs, QObject *parent = 0);

    int rowCount(const QModelIndex &parent) const override{
        Q_UNUSED(parent);
        return listOfPairs.size();
    }
    int columnCount(const QModelIndex &parent) const override{
        Q_UNUSED(parent);
        return 2;
    }

    QVariant data(const QModelIndex &index, int role) const override{
        if (!index.isValid())
            return QVariant();

        if (index.row() >= listOfPairs.size() || index.row() < 0)
            return QVariant();

        if (role == Qt::DisplayRole) {
            QPair<QString, QString> pair = listOfPairs.at(index.row());

            if (index.column() == 0)
                return pair.first;
            else if (index.column() == 1)
                return pair.second;
        }
        return QVariant();
    }

    QVariant headerData(int section, Qt::Orientation orientation, int role) const override{
        if (role != Qt::DisplayRole)
            return QVariant();

        if (orientation == Qt::Horizontal) {
            switch (section) {
                case 0:
                    return tr("Name");

                case 1:
                    return tr("Address");

                default:
                    return QVariant();
            }
        }
        return QVariant();
    }

    Qt::ItemFlags flags(const QModelIndex &index) const override{
        if (!index.isValid())
            return Qt::ItemIsEnabled;

        return QAbstractTableModel::flags(index) | Qt::ItemIsEditable;
    }

    QList< QPair<QString, QString> > TableModel::getList()
    {

        return listOfPairs;
    }

    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override{
        if (index.isValid() && role == Qt::EditRole) {
            int row = index.row();

            QPair<QString, QString> p = listOfPairs.value(row);

            if (index.column() == 0)
                p.first = value.toString();
            else if (index.column() == 1)
                p.second = value.toString();
            else
                return false;

            listOfPairs.replace(row, p);
            emit(dataChanged(index, index));

            return true;
        }

        return false;
    }

    bool insertRows(int position, int rows, const QModelIndex &index = QModelIndex()) override{
        Q_UNUSED(index);
        beginInsertRows(QModelIndex(), position, position + rows - 1);

        for (int row = 0; row < rows; ++row) {
            QPair<QString, QString> pair(" ", " ");
            listOfPairs.insert(position, pair);
        }

        endInsertRows();
        return true;
    }

    bool removeRows(int position, int rows, const QModelIndex &index = QModelIndex()) override{
        Q_UNUSED(index);
        beginRemoveRows(QModelIndex(), position, position + rows - 1);

        for (int row = 0; row < rows; ++row) {
            listOfPairs.removeAt(position);
        }

        endRemoveRows();
        return true;
    }

    QHash<int, QByteArray> roleNames() const override{
        return { {Qt::DisplayRole, "display"} };
    }

public slots:
    void addPar(QString nome, QString address){
        listOfPairs.push_back(QPair<QString, QString>(nome, address));
    }

private:
    QList<QPair<QString, QString> > listOfPairs;
};

#endif // TABLEMODEL_H
