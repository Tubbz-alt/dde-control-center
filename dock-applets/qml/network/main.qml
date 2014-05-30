import QtQuick 2.0
import QtQuick.Window 2.1
import Deepin.DockApplet 1.0
import Deepin.Widgets 1.0
import DBus.Com.Deepin.Daemon.Network 1.0
import DBus.Com.Deepin.Daemon.Bluetooth 1.0
import DBus.Com.Deepin.Api.Graphic 1.0
import "../widgets/"

DockApplet{
    title: "Network"
    appid: "AppletNetwork"
    icon: getIcon()

    property var dconstants: DConstants {}
    property var activeConnections: unmarshalJSON(dbusNetwork.activeConnections)

    // Graphic
    property var dbusGraphic: Graphic {}
    property string iconBgDataUri: {
        if(dbusNetwork.state == 70){
            var path = "network/network_on.png"
        }
        else{
            var path = "network/network_off.png"
        }
        return getIconDataUri(path)
    }
    property var subImageList: ListModel{
        function getTypeIndex(type){
            for(var i=0; i<subImageList.count; i++){
                var imageInfo = subImageList.get(i)
                if(imageInfo.type == type){
                    return i
                }
            }
            return -1

        }
    }

    function getIcon(){
        var iconDataUri = iconBgDataUri
        for(var i=0; i<subImageList.count; i++){
            var imageInfo = subImageList.get(i)
            iconDataUri = dbusGraphic.CompositeImageUri(
                iconDataUri, 
                getIconDataUri(imageInfo.imagePath),
                imageInfo.x,
                imageInfo.y,
                "png"
            )
        }
        print("==> [info] network icon update...")
        return iconDataUri
    }

    function getIconDataUri(path){
        return dbusGraphic.ConvertImageToDataUri(getIconUrl(path).split("://")[1])
    }

    property var positions: {
        "vpn": [6, 6],
        "bluetooth": [6, 19],
        "3g": [19, 6],
        "wifi": [19, 19]
    }

    function updateState(type, show, enabled){
        var index = subImageList.getTypeIndex(type)
        if(show){
            var imagePath = "network/" + type + "_"
            if(enabled){
                imagePath += "on.png"
            }
            else{
                imagePath += "off.png"
            }
            if(index == -1){
                subImageList.append({
                    "type": type,
                    "imagePath": imagePath,
                    "x": positions[type][0],
                    "y": positions[type][1]
                })
            }
            else{
                var info = subImageList.get(index)
                info.imagePath = imagePath
            }
        }
        else{
            if(index != -1){
                subImageList.remove(index)
            }
        }
    }

    // vpn
    property var nmConnections: unmarshalJSON(dbusNetwork.connections)
    property var vpnConnections: nmConnections["vpn"]
    property var activeDevice: getActiveDevice()
    property int activeVpnIndex: {
        for(var i in activeConnections){
            if(activeConnections[i].Vpn){
                return i
            }
        }
        return -1
    }

    onActiveVpnIndexChanged: {
        var vpnShow = vpnConnections ? vpnConnections.length > 0 : false
        var vpnEnabled = activeVpnIndex != -1
        updateState("vpn", vpnShow, vpnEnabled)
    }
    onVpnConnectionsChanged: {
        var vpnShow = vpnConnections ? vpnConnections.length > 0 : false
        var vpnEnabled = activeVpnIndex != -1
        updateState("vpn", vpnShow, vpnEnabled)
    }

    // bluetooth
    property var dbusBluetooth: Bluetooth {}
    property var adapters: dbusBluetooth.adapters ? unmarshalJSON(dbusBluetooth.adapters) : ""

    onAdaptersChanged: {
        var show = adapters.length > 0
        var enabled = dbusBluetooth.powered ? dbusBluetooth.powered : false
        updateState("bluetooth", show, enabled)
    }

    property int xEdgePadding: 10

    function getActiveDevice(){
        for(var i in wirelessDevices){
            var info = wirelessDevices[i]
            if(info.ActiveAp != "/" && info.State == 100){
                return info
            }
        }
        return null
    }

    function showNetwork(id){
        dbusControlCenter.ShowModule("network")
    }

    function hideNetwork(id){
        set_hide_applet("network")
    }

    onActivate: {
        showNetwork(0)
    }

    menu: Menu {
        Component.onCompleted: {
            addItem("_Run", showNetwork);
            addItem("_Undock", hideNetwork);
        }
    }

    window: DockQuickWindow {
        id: root
        width: 224
        height: contentColumn.height + xEdgePadding * 2
        color: "transparent"

        Item {
            anchors.centerIn: parent
            width: parent.width - xEdgePadding * 2
            height: parent.height - xEdgePadding * 2

            Column {
                id: contentColumn
                width: parent.width
                spacing: 20

                Row {
                    id: buttonRow
                    spacing: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    CheckButton{
                        id: wiredCheckButton
                        onImage: "images/wire_on.png"
                        offImage: "images/wire_off.png"
                        visible: nmDevices["wired"].length > 0

                        onClicked: {
                            dbusNetwork.wiredEnabled = active
                        }

                        Connections{
                            target: dbusNetwork
                            onWiredEnabledChanged:{
                                if(!wiredCheckButton.pressed){
                                    wiredCheckButton.active = dbusNetwork.wiredEnabled
                                }
                            }
                        }

                        Timer{
                            running: true
                            interval: 100
                            onTriggered: {
                                parent.active = dbusNetwork.wiredEnabled
                            }
                        }
                    }

                    CheckButton{
                        id: wirelessCheckButton
                        onImage: "images/wifi_on.png"
                        offImage: "images/wifi_off.png"
                        visible: nmDevices["wireless"].length > 0

                        onClicked: {
                            dbusNetwork.wirelessEnabled = active
                        }

                        Connections{
                            target: dbusNetwork
                            onWirelessEnabledChanged:{
                                if(!wirelessCheckButton.pressed){
                                    wirelessCheckButton.active = dbusNetwork.wirelessEnabled
                                }
                            }
                        }

                        Timer{
                            running: true
                            interval: 100
                            onTriggered: {
                                parent.active = dbusNetwork.wirelessEnabled
                            }
                        }
                    }

                    //CheckButton{
                        //onImage: "images/3g_on.png"
                        //offImage: "images/3g_off.png"
                    //}

                    CheckButton{
                        id: vpnButton
                        visible: vpnConnections ? vpnConnections.length > 0 : false
                        onImage: "images/vpn_on.png"
                        offImage: "images/vpn_off.png"
                        property bool vpnActive: activeVpnIndex != -1

                        onVpnActiveChanged: {
                            if(!vpnButton.pressed){
                                vpnButton.active = vpnActive
                            }
                        }

                        function deactiveVpn(){
                            if(activeVpnIndex != -1){
                                var uuid = activeConnections[activeVpnIndex].Uuid
                                dbusNetwork.DeactivateConnection(uuid)
                            }
                        }

                        onClicked: {
                            deactiveVpn()
                        }

                        Timer{
                            running: true
                            interval: 100
                            onTriggered: {
                                parent.active = parent.vpnActive
                            }
                        }
                    }

                    CheckButton{
                        id: bluetoothButton
                        visible: adapters.length > 0
                        onImage: "images/bluetooth_on.png"
                        offImage: "images/bluetooth_off.png"

                        onClicked: {
                            dbusBluetooth.powered = active
                        }

                        Connections{
                            target: dbusBluetooth
                            onPoweredChanged:{
                                if(!bluetoothButton.pressed){
                                    bluetoothButton.active = dbusBluetooth.powered
                                }
                                var show = adapters.length > 0
                                var enabled = dbusBluetooth.powered
                                updateState("bluetooth", show, enabled)
                            }
                        }

                        Timer{
                            running: true
                            interval: 100
                            onTriggered: {
                                if(dbusBluetooth.powered)
                                    parent.active = dbusBluetooth.powered
                            }
                        }
                    }

                    CheckButton {
                        id: airplaneModeButton
                        onImage: "images/airplane_mode_on.png"
                        offImage: "images/airplane_mode_off.png"
                        property bool airplaneModeActive: getActive()

                        onAirplaneModeActiveChanged: {
                            if(!airplaneModeButton.pressed){
                                airplaneModeButton.active = airplaneModeButton.airplaneModeActive
                            }
                        }

                        function getActive(){
                            if(dbusNetwork.networkingEnabled || dbusBluetooth.powered){
                                return false
                            }
                            else{
                                return true
                            }
                        }

                        function setActive(){
                            dbusNetwork.networkingEnabled = true
                            dbusNetwork.wiredEnabled = true
                            dbusNetwork.wirelessEnabled = true
                            dbusBluetooth.powered = true
                        }

                        function setDeactive(){
                            dbusNetwork.wiredEnabled = false
                            dbusNetwork.wirelessEnabled = false
                            dbusNetwork.networkingEnabled = false
                            dbusBluetooth.powered = false
                        }

                        onClicked: {
                            if(active){
                                setDeactive()
                            }
                            else{
                                setActive()
                            }
                        }

                        Timer{
                            running: true
                            interval: 100
                            onTriggered: {
                                parent.active = parent.airplaneModeActive
                            }
                        }

                    }
                }

            }

        }

    }

}
