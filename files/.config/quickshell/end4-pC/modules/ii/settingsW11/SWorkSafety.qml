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
            icon: "work_alert"
            shape: MaterialShape.Shape.PuffyDiamond
            title: Translation.tr("Work safety")
            WCGroup {
                WCSwitch {
                    buttonIcon: "assignment"
                    text: Translation.tr("Hide clipboard images copied from sussy sources")
                    checked: Config.options.workSafety.enable.clipboard
                    onCheckedChanged: {
                        Config.options.workSafety.enable.clipboard = checked;
                    }
                }
                WCSwitch {
                    buttonIcon: "wallpaper"
                    text: Translation.tr("Hide sussy/anime wallpapers")
                    checked: Config.options.workSafety.enable.wallpaper
                    onCheckedChanged: {
                        Config.options.workSafety.enable.wallpaper = checked;
                    }
                }
            }
        }

}
