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
            icon: "auto_awesome_mosaic"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Layout")

            WCGroup {
                WCSelection {
                    text: Translation.tr("Tiling Layout")
                    icon: "responsive_layout"
                    currentValue: Config.options.hyprland.general.layout
                    onSelected: newValue => {
                        Config.options.hyprland.general.layout = newValue
                        HyprlandConfig.set("general:layout", newValue)
                    }
                    options: [
                        { displayName: Translation.tr("Dwindle"),   icon: "browse",             value: "dwindle"   },
                        { displayName: Translation.tr("Master"),    icon: "auto_awesome_mosaic", value: "master"    },
                        { displayName: Translation.tr("Scrolling"), icon: "view_carousel",       value: "scrolling" },
                    ]
                }
            }

            WCSubsection {
                Layout.topMargin: 10
                visible: Config.options.hyprland.general.layout === "dwindle"
                title: Translation.tr("Dwindle")

                WCGroup {
                    WCHyprSwitch {
                        optionKey: "dwindle:preserve_split"
                        buttonIcon: "call_split"
                        text: Translation.tr("Preserve split direction")
                    }
                    WCHyprSwitch {
                        optionKey: "dwindle:smart_split"
                        buttonIcon: "smart_toy"
                        text: Translation.tr("Smart split (follow the cursor)")
                    }
                    WCHyprSelection {
                        optionKey: "dwindle:force_split"
                        icon: "splitscreen"
                        text: Translation.tr("Force split side")
                        fallback: 0
                        options: [
                            { displayName: Translation.tr("Auto"), icon: "auto_mode", value: 0 },
                            { displayName: Translation.tr("Left / top"), icon: "align_horizontal_left", value: 1 },
                            { displayName: Translation.tr("Right / bottom"), icon: "align_horizontal_right", value: 2 }
                        ]
                    }
                    WCHyprSpin {
                        optionKey: "dwindle:default_split_ratio"
                        icon: "percent"
                        text: Translation.tr("Default split ratio")
                        factor: 10
                        from: 2; to: 18; stepSize: 1
                    }
                }
            }

            WCSubsection {
                Layout.topMargin: 10
                visible: Config.options.hyprland.general.layout === "master"
                title: Translation.tr("Master")

                WCGroup {
                    WCHyprSelection {
                        optionKey: "master:new_status"
                        icon: "add_box"
                        text: Translation.tr("New windows become")
                        fallback: "slave"
                        options: [
                            { displayName: Translation.tr("Master"), icon: "star", value: "master" },
                            { displayName: Translation.tr("Slave"), icon: "view_agenda", value: "slave" },
                            { displayName: Translation.tr("Inherit"), icon: "content_copy", value: "inherit" }
                        ]
                    }
                    WCHyprSelection {
                        optionKey: "master:orientation"
                        icon: "screen_rotation"
                        text: Translation.tr("Master position")
                        fallback: "left"
                        options: [
                            { displayName: Translation.tr("Left"), icon: "align_horizontal_left", value: "left" },
                            { displayName: Translation.tr("Right"), icon: "align_horizontal_right", value: "right" },
                            { displayName: Translation.tr("Top"), icon: "align_vertical_top", value: "top" },
                            { displayName: Translation.tr("Bottom"), icon: "align_vertical_bottom", value: "bottom" },
                            { displayName: Translation.tr("Center"), icon: "align_horizontal_center", value: "center" }
                        ]
                    }
                    WCHyprSpin {
                        optionKey: "master:mfact"
                        icon: "aspect_ratio"
                        text: Translation.tr("Master size")
                        factor: 100
                        from: 10; to: 90; stepSize: 5
                    }
                }
            }
        }

    WCSection {
            icon: "deblur"
            shape: MaterialShape.Shape.PixelCircle
            title: Translation.tr("Visual & Aesthetics")

            WCGroup {
                WCSpin {
                    icon: "rounded_corner"
                    text: Translation.tr("Window Rounding")
                    value: Config.options.hyprland.decoration.rounding
                    from: 0; to: 30; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.rounding) return
                        Config.options.hyprland.decoration.rounding = value
                        HyprlandConfig.set("decoration:rounding", value)
                    }
                }

                WCSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur")
                    checked: Config.options.hyprland.decoration.blur.enabled
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.decoration.blur.enabled) return
                        Config.options.hyprland.decoration.blur.enabled = checked
                        HyprlandConfig.set("decoration:blur:enabled", checked ? 1 : 0)
                    }
                }

                WCSpin {
                    icon: "blur_circular"
                    text: Translation.tr("Blur Size")
                    value: Config.options.hyprland.decoration.blur.size
                    from: 1; to: 20; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.blur.size) return
                        Config.options.hyprland.decoration.blur.size = value
                        HyprlandConfig.set("decoration:blur:size", value)
                    }
                }

                WCSpin {
                    icon: "layers"
                    text: Translation.tr("Blur Passes")
                    value: Config.options.hyprland.decoration.blur.passes
                    from: 1; to: 6; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.decoration.blur.passes) return
                        Config.options.hyprland.decoration.blur.passes = value
                        HyprlandConfig.set("decoration:blur:passes", value)
                    }
                }

                WCSpin {
                    icon: "margin"
                    text: Translation.tr("Gaps In")
                    value: Config.options.hyprland.general.gapsIn
                    from: 0; to: 40; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.gapsIn) return
                        Config.options.hyprland.general.gapsIn = value
                        HyprlandConfig.set("general:gaps_in", value)
                    }
                }

                WCSpin {
                    icon: "open_in_full"
                    text: Translation.tr("Gaps Out")
                    value: Config.options.hyprland.general.gapsOut
                    from: 0; to: 60; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.gapsOut) return
                        Config.options.hyprland.general.gapsOut = value
                        HyprlandConfig.set("general:gaps_out", value)
                    }
                }

                WCSpin {
                    icon: "opacity"
                    text: Translation.tr("Active Opacity")
                    value: Math.round(Config.options.hyprland.decoration.activeOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === Config.options.hyprland.decoration.activeOpacity) return
                        Config.options.hyprland.decoration.activeOpacity = newVal
                        HyprlandConfig.set("decoration:active_opacity", newVal)
                    }
                }

                WCSpin {
                    icon: "opacity"
                    text: Translation.tr("Inactive Opacity")
                    value: Math.round(Config.options.hyprland.decoration.inactiveOpacity * 100)
                    from: 10; to: 100; stepSize: 5
                    onValueChanged: {
                        const newVal = value / 100.0
                        if (newVal === Config.options.hyprland.decoration.inactiveOpacity) return
                        Config.options.hyprland.decoration.inactiveOpacity = newVal
                        HyprlandConfig.set("decoration:inactive_opacity", newVal)
                    }
                }
                WCSpin {
                    icon: "border_outer"
                    text: Translation.tr("Border Size")
                    value: Config.options.hyprland.general.borderSize
                    from: 0; to: 10; stepSize: 1
                    onValueChanged: {
                        if (value === Config.options.hyprland.general.borderSize) return
                        Config.options.hyprland.general.borderSize = value
                        HyprlandConfig.set("general:border_size", value)
                    }
                }

                WCSwitch {
                    buttonIcon: "format_paint"
                    text: Translation.tr("Custom border colors")
                    checked: Config.options.hyprland.general.borderColor.enable
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.general.borderColor.enable) return
                        Config.options.hyprland.general.borderColor.enable = checked
                        if (checked) HyprlandConfig.applyBorderColors()
                        else HyprlandConfig.resetBorderColors()
                    }
                }
            }
            

            WCSubsection {
                Layout.topMargin: 10
                visible: Config.options.hyprland.general.borderColor.enable
                title: Translation.tr("Border Color Management")
                WCGroup {
                    visible: Config.options.hyprland.general.borderColor.enable

                    WCColors {
                        icon: "border_color"
                        text: Translation.tr("Active border")
                        options: page.borderColorRoles
                        currentValue: Config.options.hyprland.general.borderColor.activeRole
                        onSelected: newValue => {
                            Config.options.hyprland.general.borderColor.activeRole = newValue
                            HyprlandConfig.applyBorderColors()
                        }
                    }

                    WCSpin {
                        icon: "opacity"
                        text: Translation.tr("Active border opacity")
                        value: Math.round(Config.options.hyprland.general.borderColor.activeOpacity * 100)
                        from: 0; to: 100; stepSize: 5
                        onValueChanged: {
                            // Compared as integers: the spin box only holds whole percents.
                            if (value === Math.round(Config.options.hyprland.general.borderColor.activeOpacity * 100)) return
                            Config.options.hyprland.general.borderColor.activeOpacity = value / 100.0
                            HyprlandConfig.applyBorderColors()
                        }
                    }

                    WCColors {
                        icon: "border_color"
                        text: Translation.tr("Inactive border")
                        options: page.borderColorRoles
                        currentValue: Config.options.hyprland.general.borderColor.inactiveRole
                        onSelected: newValue => {
                            Config.options.hyprland.general.borderColor.inactiveRole = newValue
                            HyprlandConfig.applyBorderColors()
                        }
                    }

                    WCSpin {
                        icon: "opacity"
                        text: Translation.tr("Inactive border opacity")
                        value: Math.round(Config.options.hyprland.general.borderColor.inactiveOpacity * 100)
                        from: 0; to: 100; stepSize: 5
                        onValueChanged: {
                            // Compared as integers: the spin box only holds whole percents.
                            if (value === Math.round(Config.options.hyprland.general.borderColor.inactiveOpacity * 100)) return
                            Config.options.hyprland.general.borderColor.inactiveOpacity = value / 100.0
                            HyprlandConfig.applyBorderColors()
                        }
                    }
                }
            }

            WCSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Shadows, dimming & blur")

                WCGroup {
                    WCHyprSwitch {
                        optionKey: "decoration:shadow:enabled"
                        buttonIcon: "shadow"
                        text: Translation.tr("Window shadows")
                    }
                    WCHyprSpin {
                        optionKey: "decoration:shadow:range"
                        icon: "blur_on"
                        text: Translation.tr("Shadow range")
                        from: 0; to: 50; stepSize: 1
                    }
                    WCHyprSwitch {
                        optionKey: "decoration:dim_inactive"
                        buttonIcon: "brightness_low"
                        text: Translation.tr("Dim inactive windows")
                    }
                    WCHyprSpin {
                        optionKey: "decoration:dim_strength"
                        icon: "contrast"
                        text: Translation.tr("Dim strength")
                        factor: 100
                        from: 0; to: 100; stepSize: 5
                    }
                    WCHyprSpin {
                        optionKey: "decoration:blur:noise"
                        icon: "grain"
                        text: Translation.tr("Blur noise")
                        factor: 100
                        from: 0; to: 50; stepSize: 1
                    }
                    WCHyprSpin {
                        optionKey: "decoration:blur:vibrancy"
                        icon: "palette"
                        text: Translation.tr("Blur vibrancy")
                        factor: 100
                        from: 0; to: 100; stepSize: 5
                    }
                }
            }
        }

    WCSection {
            icon: "pan_tool"
            shape: MaterialShape.Shape.Cookie9Sided
            title: Translation.tr("Windows & Cursor")

            WCSubsection {
                title: Translation.tr("Windows")

                WCGroup {
                    WCHyprSwitch {
                        optionKey: "general:resize_on_border"
                        buttonIcon: "open_in_full"
                        text: Translation.tr("Resize windows by dragging their borders")
                    }
                    WCHyprSpin {
                        optionKey: "general:extend_border_grab_area"
                        icon: "border_outer"
                        text: Translation.tr("Border grab area (px)")
                        from: 0; to: 60; stepSize: 1
                    }
                    WCHyprSwitch {
                        optionKey: "general:allow_tearing"
                        buttonIcon: "sports_esports"
                        text: Translation.tr("Allow tearing (lower latency in games)")
                    }
                }
            }

            WCSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Cursor")

                WCGroup {
                    WCHyprSelection {
                        optionKey: "cursor:no_hardware_cursors"
                        icon: "mouse"
                        text: Translation.tr("Hardware cursor")
                        fallback: 2
                        options: [
                            { displayName: Translation.tr("Auto"), icon: "auto_mode", value: 2 },
                            { displayName: Translation.tr("On"), icon: "check_circle", value: 0 },
                            { displayName: Translation.tr("Off"), icon: "block", value: 1 }
                        ]
                    }
                    WCHyprSpin {
                        optionKey: "cursor:inactive_timeout"
                        icon: "hourglass_empty"
                        text: Translation.tr("Hide cursor after inactivity (s, 0 = never)")
                        from: 0; to: 60; stepSize: 1
                    }
                    WCHyprSwitch {
                        optionKey: "cursor:hide_on_key_press"
                        buttonIcon: "keyboard_hide"
                        text: Translation.tr("Hide cursor while typing")
                    }
                    WCHyprSelection {
                        optionKey: "cursor:warp_on_change_workspace"
                        icon: "ads_click"
                        text: Translation.tr("Move cursor to the new workspace")
                        fallback: 0
                        options: [
                            { displayName: Translation.tr("Off"), icon: "block", value: 0 },
                            { displayName: Translation.tr("On"), icon: "check_circle", value: 1 },
                            { displayName: Translation.tr("Force"), icon: "bolt", value: 2 }
                        ]
                    }
                }
            }
        }

    WCSection {
            icon: "animation"
            shape: MaterialShape.Shape.Oval
            title: Translation.tr("Animations")
            WCGroup {
                WCSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.hyprland.animations.enable
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.animations.enable) return
                        Config.options.hyprland.animations.enable = checked
                        HyprlandConfig.set("animations:enabled", checked ? 1 : 0)
                    }
                }
                WCSelection {
                    text: Translation.tr("Presets")
                    icon: "present_to_all"
                    currentValue: Config.options.hyprland.animations.animation
                    onSelected: newValue => {
                        Config.options.hyprland.animations.animation = newValue
                        saveAnimProc.command = [
                            "python3",
                            HyprlandConfig.configuratorScriptPath,
                            "--anim-preset", newValue
                        ]
                        saveAnimProc.running = true
                    }
                    options: [
                        { displayName: Translation.tr("Elastic"),   icon: "move_selection_right", value: "fast"   },
                        { displayName: Translation.tr("Normal"),    icon: "animation",            value: "normal" },
                        { displayName: Translation.tr("Niri Like"), icon: "mobiledata_arrows",    value: "niri"   },
                    ]
                }
            }

            WCNotice {
                Layout.fillWidth: true
                Layout.topMargin: 15
                text: Translation.tr("Animation presets require a require line in your hyprland.lua. Add the following line to enable presets:") + '\n\nrequire("hyprland/shellOverrides/animations")'

                Item { Layout.fillWidth: true }

                RippleButtonWithIcon {
                    id: copySourceButton
                    property bool justCopied: false
                    Layout.fillWidth: false
                    buttonRadius: Appearance.rounding.small
                    materialIcon: justCopied ? "check" : "content_copy"
                    mainText: justCopied ? Translation.tr("Copied!") : Translation.tr("Copy line")
                    onClicked: {
                        copySourceButton.justCopied = true
                        Quickshell.clipboardText = 'require("hyprland/shellOverrides/animations")'
                        revertSourceTimer.restart()
                    }
                    colBackground: ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    Timer {
                        id: revertSourceTimer
                        interval: 1500
                        onTriggered: copySourceButton.justCopied = false
                    }
                }
            }

            Process {
                id: saveAnimProc
                onRunningChanged: if (!running) reloadAnimProc.running = true
            }
            Process {
                id: reloadAnimProc
                command: ["hyprctl", "reload"]
            }
        }

    WCSection {
            icon: "tune"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Misc")

            WCGroup {
                WCSwitch {
                    buttonIcon: "center_focus_strong"
                    text: Translation.tr("Focus on activate")
                    checked: Config.options.hyprland.misc.focusOnActivate
                    onCheckedChanged: {
                        if (checked === Config.options.hyprland.misc.focusOnActivate) return
                        Config.options.hyprland.misc.focusOnActivate = checked
                        HyprlandConfig.set("misc:focus_on_activate", checked ? 1 : 0)
                    }
                }
                    WCHyprSelection {
                        optionKey: "misc:vrr"
                        icon: "slow_motion_video"
                        text: Translation.tr("Variable refresh rate (VRR)")
                        fallback: 0
                        options: [
                            { displayName: Translation.tr("Off"), icon: "block", value: 0 },
                            { displayName: Translation.tr("On"), icon: "check_circle", value: 1 },
                            { displayName: Translation.tr("Fullscreen only"), icon: "fullscreen", value: 2 }
                        ]
                    }
                    WCHyprSwitch {
                        optionKey: "misc:enable_swallow"
                        buttonIcon: "call_merge"
                        text: Translation.tr("Window swallowing (terminal swallows launched apps)")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:animate_manual_resizes"
                        buttonIcon: "animation"
                        text: Translation.tr("Animate manual resizes")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:close_special_on_empty"
                        buttonIcon: "close_fullscreen"
                        text: Translation.tr("Close empty special workspace")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:disable_hyprland_logo"
                        buttonIcon: "hide_image"
                        text: Translation.tr("Hide the Hyprland logo")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:disable_splash_rendering"
                        buttonIcon: "subtitles_off"
                        text: Translation.tr("Hide the splash text")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:mouse_move_enables_dpms"
                        buttonIcon: "mouse"
                        text: Translation.tr("Mouse wakes the screen")
                    }
                    WCHyprSwitch {
                        optionKey: "misc:key_press_enables_dpms"
                        buttonIcon: "keyboard"
                        text: Translation.tr("Keys wake the screen")
                    }
                    WCHyprSwitch {
                        optionKey: "xwayland:force_zero_scaling"
                        buttonIcon: "zoom_out_map"
                        text: Translation.tr("XWayland: sharp apps (force zero scaling)")
                    }
                    WCHyprSwitch {
                        optionKey: "group:auto_group"
                        buttonIcon: "tab_group"
                        text: Translation.tr("Auto-group dragged windows")
                    }
                    WCHyprSwitch {
                        optionKey: "binds:workspace_back_and_forth"
                        buttonIcon: "swap_horiz"
                        text: Translation.tr("Switching to the current workspace goes back")
                    }
                    WCHyprSwitch {
                        optionKey: "binds:allow_workspace_cycles"
                        buttonIcon: "cached"
                        text: Translation.tr("Allow workspace cycles")
                    }
                    WCHyprSelection {
                        optionKey: "render:direct_scanout"
                        icon: "speed"
                        text: Translation.tr("Direct scanout (fullscreen apps)")
                        fallback: 0
                        options: [
                            { displayName: Translation.tr("Off"), icon: "block", value: 0 },
                            { displayName: Translation.tr("On"), icon: "check_circle", value: 1 },
                            { displayName: Translation.tr("Auto"), icon: "auto_mode", value: 2 }
                        ]
                    }
            }
        }

}
