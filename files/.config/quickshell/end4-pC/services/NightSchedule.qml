pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Night light from sunset to sunrise (2026-10-08, ours; not upstream). Settings › System › Display.
 * While light.night.followSun (and the schedule) is on, this works out today's sunset and tomorrow's sunrise from
 * ~/.local/bin/sun-times (offline: the time zone's main city), checked every 30 minutes so a new day or a
 * daylight-saving change is picked up. Hyprsunset uses `sunset` / `sunrise` directly (2026-10-16: they used to be
 * written over light.night.from/to, your own hours, in the settings file).
 * Instantiated from GlobalStates.qml.
 */
Singleton {
    id: root

    readonly property bool active: Config.ready && Config.options.light.night.automatic && Config.options.light.night.followSun === true
    property string place: ""
    property bool ok: false
    property string sunset: ""
    property string sunrise: ""

    onActiveChanged: if (active) proc.running = true
    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.active
        onTriggered: proc.running = true
    }
    Process {
        id: proc
        command: [`${Quickshell.env("HOME")}/.local/bin/sun-times`]
        stdout: StdioCollector {
            onStreamFinished: {
                let d = {}
                try { d = JSON.parse(text) } catch (e) {}
                root.place = d.place || ""
                root.ok = d.ok === true
                if (!root.ok) return   // polar day/night or no location: your own hours are used
                root.sunset = d.sunset
                root.sunrise = d.sunrise
            }
        }
    }
}
