pragma Singleton
import QtQuick
import Quickshell

// Phoenix login screen (2026-10-22): the icon font of the desktop's Fonts service (phoenix-greeter-build copies it
// into assets/fonts); the handwriting fonts of the desktop text widget aren't needed here
Singleton {
    property string iconMaterialFamily: materialSymbolsLoader.name
    FontLoader {
        id: materialSymbolsLoader
        source: Qt.resolvedUrl(`${Quickshell.shellPath("assets/fonts")}/MaterialSymbolsLite.ttf`)
    }
}
