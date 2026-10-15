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
            icon: "panorama"
            title: Translation.tr("Wallpaper")
            shape: MaterialShape.Shape.Clover4Leaf

            Rectangle {
                Layout.fillWidth: true
                visible: WM.compositor !== "niri"
                implicitHeight: wrapperCol.implicitHeight + 16
                topLeftRadius: Appearance.rounding.verylarge
                topRightRadius: Appearance.rounding.verylarge
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: wrapperCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Carousel {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        largeItemWidthRatio: 0.5
                        mediumItemWidthRatio: 0.485
                        itemSpacing: 8
                        model: [
                            page.displayPathFor(Config.options.background.wallpaperPath),
                            page.displayPathFor(
                                Config.options.background.lockWall !== ""
                                    ? Config.options.background.lockWall
                                    : Config.options.background.wallpaperPath
                            )
                        ]
                        wheelEnabled: false
                        dragEnabled: false
                        clickAction: (index, modelData) => {
                            GlobalStates.wallpaperSelectorTarget = index === 1 ? "lockWall" : "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    text: "desktop_windows"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: Translation.tr("Desktop")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 24
                            radius: Appearance.rounding.normal
                            color: "transparent"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol {
                                    text: "lock"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    text: Translation.tr("Lockscreen")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: WM.compositor === "niri"
                implicitHeight: niriWrapperCol.implicitHeight + 16
                topLeftRadius: Appearance.rounding.verylarge
                topRightRadius: Appearance.rounding.verylarge
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: Appearance.rounding.normal
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: niriWrapperCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Carousel {
                        Layout.fillWidth: true
                        implicitHeight: 280
                        largeItemWidthRatio: 1
                        mediumItemWidthRatio: 0
                        itemSpacing: 8
                        model: [page.displayPathFor(Config.options.background.wallpaperPath)]
                        wheelEnabled: false
                        dragEnabled: false
                        clickAction: (index, modelData) => {
                            GlobalStates.wallpaperSelectorTarget = "wallpaper"
                            GlobalStates.wallpaperSelectorOpen = true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: Appearance.rounding.normal
                        color: "transparent"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: "image"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: Config.options.background.wallpaperPath.split("/").pop()
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                }
            }

            WCGroup {
                Layout.topMargin: -2

                WCSwitch {
                    id: syncWallpaperSwitch
                    buttonIcon: "sync"
                    text: Translation.tr("Use same wallpaper for both")
                    checked: Config.options.background.lockWall === ""
                    onCheckedChanged: {
                        if (checked) {
                            Config.options.background.lockWall = "";
                        }
                    }
                }

                WCSwitch {
                    buttonIcon: "preview"
                    text: Translation.tr("Preview wallpaper")
                    checked: Config.options.background.enableWallpaperPreview
                    onCheckedChanged: {
                        Config.options.background.enableWallpaperPreview = checked;
                    }
                }

                WCSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Blur wall")
                    checked: Config.options.background.showBlur
                    onCheckedChanged: {
                        Config.options.background.showBlur = checked;
                    }
                }

                WCSlider {
                    Layout.fillWidth: true
                    text: Translation.tr("Blur Size")
                    value: Config.options.background.blurRadius ?? 32
                    usePercentTooltip: false
                    buttonIcon: "aspect_ratio"
                    from: 1
                    to: 64
                    stopIndicatorValues: [32]
                    onValueChanged: Config.options.background.blurRadius = value
                }

                WCSelection {
                    text: Translation.tr("Split blur amount")
                    icon: "split_scene"
                    currentValue: Config.options.background.splitRatio
                    options: [
                        { "displayName": "25%",  "icon": "thumbnail_bar",              "value": "25" },
                        { "displayName": "50%",  "icon": "side_navigation",              "value": "50" },
                        { "displayName": "100%", "icon": "fullscreen",    "value": "100" },
                    ]
                    onSelected: newValue => {
                        Config.options.background.splitRatio = newValue
                    }
                }

                WCSelection {
                    text: Translation.tr("Split blur side")
                    icon: "align_horizontal_left"
                    currentValue: Config.options.background.splitSide
                    options: [
                        { "displayName": Translation.tr("Left"),  "icon": "align_horizontal_left",  "value": "left" },
                        { "displayName": Translation.tr("Right"), "icon": "align_horizontal_right", "value": "right" },
                    ]
                    onSelected: newValue => {
                        Config.options.background.splitSide = newValue
                    }
                }

                WCSpin {
                    icon: "timer"
                    text: Translation.tr("Wallpaper change interval (min)")
                    value: Config.options.wallpaperSelector.changeInterval / 60000
                    from: 0
                    to: 1440
                    stepSize: 5
                    onValueChanged: {
                        Config.options.wallpaperSelector.changeInterval = value * 60000;
                    }
                }

                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "texture"
                    text: Translation.tr("Transitions")
                    fieldWidth: 50
                    model: [
                        { displayName: Translation.tr("None"), icon: "block", value: "" },
                        { displayName: Translation.tr("Circle"), icon: "circle", value: "circleSelect" },
                        { displayName: Translation.tr("Circle Pit"), icon: "blur_circular", value: "circlePit" },
                        { displayName: Translation.tr("Magic"), icon: "auto_awesome", value: "magic" },
                        { displayName: Translation.tr("Doom"), icon: "whatshot", value: "Doom" },
                        { displayName: Translation.tr("Peel"), icon: "layers", value: "Peel" },
                        { displayName: Translation.tr("Fade"), icon: "gradient", value: "transition" },
                        { displayName: Translation.tr("Pixelate"), icon: "grain", value: "pixelate" },
                        { displayName: Translation.tr("Stripes"), icon: "texture_minus", value: "stripes" },
                        { displayName: Translation.tr("CRT"), icon: "tv", value: "crt" },
                        { displayName: Translation.tr("Dissolve"), icon: "blur_on", value: "dissolve" },
                        { displayName: Translation.tr("Glitch"), icon: "bug_report", value: "glitch" },
                        { displayName: Translation.tr("Ripple"), icon: "water", value: "ripple" },
                        { displayName: Translation.tr("Shatter"), icon: "broken_image", value: "shatter" },
                        { displayName: Translation.tr("Random"), icon: "shuffle", value: "random" },
                    ]
                    currentValue: Config.options.background.wallpaperAnimation
                    onSelected: newValue => {
                        Config.options.background.wallpaperAnimation = newValue;
                    }
                }
            }

            Connections {
                target: Config.options.background
                function onLockWallChanged() {
                    syncWallpaperSwitch.checked = Qt.binding(() => Config.options.background.lockWall === "")
                }
            }
        
            WCSubsection {
                title: Translation.tr("Centered wallpaper")
                Layout.fillWidth: true

                WCGroup {
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "check"
                        text: Translation.tr("Enable")
                        checked: Config.options.background.centeredWallpaper
                        onClicked: {
                            Config.options.background.centeredWallpaper = !Config.options.background.centeredWallpaper;
                        }
                    }
                    WCSwitch {
                        Layout.fillWidth: true
                        buttonIcon: "lock"
                        text: Translation.tr("Show only when locked")
                        checked: Config.options.background.centeredWallpaperOnlyWhenLocked
                        onCheckedChanged: {
                            Config.options.background.centeredWallpaperOnlyWhenLocked = checked;
                        }
                        enabled: Config.options.background.centeredWallpaper && WM.compositor !== "niri"
                    }
                }

                WCGroup {
                    Layout.topMargin: 0
                    visible: Config.options.background.centeredWallpaper
                    ConfigSelectionShapeArray {
                        currentValue: Config.options.background.centeredWallpaperShape
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
                            Config.options.background.centeredWallpaperShape = newValue
                        }
                    }
                    WCColors {
                        visible: Config.options.background.centeredWallpaper
                        icon: "palette"
                        text: Translation.tr("Background Color")
                        currentValue: Config.options.background.centeredWallpaperColor
                        onSelected: newValue => {
                            Config.options.background.centeredWallpaperColor = newValue
                        }
                    }
                    WCSlider {
                        visible: Config.options.background.centeredWallpaper
                        text: Translation.tr("Size")
                        value: Config.options.background.centeredWallpaperSize
                        usePercentTooltip: false
                        buttonIcon: "aspect_ratio"
                        from: 400
                        to: 800
                        stopIndicatorValues: [400]
                        onValueChanged: {
                            Config.options.background.centeredWallpaperSize = value;
                        }
                    }
                }
            }
        }

    WCSection {
            icon: "grid_view"
            shape: MaterialShape.Shape.Square
            title: Translation.tr("Multiple wallpapers")

            WCGroup {
                WCSwitch {
                    buttonIcon: "dashboard"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.collage.enable
                    onCheckedChanged: {
                        if (checked && !Config.options.background.collage.enable) Collage.reset()
                        Config.options.background.collage.enable = checked
                    }
                }
                WCCombo {
                    Layout.fillWidth: true
                    buttonIcon: "dashboard_customize"
                    text: Translation.tr("Layout")
                    fieldWidth: 220
                    fixedWidth: true
                    model: Collage.presetOptions
                    currentValue: Collage.currentPreset
                    onSelected: newValue => Collage.applyPresetByName(newValue)
                }
                WCSpin {
                    icon: "space_bar"
                    text: Translation.tr("Spacing")
                    value: Config.options.background.collage.gap
                    from: 0
                    to: 80
                    stepSize: 2
                    onValueChanged: Config.options.background.collage.gap = value
                }
                WCSpin {
                    icon: "crop_free"
                    text: Translation.tr("Outer margin")
                    value: Config.options.background.collage.margin
                    from: 0
                    to: 120
                    stepSize: 2
                    onValueChanged: Config.options.background.collage.margin = value
                }
                WCSpin {
                    icon: "rounded_corner"
                    text: Translation.tr("Corner radius")
                    value: Config.options.background.collage.radius
                    from: 0
                    to: 80
                    stepSize: 2
                    onValueChanged: Config.options.background.collage.radius = value
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    StyledText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colSubtext
                        text: Translation.tr("Arrange the tiles from the desktop while widgets are unlocked: split, remove, change the image and drag the borders. The starred tile sets the colors and the blurred backdrop.")
                    }
                    RippleButton {
                        implicitWidth: resetLabel.implicitWidth + 24
                        implicitHeight: 36
                        buttonRadius: Appearance.rounding.full
                        onClicked: Collage.reset()
                        contentItem: StyledText {
                            id: resetLabel
                            anchors.centerIn: parent
                            text: Translation.tr("Reset layout")
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

}
