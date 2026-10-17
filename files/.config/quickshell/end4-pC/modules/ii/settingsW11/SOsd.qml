// Generated 2026-10-15 from illogical-impulse's InterfaceConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    WCSection {
            icon: "voting_chip"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("On-screen display")
            WCGroup {
                WCSpin {
                    icon: "av_timer"
                    text: Translation.tr("Timeout (ms)")
                    value: Config.options.osd.timeout
                    from: 100
                    to: 3000
                    stepSize: 100
                    onEdited: value => {
                        Config.options.osd.timeout = value;
                    }
                }
            }
        }

}
