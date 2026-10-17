// Generated 2026-10-15 from illogical-impulse's BackgroundConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Quickshell.Hyprland

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    function displayPathFor(path) {
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(path)
            ? Config.options.background.thumbnailPath
            : path
    }

    WCSection {
            id: settingsClock
            icon: "clock_loader_40"
            shape: MaterialShape.Shape.Bun
            title: Translation.tr("Clock")

            function stylePresent(styleName) {
                if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) {
                    return true;
                }
                if (Config.options.background.widgets.clock.styleLocked === styleName) {
                    return true;
                }
                return false;
            }

            readonly property bool digitalPresent: stylePresent("digital")
            readonly property bool cookiePresent: stylePresent("cookie")

            WCGroup {
                WCSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.clock.enable
                    onToggled: checked => {
                        Config.options.background.widgets.clock.enable = checked;
                    }
                }

                WCSwitch {
                    buttonIcon: "lock_clock"
                    text: Translation.tr("Show only when locked")
                    enabled: WM.compositor !== "niri"
                    checked: Config.options.background.widgets.clock.showOnlyWhenLocked
                    onToggled: checked => {
                        Config.options.background.widgets.clock.showOnlyWhenLocked = checked;
                    }
                }
                WCSelection {
                    text: Translation.tr("Placement strategy")
                    icon: "move"
                    currentValue: Config.options.background.widgets.clock.placementStrategy
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.placementStrategy = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Draggable"),
                            icon: "drag_pan",
                            value: "free"
                        },
                        {
                            displayName: Translation.tr("Least busy"),
                            icon: "category",
                            value: "leastBusy"
                        },
                        {
                            displayName: Translation.tr("Most busy"),
                            icon: "shapes",
                            value: "mostBusy"
                        },
                    ]
                }
                WCSelection {
                    text: Translation.tr("Clock style")
                    icon: "nest_clock_farsight_analog"
                    currentValue: Config.options.background.widgets.clock.style
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        },
                        {
                            displayName: Translation.tr("Pixel"),
                            icon: "grid_view",
                            value: "pixel"
                        }
                    ]
                }
                WCSelection {
                    text: Translation.tr("Clock style (locked)")
                    icon: "shield_watch"
                    currentValue: Config.options.background.widgets.clock.styleLocked
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.styleLocked = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        },
                        {
                            displayName: Translation.tr("Pixel"),
                            icon: "grid_view",
                            value: "pixel"
                        }
                    ]
                }
            }

            WCSubsection {
                visible: settingsClock.digitalPresent
                title: Translation.tr("Digital clock settings")

                WCGroup {
                    WCGroup {
                        uniform: true
                        WCSwitch {
                            buttonIcon: "vertical_distribute"
                            text: Translation.tr("Vertical")
                            checked: Config.options.background.widgets.clock.digital.vertical
                            onToggled: checked => { Config.options.background.widgets.clock.digital.vertical = checked }
                        }
                        WCSwitch {
                            buttonIcon: "animation"
                            text: Translation.tr("Animate time change")
                            checked: Config.options.background.widgets.clock.digital.animateChange
                            onToggled: checked => { Config.options.background.widgets.clock.digital.animateChange = checked }
                        }
                    }
                    WCGroup {
                        uniform: true
                        WCSwitch {
                            buttonIcon: "date_range"
                            text: Translation.tr("Show date")
                            checked: Config.options.background.widgets.clock.digital.showDate
                            onToggled: checked => { Config.options.background.widgets.clock.digital.showDate = checked }
                        }
                        WCSwitch {
                            buttonIcon: "activity_zone"
                            text: Translation.tr("Use adaptive alignment")
                            checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                            onToggled: checked => { Config.options.background.widgets.clock.digital.adaptiveAlignment = checked }
                        }
                    }
                }

                WCGroup {
                    WCSwitch {
                        id: autoColorSwitch
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Automatic colors")
                        checked: Config.options.background.widgets.clock.color === ""
                        onToggled: checked => {
                            if (checked) {
                                Config.options.background.widgets.clock.color = ""
                            }
                        }
                    }

                    WCColors {
                        icon: "palette"
                        text: Translation.tr("Color")
                        currentValue: Config.options.background.widgets.clock.color
                        onSelected: newValue => {
                            Config.options.background.widgets.clock.color = newValue
                            autoColorSwitch.checked = false
                        }
                    }
                }

                WCGroup {
                    WCCombo {
                        Layout.fillWidth: true
                        buttonIcon: "font_download"
                        text: Translation.tr("Font family")
                        fieldWidth: 260
                        fixedWidth: true
                        searchable: true
                        model: SystemAppearance.fontOptions(Config.options.background.widgets.clock.digital.font.family)
                        currentValue: Config.options.background.widgets.clock.digital.font.family
                        onSelected: newValue => { Config.options.background.widgets.clock.digital.font.family = newValue }
                    }
                    WCSlider {
                        text: Translation.tr("Font weight")
                        value: Config.options.background.widgets.clock.digital.font.weight
                        usePercentTooltip: false
                        buttonIcon: "format_bold"
                        from: 1
                        to: 1000
                        stopIndicatorValues: [350]
                        onEdited: value => {
                            Config.options.background.widgets.clock.digital.font.weight = value;
                        }
                    }

                    WCSlider {
                        text: Translation.tr("Font size")
                        value: Config.options.background.widgets.clock.digital.font.size
                        usePercentTooltip: false
                        buttonIcon: "format_size"
                        from: 50
                        to: 700
                        stopIndicatorValues: [90]
                        onEdited: value => {
                            Config.options.background.widgets.clock.digital.font.size = value;
                        }
                    }

                    WCSlider {
                        text: Translation.tr("Font width")
                        value: Config.options.background.widgets.clock.digital.font.width
                        usePercentTooltip: false
                        buttonIcon: "fit_width"
                        from: 25
                        to: 125
                        stopIndicatorValues: [100]
                        onEdited: value => {
                            Config.options.background.widgets.clock.digital.font.width = value;
                        }
                    }
                    WCSlider {
                        text: Translation.tr("Font roundness")
                        value: Config.options.background.widgets.clock.digital.font.roundness
                        usePercentTooltip: false
                        buttonIcon: "line_curve"
                        from: 0
                        to: 100
                        onEdited: value => {
                            Config.options.background.widgets.clock.digital.font.roundness = value;
                        }
                    }
                }
            }

            WCSubsection {
                visible: settingsClock.cookiePresent
                title: Translation.tr("Cookie clock settings")
                WCGroup {   
                    WCSwitch {  
                        buttonIcon: "wand_stars"
                        text: Translation.tr("Auto styling with Gemini")
                        checked: Config.options.background.widgets.clock.cookie.aiStyling
                        onToggled: checked => {
                            Config.options.background.widgets.clock.cookie.aiStyling = checked;
                        }
                    }

                    WCSwitch {
                        buttonIcon: "airwave"
                        text: Translation.tr("Use old sine wave cookie implementation")
                        checked: Config.options.background.widgets.clock.cookie.useSineCookie
                        onToggled: checked => {
                            Config.options.background.widgets.clock.cookie.useSineCookie = checked;
                        }
                    }

                    WCSpin {
                        icon: "add_triangle"
                        text: Translation.tr("Sides")
                        value: Config.options.background.widgets.clock.cookie.sides
                        from: 0
                        to: 40
                        stepSize: 1
                        onEdited: value => {
                            Config.options.background.widgets.clock.cookie.sides = value;
                        }
                    }

                    WCSwitch {
                        buttonIcon: "autoplay"
                        text: Translation.tr("Constantly rotate")
                        checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                        onToggled: checked => {
                            Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
                        }
                    }

                    WCGroup {

                        WCSwitch {
                            enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                            buttonIcon: "brightness_7"
                            text: Translation.tr("Hour marks")
                            checked: Config.options.background.widgets.clock.cookie.hourMarks
                            onEnabledChanged: {
                                checked = Config.options.background.widgets.clock.cookie.hourMarks;
                            }
                            onToggled: checked => {
                                Config.options.background.widgets.clock.cookie.hourMarks = checked;
                            }
                        }

                        WCSwitch {
                            enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                            buttonIcon: "timer_10"
                            text: Translation.tr("Digits in the middle")
                            checked: Config.options.background.widgets.clock.cookie.timeIndicators
                            onEnabledChanged: {
                                checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                            }
                            onToggled: checked => {
                                Config.options.background.widgets.clock.cookie.timeIndicators = checked;
                            }
                        }
                    }
                }
            }

            WCGroup {
                Layout.topMargin: 10
                visible: settingsClock.cookiePresent
                WCSelection {
                    text: "Dial Style"
                    icon: "graph_6"
                    currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
                        if (newValue !== "dots" && newValue !== "full") {
                            Config.options.background.widgets.clock.cookie.hourMarks = false;
                        }
                        if (newValue === "numbers") {
                            Config.options.background.widgets.clock.cookie.timeIndicators = false;
                        }
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "none"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "graph_6",
                            value: "dots"
                        },
                        {
                            displayName: Translation.tr("Full"),
                            icon: "history_toggle_off",
                            value: "full"
                        },
                        {
                            displayName: Translation.tr("Numbers"),
                            icon: "counter_1",
                            value: "numbers"
                        }
                    ]
                }
                WCSelection {
                    icon: "highlighter_size_2"
                    text: Translation.tr("Hour hand")
                    currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Hollow"),
                            icon: "circle",
                            value: "hollow"
                        },
                        {
                            displayName: Translation.tr("Fill"),
                            icon: "eraser_size_5",
                            value: "fill"
                        },
                    ]
                }
                WCSelection {
                    text: Translation.tr("Minute hand")
                    icon: "eraser_size_1" 
                    currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Thin"),
                            icon: "line_end",
                            value: "thin"
                        },
                        {
                            displayName: Translation.tr("Medium"),
                            icon: "eraser_size_2",
                            value: "medium"
                        },
                        {
                            displayName: Translation.tr("Bold"),
                            icon: "eraser_size_4",
                            value: "bold"
                        },
                    ]
                }
                WCSelection {
                    text: Translation.tr("Second hand")
                    icon: "pen_size_1"
                    currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "radio",
                            value: "classic"
                        },
                        {
                            displayName: Translation.tr("Line"),
                            icon: "line_end",
                            value: "line"
                        },
                        {
                            displayName: Translation.tr("Dot"),
                            icon: "adjust",
                            value: "dot"
                        },
                    ]
                }
                WCSelection {
                    text: Translation.tr("Date style")
                    icon: "date_range"
                    currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.dateStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Bubble"),
                            icon: "bubble_chart",
                            value: "bubble"
                        },
                        {
                            displayName: Translation.tr("Border"),
                            icon: "rotate_right",
                            value: "border"
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "rectangle",
                            value: "rect"
                        }
                    ]
                }
            }
            
            WCSubsection {
                visible: Config.options.background.widgets.clock.style === "pixel"
                title: Translation.tr("Pixel Clock Settings")
                WCGroup {
                    visible: Config.options.background.widgets.clock.style === "pixel"
                    WCSelection {
                        text: Translation.tr("Pixel clock orientation")
                        visible: Config.options.background.widgets.clock.style === "pixel"
                        icon: "screen_rotation"
                        currentValue: Config.options.background.widgets.clock.pixel.orientation
                        onSelected: newValue => {
                            Config.options.background.widgets.clock.pixel.orientation = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Horizontal"),
                                icon: "swap_horiz",
                                value: "horizontal"
                            },
                            {
                                displayName: Translation.tr("Vertical"),
                                icon: "swap_vert",
                                value: "vertical"
                            }
                        ]
                    }
                }
            }

            WCSubsection {
                title: Translation.tr("Quote")
                WCGroup {
                    WCSwitch {
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.background.widgets.clock.quote.enable
                        onToggled: checked => {
                            Config.options.background.widgets.clock.quote.enable = checked;
                        }
                    }
                    WCSwitch {
                        buttonIcon: "font_download"
                        text: Translation.tr("Follow Clock Font")
                        enabled: Config.options.background.widgets.clock.style !== "pixel"
                        checked: Config.options.background.widgets.clock.quote.followClock
                        onToggled: checked => {
                            Config.options.background.widgets.clock.quote.followClock = checked;
                        }
                    }
                    WCText {
                        id: quoteField
                        Layout.fillWidth: true
                        fieldWidth: 300
                        buttonIcon: "format_quote"
                        text: Translation.tr("Quote")
                        placeholderText: Translation.tr("Quote")
                        value: Config.options.background.widgets.clock.quote.text
                        onValueChanged: {
                            quoteDebounceTimer.restart();
                        }

                        Timer {
                            id: quoteDebounceTimer
                            interval: 600
                            repeat: false
                            onTriggered: {
                                Config.options.background.widgets.clock.quote.text = quoteField.value;
                            }
                        }
                    }
                }
            }
        }

    WCSection {
            icon: "panorama"
            shape: MaterialShape.Shape.SoftBoom 
            title: Translation.tr("Custom Image")
            WCGroup {
                WCSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.customImage.enable
                    onToggled: checked => {
                        Config.options.background.widgets.customImage.enable = checked;
                    }
                }
                ConfigSelectionShapeArray {
                    currentValue: Config.options.background.widgets.customImage.shape
                    shapeColor: Appearance.colors.colPrimary
                    backgroundColor: Appearance.colors.colPrimaryContainer
                    options: [
                        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill",
                        "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny",
                        "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided",
                        "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", "SoftBurst", "Flower",
                        "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart"
                    ]
                    onSelected: newValue => {
                        Config.options.background.widgets.customImage.shape = newValue
                    }
                }
                WCSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "photo_size_select_large"
                    text: Translation.tr("Image card")
                    checked: Config.options.background.widgets.imageCard.enable
                    onToggled: checked => {
                        Config.options.background.widgets.imageCard.enable = checked;
                    }
                }
                WCSelection {
                    enabled: Config.options.background.widgets.imageCard.enable
                    text: Translation.tr("Image card layout")
                    icon: "grid_view"
                    currentValue: Config.options.background.widgets.imageCard.sizeMode
                    options: [
                        { displayName: "1x1", icon: "crop_square", value: "1x1" },
                        { displayName: "1x2", icon: "crop_landscape", value: "1x2" },
                        { displayName: "1x3", icon: "crop_16_9", value: "1x3" },
                        { displayName: "2x2", icon: "grid_view", value: "2x2" },
                        { displayName: "2x3", icon: "view_module", value: "2x3" }
                    ]
                    onSelected: newValue => {
                        Config.options.background.widgets.imageCard.sizeMode = newValue
                    }
                }
            }
        }

    WCSection {
            id: settingsVisualizer
            icon: "graphic_eq"
            shape: MaterialShape.Shape.Burst
            title: Translation.tr("Visualizer")

            readonly property var entry: Config.options.background.widgets.visualizer
            readonly property bool bandStyle: ["mirror", "aurora", "dots"].includes(entry.style)

            WCGroup {
                WCSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: settingsVisualizer.entry.enable
                    onToggled: checked => {
                        settingsVisualizer.entry.enable = checked;
                    }
                }
                WCSelection {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: settingsVisualizer.entry.style
                    onSelected: newValue => {
                        settingsVisualizer.entry.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Classic"),
                            icon: "bar_chart",
                            value: "bars"
                        },
                        {
                            displayName: Translation.tr("Mirror"),
                            icon: "equalizer",
                            value: "mirror"
                        },
                        {
                            displayName: Translation.tr("Aurora"),
                            icon: "waves",
                            value: "aurora"
                        },
                        {
                            displayName: Translation.tr("Ring"),
                            icon: "album",
                            value: "ring"
                        },
                        {
                            displayName: Translation.tr("Dots"),
                            icon: "grid_on",
                            value: "dots"
                        }
                    ]
                }

                WCSelection {
                    text: Translation.tr("Colors")
                    icon: "palette"
                    enabled: settingsVisualizer.entry.style !== "bars"
                    currentValue: settingsVisualizer.entry.colorSource
                    onSelected: newValue => {
                        settingsVisualizer.entry.colorSource = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Theme"),
                            icon: "palette",
                            value: "theme"
                        },
                        {
                            displayName: Translation.tr("Album cover"),
                            icon: "album",
                            value: "cover"
                        }
                    ]
                }
        
                WCSlider {
                    text: Translation.tr("Sensitivity (%)")
                    buttonIcon: "tune"
                    usePercentTooltip: false
                    enabled: settingsVisualizer.entry.style !== "bars"
                    value: settingsVisualizer.entry.sensitivity * 100
                    from: 50
                    to: 300
                    stopIndicatorValues: [100]
                    onEdited: value => {
                        settingsVisualizer.entry.sensitivity = Math.round(value) / 100;
                    }
                }
                WCSlider {
                    text: Translation.tr("Height")
                    buttonIcon: "height"
                    usePercentTooltip: false
                    enabled: settingsVisualizer.entry.style !== "bars" && settingsVisualizer.bandStyle
                    value: settingsVisualizer.entry.height
                    from: 120
                    to: 600
                    stopIndicatorValues: [260]
                    onEdited: value => {
                        settingsVisualizer.entry.height = Math.round(value);
                    }
                }
                WCSlider {
                    text: Translation.tr("Size")
                    buttonIcon: "aspect_ratio"
                    usePercentTooltip: false
                    enabled: settingsVisualizer.entry.style === "ring"
                    value: settingsVisualizer.entry.ringSize
                    from: 200
                    to: 900
                    stopIndicatorValues: [380]
                    onEdited: value => {
                        settingsVisualizer.entry.ringSize = Math.round(value);
                    }
                }
            }
        }

    WCSection {
            id: settingsCustomText
            icon: "text_fields"
            shape: MaterialShape.Shape.Cookie4Sided
            title: Translation.tr("Text")

            readonly property var entry: Config.options.background.widgets.customText

            WCGroup {
                WCSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: settingsCustomText.entry.enable
                    onToggled: checked => {
                        settingsCustomText.entry.enable = checked;
                    }
                }
                WCSwitch {
                    Layout.fillWidth: true
                    buttonIcon: "shadow"
                    text: Translation.tr("Shadow")
                    checked: settingsCustomText.entry.shadow
                    onToggled: checked => {
                        settingsCustomText.entry.shadow = checked;
                    }
                }
                WCText {
                    id: customTextContentField
                    Layout.fillWidth: true
                    buttonIcon: "edit_note"
                    text: Translation.tr("Text to display")
                    description: Translation.tr("Double-click the text on your desktop to edit it, drag its corner to resize it")
                    placeholderText: Translation.tr("Text to display")
                    multiline: true
                    fieldWidth: 280
                    fieldHeight: 76
                    value: settingsCustomText.entry.content
                    onValueChanged: customTextContentDebounce.restart()

                    Timer {
                        id: customTextContentDebounce
                        interval: 500
                        onTriggered: {
                            if (customTextContentField.value !== settingsCustomText.entry.content)
                                settingsCustomText.entry.content = customTextContentField.value
                        }
                    }
                }
            }

            WCSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Font")

                WCGroup {
                    WCCombo {
                        Layout.fillWidth: true
                        buttonIcon: "font_download"
                        fieldWidth: 50
                        text: Translation.tr("Font family")
                        textRole: "displayName"
                        model: Fonts.handwritingFamilies.map(family => ({
                            displayName: family,
                            value: family
                        }))
                        currentValue: settingsCustomText.entry.fontFamily
                        onSelected: newValue => { settingsCustomText.entry.fontFamily = newValue; }
                    }
                    WCText {
                        id: settingsCustomFontField
                        buttonIcon: "custom_typography"
                        text: Translation.tr("Custom Font")
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        placeholderText: Translation.tr("Any installed font family")
                        value: Fonts.handwritingFamilies.includes(settingsCustomText.entry.fontFamily) ? "" : settingsCustomText.entry.fontFamily

                        onValueChanged: {
                            customTextFontDebounce.restart();
                        }

                        Timer {
                            id: customTextFontDebounce
                            interval: 500
                            repeat: false
                            onTriggered: {
                                if (settingsCustomFontField.value.trim() !== "")
                                    settingsCustomText.entry.fontFamily = settingsCustomFontField.value.trim()
                            }
                        }
                    }

                    WCSlider {
                        text: Translation.tr("Font size")
                        value: settingsCustomText.entry.fontSize
                        usePercentTooltip: false
                        buttonIcon: "format_size"
                        from: 12
                        to: 400
                        stopIndicatorValues: [72]
                        onEdited: value => {
                            settingsCustomText.entry.fontSize = Math.round(value);
                        }
                    }

                    WCSelection {
                        text: Translation.tr("Alignment")
                        icon: "format_align_center"
                        currentValue: settingsCustomText.entry.alignment
                        onSelected: newValue => {
                            settingsCustomText.entry.alignment = newValue;
                        }
                        options: [
                            {
                                displayName: Translation.tr("Left"),
                                icon: "format_align_left",
                                value: "left"
                            },
                            {
                                displayName: Translation.tr("Center"),
                                icon: "format_align_center",
                                value: "center"
                            },
                            {
                                displayName: Translation.tr("Right"),
                                icon: "format_align_right",
                                value: "right"
                            }
                        ]
                    }
                }
            }

            WCSubsection {
                Layout.topMargin: 10
                title: Translation.tr("Colors")
                
                WCGroup {
                    WCSwitch {
                        id: customTextAutoColorSwitch
                        buttonIcon: "auto_awesome"
                        text: Translation.tr("Automatic colors")
                        checked: settingsCustomText.entry.color === ""
                        onToggled: checked => {
                            if (checked) {
                                settingsCustomText.entry.color = ""
                            }
                        }
                    }

                    WCColors {
                        icon: "palette"
                        text: Translation.tr("Color")
                        currentValue: settingsCustomText.entry.color
                        onSelected: newValue => {
                            settingsCustomText.entry.color = newValue
                            customTextAutoColorSwitch.checked = false
                        }
                    }
                }
            }
        }

    WCSection {
            icon: "widgets"
            shape: MaterialShape.Shape.Pill
            title: Translation.tr("Widgets")
            hint: Translation.tr("Widgets with a star are shown in the desktop menu")
            hintIcon: "info"

            WCSubsection {
                title: Translation.tr("Show widgets on")
                visible: Hyprland.monitors.values.length > 1
                Layout.bottomMargin: 10

                WidgetsMonitorSelector {
                    configEntry: Config.options.background
                }
            }
            
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8
                Repeater {
                    model: [
                        {
                            icon: "weather_mix",
                            key: "weather",
                            name: Translation.tr("Weather"),
                            enabled: Config.options.background.widgets.weather.enable
                        },
                        {
                            icon: "image",
                            key: "images",
                            name: Translation.tr("Image converter"),
                            enabled: Config.options.background.widgets.images.enable
                        },
                        {
                            icon: "music_note",
                            key: "media",
                            name: Translation.tr("Media Player"),
                            enabled: Config.options.background.widgets.media.enable
                        },
                        {
                            icon: "memory",
                            key: "resources",
                            name: Translation.tr("Resources"),
                            enabled: Config.options.background.widgets.resources.enable
                        },
                        {
                            icon: "calendar_month",
                            key: "calendar",
                            name: Translation.tr("Calendar"),
                            enabled: Config.options.background.widgets.calendar.enable
                        },
                        {
                            icon: "public",
                            key: "worldClock",
                            name: Translation.tr("World Clock"),
                            enabled: Config.options.background.widgets.worldClock.enable
                        },
                        {
                            icon: "person",
                            key: "userCard",
                            name: Translation.tr("User Card"),
                            enabled: Config.options.background.widgets.userCard.enable
                        },
                        {
                            icon: "note_stack_add",
                            key: "notes",
                            name: Translation.tr("Notes"),
                            enabled: Config.options.background.widgets.notes.enable
                        },
                        {
                            icon: "add_task",
                            key: "todo",
                            name: Translation.tr("To-Do"),
                            enabled: Config.options.background.widgets.todo.enable
                        },
                        {
                            icon: "timer",
                            key: "timers",
                            name: Translation.tr("Timers"),
                            enabled: Config.options.background.widgets.timers.enable
                        },
                        {
                            icon: "sticker",
                            key: "sticker",
                            name: Translation.tr("Sticker"),
                            enabled: Config.options.background.widgets.sticker.enable
                        },
                        
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 105
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer1
                        border.width: 1
                        border.color: Appearance.colors.colLayer0Border
                        ColumnLayout {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 12
                            }
                            spacing: 0
                            RowLayout {
                                Layout.fillWidth: true
                                MaterialSymbol {
                                    text: modelData.icon
                                    iconSize: Appearance.font.pixelSize.normal + 5
                                    color: Appearance.colors.colPrimary
                                }
                                Item { Layout.fillWidth: true }
                                WCSwitch {
                                    checked: modelData.enabled
                                    onToggled: checked => {
                                        if (modelData.icon === "weather_mix")
                                            Config.options.background.widgets.weather.enable = checked
                                        else if (modelData.icon === "image")
                                            Config.options.background.widgets.images.enable = checked
                                        else if (modelData.icon === "music_note")
                                            Config.options.background.widgets.media.enable = checked
                                        else if (modelData.icon === "memory")
                                            Config.options.background.widgets.resources.enable = checked
                                        else if (modelData.icon === "calendar_month")
                                            Config.options.background.widgets.calendar.enable = checked
                                        else if (modelData.icon === "public")
                                            Config.options.background.widgets.worldClock.enable = checked
                                        else if (modelData.icon === "person")
                                            Config.options.background.widgets.userCard.enable = checked
                                        else if (modelData.icon === "note_stack_add")
                                            Config.options.background.widgets.notes.enable = checked
                                        else if (modelData.icon === "add_task")
                                            Config.options.background.widgets.todo.enable = checked
                                        else if (modelData.icon === "timer")
                                            Config.options.background.widgets.timers.enable = checked
                                        else if (modelData.icon === "sticker")
                                            Config.options.background.widgets.sticker.enable = checked
                                    }
                                }
                            }
                            StyledText {
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: modelData.enabled ? Translation.tr("Enabled") : Translation.tr("Disabled")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        RippleButton {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 8
                            implicitWidth: 30
                            implicitHeight: 30
                            buttonRadius: 15
                            colBackground: "transparent"
                            downAction: () => DesktopWidgets.toggleStar(modelData.key)
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: "star"
                                fill: DesktopWidgets.isStarred(modelData.key) ? 1 : 0
                                iconSize: Appearance.font.pixelSize.larger
                                color: DesktopWidgets.isStarred(modelData.key) ? Appearance.colors.colTertiary : Appearance.colors.colSubtext
                            }
                            StyledToolTip {
                                text: DesktopWidgets.isStarred(modelData.key) ? Translation.tr("Shown in the desktop menu") : Translation.tr("Hidden from the desktop menu")
                            }
                        }
                    }
                }
            }
            WCSubsection {
                title: Translation.tr("Also in the desktop menu")
                Layout.bottomMargin: 10

                WCGroup {
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "schedule"
                        text: Translation.tr("Clock")
                        checked: DesktopWidgets.isStarred("clock")
                        onToggled: checked => DesktopWidgets.setStarred("clock", checked)
                    }
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "graphic_eq"
                        text: Translation.tr("Visualizer")
                        checked: DesktopWidgets.isStarred("visualizer")
                        onToggled: checked => DesktopWidgets.setStarred("visualizer", checked)
                    }
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "image"
                        text: Translation.tr("Custom Image")
                        checked: DesktopWidgets.isStarred("customImage")
                        onToggled: checked => DesktopWidgets.setStarred("customImage", checked)
                    }
                }
            }
            WCSubsection {
                title: Translation.tr("Canvas")
                Layout.bottomMargin: 10

                WCGroup {
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "grid_4x4"
                        text: Translation.tr("Show alignment grid while dragging")
                        checked: Config.options.background.showGrid
                        onToggled: checked => {
                            Config.options.background.showGrid = checked;
                        }
                    }
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "align_horizontal_center"
                        text: Translation.tr("Show snap lines when dropping")
                        checked: Config.options.background.showSnapLines
                        onToggled: checked => {
                            Config.options.background.showSnapLines = checked;
                        }
                    }
                }
            }
        }

}
