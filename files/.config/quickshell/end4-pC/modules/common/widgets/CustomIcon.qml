import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.modules.common.functions

Item {
    id: root
    
    property bool colorize: false
    property color color
    property string source: ""
    property string customFolder: ""
    property string iconFolder: FileUtils.folderUrl(root.customFolder) || Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))
    width: 30
    height: 30
    onSourceChanged: iconImage.attempt = 0
    
    IconImage {
        id: iconImage
        anchors.fill: parent
        // icon names are stored without the file extension (IconPickerGrid), some setup profiles name the plain icon
        // ("spark" for spark-symbolic.svg): try those files in turn (Phoenix, 2026-10-17)
        property int attempt: 0
        readonly property bool bareName: root.source !== "" && !root.source.includes("/") && !/\.(svg|png)$/.test(root.source)
        readonly property var suffixes: [".svg", "-symbolic.svg", ".png"]
        source: {
            if (root.source === "") return "";
            if (iconFolder && !root.source.includes("/")) {
                return iconFolder + "/" + root.source + (bareName ? suffixes[attempt] : "")
            }
            return root.source
        }
        onStatusChanged: if (status === Image.Error && bareName && attempt < suffixes.length - 1) attempt++
        implicitSize: root.height
    }

    Loader {
        active: root.colorize
        anchors.fill: iconImage
        sourceComponent: ColorOverlay {
            source: iconImage
            color: root.color
        }
    }
}
