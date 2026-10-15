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
            icon: "trackpad_input"
            shape: MaterialShape.Shape.Pentagon
            title: Translation.tr("Input")

            WCSubsection {
                title: Translation.tr("Keyboard")

                WCGroup {
                    WCText {
                        id: kbLayoutField
                        Layout.fillWidth: true
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keyboard layout")
                        placeholderText: Translation.tr("e.g., us, es, latam")
                        Component.onCompleted: value = Config.options.hyprland.input.kbLayout
                        onValueChanged: kbLayoutDebounceTimer.restart()

                        Timer {
                            id: kbLayoutDebounceTimer
                            interval: 1000
                            repeat: false
                            onTriggered: {
                                Config.options.hyprland.input.kbLayout = kbLayoutField.value
                                HyprlandConfig.set("input:kb_layout", kbLayoutField.value)
                            }
                        }
                    }
                    WCSwitch {
                        buttonIcon: "numbers"
                        text: Translation.tr("Numlock by default")
                        checked: Config.options.hyprland.input.numlock
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.numlock) return
                            Config.options.hyprland.input.numlock = checked
                            HyprlandConfig.set("input:numlock_by_default", checked ? 1 : 0)
                        }
                    }

                    WCSpin {
                        icon: "keyboard_return"
                        text: Translation.tr("Repeat delay (ms)")
                        value: Config.options.hyprland.input.repeatDelay
                        from: 100; to: 1000; stepSize: 10
                        onValueChanged: {
                            if (value === Config.options.hyprland.input.repeatDelay) return
                            Config.options.hyprland.input.repeatDelay = value
                            HyprlandConfig.set("input:repeat_delay", value)
                        }
                    }

                    WCSpin {
                        icon: "speed"
                        text: Translation.tr("Repeat rate")
                        value: Config.options.hyprland.input.repeatRate
                        from: 10; to: 100; stepSize: 1
                        onValueChanged: {
                            if (value === Config.options.hyprland.input.repeatRate) return
                            Config.options.hyprland.input.repeatRate = value
                            HyprlandConfig.set("input:repeat_rate", value)
                        }
                    }
                    WCHyprText {
                        optionKey: "input:kb_variant"
                        Layout.fillWidth: true
                        buttonIcon: "keyboard_alt"
                        text: Translation.tr("Keyboard variant")
                        placeholderText: Translation.tr("e.g., intl, dvorak")
                    }
                    WCHyprText {
                        optionKey: "input:kb_options"
                        Layout.fillWidth: true
                        buttonIcon: "keyboard_command_key"
                        text: Translation.tr("Keyboard options")
                        placeholderText: Translation.tr("e.g., caps:escape, grp:alt_shift_toggle")
                    }
                    WCSelection {
                        text: Translation.tr("Follow mouse")
                        icon: "mouse"
                        currentValue: Config.options.hyprland.input.followMouse
                        onSelected: newValue => {
                            Config.options.hyprland.input.followMouse = newValue
                            HyprlandConfig.set("input:follow_mouse", newValue)
                        }
                        options: [
                            { displayName: Translation.tr("Disabled"), icon: "mouse",     value: 0 },
                            { displayName: Translation.tr("Full"),     icon: "open_with",  value: 1 },
                            { displayName: Translation.tr("Loose"),    icon: "drag_pan",   value: 2 },
                            { displayName: Translation.tr("Explicit"), icon: "ads_click",  value: 3 },
                        ]
                    }
                }
            }

            WCSubsection {
                title: Translation.tr("Mouse")

                WCGroup {
                    WCHyprSpin {
                        optionKey: "input:sensitivity"
                        icon: "speed"
                        text: Translation.tr("Pointer sensitivity")
                        factor: 10
                        from: -10; to: 10; stepSize: 1
                    }
                    WCHyprSelection {
                        optionKey: "input:accel_profile"
                        icon: "trending_up"
                        text: Translation.tr("Acceleration profile")
                        fallback: ""
                        options: [
                            { displayName: Translation.tr("Default"), icon: "settings_backup_restore", value: "" },
                            { displayName: Translation.tr("Flat"), icon: "horizontal_rule", value: "flat" },
                            { displayName: Translation.tr("Adaptive"), icon: "show_chart", value: "adaptive" }
                        ]
                    }
                    WCHyprSwitch {
                        optionKey: "input:force_no_accel"
                        buttonIcon: "mouse"
                        text: Translation.tr("Disable acceleration (raw input)")
                    }
                    WCHyprSwitch {
                        optionKey: "input:left_handed"
                        buttonIcon: "front_hand"
                        text: Translation.tr("Left-handed buttons")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:middle_click_paste"
                        buttonIcon: "content_paste"
                        text: Translation.tr("Middle click paste")
                    }
                }
            }

            WCSubsection {
                title: Translation.tr("Touchpad")
                WCGroup {
                    WCSwitch {
                        buttonIcon: "swap_vert"
                        text: Translation.tr("Natural scroll")
                        checked: Config.options.hyprland.input.touchpad.naturalScroll
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.touchpad.naturalScroll) return
                            Config.options.hyprland.input.touchpad.naturalScroll = checked
                            HyprlandConfig.set("input:touchpad:natural_scroll", checked ? 1 : 0)
                        }
                    }

                    WCSwitch {
                        buttonIcon: "keyboard_hide"
                        text: Translation.tr("Disable while typing")
                        checked: Config.options.hyprland.input.touchpad.disableWhileTyping
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.touchpad.disableWhileTyping) return
                            Config.options.hyprland.input.touchpad.disableWhileTyping = checked
                            HyprlandConfig.set("input:touchpad:disable_while_typing", checked ? 1 : 0)
                        }
                    }

                    WCSwitch {
                        buttonIcon: "touch_app"
                        text: Translation.tr("Clickfinger behavior")
                        checked: Config.options.hyprland.input.touchpad.clickfingerBehavior
                        onCheckedChanged: {
                            if (checked === Config.options.hyprland.input.touchpad.clickfingerBehavior) return
                            Config.options.hyprland.input.touchpad.clickfingerBehavior = checked
                            HyprlandConfig.set("input:touchpad:clickfinger_behavior", checked ? 1 : 0)
                        }
                    }

                    WCHyprSwitch {
                        optionKey: "input:touchpad:tap-to-click"
                        buttonIcon: "touch_app"
                        text: Translation.tr("Tap to click")
                    }
                    WCHyprSwitch {
                        optionKey: "input:touchpad:tap-and-drag"
                        buttonIcon: "drag_pan"
                        text: Translation.tr("Tap and drag")
                    }
                    WCHyprSwitch {
                        optionKey: "input:touchpad:middle_button_emulation"
                        buttonIcon: "mouse"
                        text: Translation.tr("Middle button emulation (3-finger tap)")
                    }
                    WCSpin {
                        icon: "swipe"
                        text: Translation.tr("Scroll factor")
                        value: Math.round(Config.options.hyprland.input.touchpad.scrollFactor * 10)
                        from: 1; to: 30; stepSize: 1
                        onValueChanged: {
                            const newVal = value / 10.0
                            if (newVal === Config.options.hyprland.input.touchpad.scrollFactor) return
                            Config.options.hyprland.input.touchpad.scrollFactor = newVal
                            HyprlandConfig.set("input:touchpad:scroll_factor", newVal)
                        }
                    }
                }
            }
        }

}
