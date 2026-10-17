// Generated 2026-10-15 from illogical-impulse's GeneralConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    WCSection {
            icon: "battery_android_full"
            shape: MaterialShape.Shape.SemiCircle
            title: Translation.tr("Battery")
            visible: Battery.available

            WCGroup {
                WCGroup {
                    uniform: true
                    WCSpin {
                        icon: "warning"
                        text: Translation.tr("Low warning")
                        value: Config.options.battery.low
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: value => {
                            Config.options.battery.low = value;
                        }
                    }
                    WCSpin {
                        icon: "dangerous"
                        text: Translation.tr("Critical warning")
                        value: Config.options.battery.critical
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: value => {
                            Config.options.battery.critical = value;
                        }
                    }
                }
                WCGroup {
                    uniform: true
                    WCSwitch {
                        buttonIcon: "pause"
                        text: Translation.tr("Automatic suspend")
                        checked: Config.options.battery.automaticSuspend
                        onToggled: checked => {
                            Config.options.battery.automaticSuspend = checked;
                        }
                    }
                    WCSpin {
                        enabled: Config.options.battery.automaticSuspend
                        text: Translation.tr("at")
                        value: Config.options.battery.suspend
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: value => {
                            Config.options.battery.suspend = value;
                        }
                    }
                }
                WCGroup {
                    uniform: true
                    WCSpin {
                        icon: "charger"
                        text: Translation.tr("Full warning")
                        value: Config.options.battery.full
                        from: 0
                        to: 101
                        stepSize: 5
                        onEdited: value => {
                            Config.options.battery.full = value;
                        }
                    }
                }
            }
        }

    WCSection {
            icon: "mouse"
            shape: MaterialShape.Shape.Cookie7Sided
            title: Translation.tr("Device batteries")

            WCGroup {
                WCGroup {
                    uniform: true
                    WCSpin {
                        icon: "warning"
                        text: Translation.tr("Low warning")
                        value: Config.options.battery.peripheralLow
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: value => {
                            Config.options.battery.peripheralLow = value;
                        }
                    }
                    WCSpin {
                        icon: "dangerous"
                        text: Translation.tr("Critical warning")
                        value: Config.options.battery.peripheralCritical
                        from: 0
                        to: 100
                        stepSize: 5
                        onEdited: value => {
                            Config.options.battery.peripheralCritical = value;
                        }
                    }
                }
                WCSwitch {
                    buttonIcon: "notifications"
                    text: Translation.tr("Notify when a device battery is low")
                    checked: Config.options.battery.peripheralNotify
                    onToggled: checked => {
                        Config.options.battery.peripheralNotify = checked;
                    }
                }
            }
        }

}
