import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

QuickToggleButton {
    id: root
    visible: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    buttonIcon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
    onClicked: {
        BluetoothStatus.togglePower()
    }
    altAction: () => {
        Quickshell.execDetached(["phoenix-open", "settings", "devices", "bluetooth"])   // Phoenix 2026-10-15: Settings › Bluetooth & devices (was KDE's page)
        GlobalStates.sidebarRightOpen = false
    }
    StyledToolTip {
        text: Translation.tr("%1 | Right-click to configure").arg(
            (BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Bluetooth"))
            + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : "")
            )
    }
}
