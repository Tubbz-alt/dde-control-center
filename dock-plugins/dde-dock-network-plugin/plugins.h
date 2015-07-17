#ifndef PLUGINS_H
#define PLUGINS_H

#include <QMap>
#include <QObject>
#include <QString>

#include <dock/dockconstants.h>
#include <dock/dockplugininterface.h>
#include <dock/dockpluginproxyinterface.h>

#include "plugincomponentinterface.h"

class QLabel;
class NetworkPlugin : public QObject, public DockPluginInterface
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID DockPluginInterface_iid FILE "dde-dock-network-plugin.json")
    Q_INTERFACES(DockPluginInterface)

public:
    NetworkPlugin();
    ~NetworkPlugin() Q_DECL_OVERRIDE;

    void init(DockPluginProxyInterface *proxy) Q_DECL_OVERRIDE;

    QString name() Q_DECL_OVERRIDE;

    QStringList uuids() Q_DECL_OVERRIDE;
    QString getTitle(QString uuid) Q_DECL_OVERRIDE;
    QWidget * getItem(QString uuid) Q_DECL_OVERRIDE;
    QWidget * getApplet(QString uuid) Q_DECL_OVERRIDE;
    void changeMode(Dock::DockMode newMode, Dock::DockMode oldMode) Q_DECL_OVERRIDE;

    QString getMenuContent(QString uuid) Q_DECL_OVERRIDE;
    void invokeMenuItem(QString uuid, QString itemId, bool checked) Q_DECL_OVERRIDE;

private:
    DockPluginProxyInterface * m_proxy;
    QMap<QString, PluginComponentInterface*> m_items;
};

#endif // PLUGINS_H
