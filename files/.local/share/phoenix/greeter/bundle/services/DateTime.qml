pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

// Phoenix login screen (2026-10-22): the clock values the lock screen styles read (same rules as the desktop's DateTime)
Singleton {
    property var clock: SystemClock { precision: SystemClock.Seconds }
    property string time: Qt.locale().toString(clock.date, Config.options?.time.format ?? "hh:mm")
    property string shortDate: Qt.locale().toString(clock.date, Config.options?.time.shortDateFormat ?? "dd/MM")
    property string date: Qt.locale().toString(clock.date, Config.options?.time.dateWithYearFormat ?? "dd/MM/yyyy")
    property string longDate: Qt.locale().toString(clock.date, Config.options?.time.dateFormat ?? "dddd, dd/MM")
    readonly property bool use12HourFormat: (Config.options?.time.format ?? "hh:mm").toLowerCase().indexOf("ap") !== -1
    readonly property int hour24: clock.date.getHours()
    readonly property int hour12: (hour24 % 12 === 0) ? 12 : hour24 % 12
    readonly property string hourStr: (use12HourFormat ? hour12 : hour24).toString().padStart(2, "0")
    readonly property string minuteStr: Qt.locale().toString(clock.date, "mm")
}
