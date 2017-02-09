#ifndef DISPLAYCONTROLMODEL_H
#define DISPLAYCONTROLMODEL_H

#include "display/displaymodel.h"

#include <QAbstractListModel>

class DisplayControlModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit DisplayControlModel(dcc::display::DisplayModel *model, QObject *parent = 0);

    enum DisplayRole
    {
        ItemNameRole = Qt::DisplayRole,
        UnusedRole = Qt::UserRole,
        ItemDescriptionRole,
        ItemTypeRole,
    };

    enum ItemType
    {
        Duplicate,
        Extend,
        Specificed,
        Custom,
    };

    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role) const;

private:
    ItemType optionType(const int index) const;
    const QString optionName(const int index) const;
    const QString optionDescription(const int index) const;

private:
    dcc::display::DisplayModel *m_displayModel;
};

Q_DECLARE_METATYPE(DisplayControlModel::ItemType)

#endif // DISPLAYCONTROLMODEL_H
