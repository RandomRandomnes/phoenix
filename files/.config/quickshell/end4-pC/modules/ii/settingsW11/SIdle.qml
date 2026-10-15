// Generated 2026-10-15 from illogical-impulse's HyprlandConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import qs.modules.common.functions
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    Component.onCompleted: {
        HyprlandOptions.refresh()
        const h = Config.options.hyprland
        // One setMany for everything: separate calls would be separate
        // processes racing to rewrite the same overrides file.
        HyprlandConfig.setMany(Object.assign({
            "decoration:rounding":                  h.decoration.rounding,
            "decoration:blur:enabled":              h.decoration.blur.enabled ? 1 : 0,
            "decoration:blur:size":                 h.decoration.blur.size,
            "decoration:blur:passes":               h.decoration.blur.passes,
            "decoration:active_opacity":            h.decoration.activeOpacity,
            "decoration:inactive_opacity":          h.decoration.inactiveOpacity,
            "general:border_size":                  h.general.borderSize,
            "general:gaps_in":                      h.general.gapsIn,
            "general:gaps_out":                     h.general.gapsOut,
            "general:layout":                       h.general.layout,
            "animations:enabled":                   h.animations.enable ? 1 : 0,
            "input:kb_layout":                      h.input.kbLayout,
            "input:numlock_by_default":             h.input.numlock ? 1 : 0,
            "input:repeat_delay":                   h.input.repeatDelay,
            "input:repeat_rate":                    h.input.repeatRate,
            "input:follow_mouse":                   h.input.followMouse,
            "input:touchpad:natural_scroll":        h.input.touchpad.naturalScroll ? 1 : 0,
            "input:touchpad:disable_while_typing":  h.input.touchpad.disableWhileTyping ? 1 : 0,
            "input:touchpad:clickfinger_behavior":  h.input.touchpad.clickfingerBehavior ? 1 : 0,
            "input:touchpad:scroll_factor":         h.input.touchpad.scrollFactor,
            "misc:focus_on_activate":               h.misc.focusOnActivate ? 1 : 0
        }, HyprlandConfig.borderColorEntries()))
    }

    MonitorConfigOption { id: monitorConfig }

    // Same roles as the settings panel border color on the Interface page.

    readonly property var borderColorRoles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "layer0Border"]

    WCSection {
            id: idleSection
            icon: "timer"
            shape: MaterialShape.Shape.Cookie12Sided
            title: Translation.tr("Idle")

            readonly property list<var> unitOptions: [
                { displayName: Translation.tr("Seconds"), icon: "timer",    value: 1    },
                { displayName: Translation.tr("Minutes"), icon: "av_timer", value: 60   },
                { displayName: Translation.tr("Hours"),   icon: "schedule", value: 3600 },
            ]

            // one Windows-style card: name on the left, number + unit on the right (Phoenix 2026-10-15)
            component IdleTimerRow: WCard {
                id: timerRow

                property string label
                property int seconds: 0
                property int displayValue: 60
                property int displayUnit: 60
                property bool loaded: false

                signal edited(int newSeconds)

                title: timerRow.label

                onSecondsChanged: {
                    const display = idleSection.toDisplay(timerRow.seconds)
                    timerRow.displayValue = display[0]
                    timerRow.displayUnit = display[1]
                }

                StyledSpinBox {
                    value: timerRow.displayValue
                    from: 0
                    to: 9999
                    stepSize: 1
                    onValueChanged: {
                        if (!timerRow.loaded) return
                        timerRow.displayValue = value
                        timerRow.edited(value * timerRow.displayUnit)
                    }
                }
                StyledComboBox {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 160
                    Layout.maximumWidth: 160
                    textRole: "displayName"
                    model: idleSection.unitOptions
                    currentIndex: idleSection.unitOptions.findIndex(o => o.value === timerRow.displayUnit)
                    onActivated: index => {
                        timerRow.displayUnit = idleSection.unitOptions[index].value
                        timerRow.edited(timerRow.displayValue * timerRow.displayUnit)
                    }
                }
            }

            function toDisplay(seconds) {
                if (seconds <= 0)
                    return [0, 60]
                if (seconds % 3600 === 0)
                    return [seconds / 3600, 3600]
                if (seconds % 60 === 0)
                    return [seconds / 60, 60]
                return [seconds, 1]
            }

            function applyIdle() {
                HyprlandConfig.setIdle(
                    Config.options.hyprland.idle.lock,
                    Config.options.hyprland.idle.screenOff,
                    Config.options.hyprland.idle.suspend
                )
            }

            WCGroup {
                IdleTimerRow {
                    icon: "lock_clock"
                    label: Translation.tr("Lock screen")
                    seconds: Config.options.hyprland.idle.lock
                    onEdited: newSeconds => {
                        Config.options.hyprland.idle.lock = newSeconds
                        idleSection.applyIdle()
                    }
                    Component.onCompleted: loaded = true
                }
                IdleTimerRow {
                    icon: "monitor"
                    label: Translation.tr("Screen off")
                    seconds: Config.options.hyprland.idle.screenOff
                    onEdited: newSeconds => {
                        Config.options.hyprland.idle.screenOff = newSeconds
                        idleSection.applyIdle()
                    }
                    Component.onCompleted: loaded = true
                }
                IdleTimerRow {
                    icon: "bedtime"
                    label: Translation.tr("Standby")
                    seconds: Config.options.hyprland.idle.suspend
                    onEdited: newSeconds => {
                        Config.options.hyprland.idle.suspend = newSeconds
                        idleSection.applyIdle()
                    }
                    Component.onCompleted: loaded = true
                }
            }
        }

}
