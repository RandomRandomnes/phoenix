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
            icon: "volume_up"
            shape: MaterialShape.Shape.Circle
            title: Translation.tr("Audio")
            WCGroup {
                WCSwitch {
                    buttonIcon: "hearing"
                    text: Translation.tr("Earbang protection")
                    checked: Config.options.audio.protection.enable
                    onToggled: checked => {
                        Config.options.audio.protection.enable = checked;
                    }
                }
                WCGroup {
                    enabled: Config.options.audio.protection.enable
                    WCSpin {
                        icon: "arrow_warm_up"
                        text: Translation.tr("Max allowed increase")
                        value: Config.options.audio.protection.maxAllowedIncrease
                        from: 0
                        to: 100
                        stepSize: 2
                        onEdited: value => {
                            Config.options.audio.protection.maxAllowedIncrease = value;
                        }
                    }
                    WCSpin {
                        icon: "vertical_align_top"
                        text: Translation.tr("Volume limit")
                        value: Config.options.audio.protection.maxAllowed
                        from: 0
                        to: 154 // pavucontrol allows up to 153%
                        stepSize: 2
                        onEdited: value => {
                            Config.options.audio.protection.maxAllowed = value;
                        }
                    }
                }
            }
        }

    WCSection {
            icon: "notification_sound"
            shape: MaterialShape.Shape.Clover8Leaf
            title: Translation.tr("Sounds")
            WCGroup {
                WCSwitch {
                    buttonIcon: "battery_android_full"
                    text: Translation.tr("Battery")
                    enabled: Battery.available
                    checked: Config.options.sounds.battery
                    onToggled: checked => {
                        Config.options.sounds.battery = checked;
                    }
                }
                WCSwitch {
                    buttonIcon: "av_timer"
                    text: Translation.tr("Pomodoro")
                    checked: Config.options.sounds.pomodoro
                    onToggled: checked => {
                        Config.options.sounds.pomodoro = checked;
                    }
                }
            }
        }

}
