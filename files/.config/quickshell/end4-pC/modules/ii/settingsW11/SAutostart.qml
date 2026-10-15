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
            icon: "app_registration"
            shape: MaterialShape.Shape.Sunny
            title: Translation.tr("Autostart Apps")
            Layout.fillWidth: true

            WAutostartApps {}
        }

}
