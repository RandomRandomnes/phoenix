// Generated 2026-10-15 from illogical-impulse's InterfaceConfig.qml (Phoenix: the old settings moved into
// the Windows-style settings). Edit freely; it isn't regenerated.
import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: page
    Layout.fillWidth: true
    spacing: 8

    WCSection { // I see that for many the overview is important, I put it first why not
            visible: WM.compositor !== "niri"
            icon: "overview_key"
            shape: MaterialShape.Shape.Gem
            title: Translation.tr("Overview")

            WCGroup {
                WCSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.overview.enable
                    onCheckedChanged: {
                        Config.options.overview.enable = checked;
                    }
                }
                WCSwitch {
                    buttonIcon: "center_focus_strong"
                    text: Translation.tr("Center icons")
                    checked: Config.options.overview.centerIcons
                    onCheckedChanged: {
                        Config.options.overview.centerIcons = checked;
                    }
                }
                WCSpin {
                    icon: "loupe"
                    text: Translation.tr("Scale (%)")
                    value: Config.options.overview.scale * 100
                    from: 1
                    to: 100
                    stepSize: 1
                    onValueChanged: {
                        Config.options.overview.scale = value / 100;
                    }
                }
                WCSelection {
                    text: Translation.tr("Style")
                    icon: "style"
                    currentValue: Config.options.overview.style
                    onSelected: newValue => {
                        Config.options.overview.style = newValue
                    }
                    options: [
                        {
                            displayName: Translation.tr("Default"),
                            icon: "grid_on",
                            value: "default"
                        },
                        {
                            displayName: Translation.tr("Niri Like"),
                            icon: "mobiledata_arrows",
                            value: "niri"
                        }
                    ]
                }
            }

            WCSubsection {
                title: Translation.tr("Default Settings")
                visible: Config.options.overview.style !== "niri"

                WCGroup {
                    visible: Config.options.overview.style !== "niri"
                    WCGroup {
                        uniform: true
                        visible: Config.options.overview.style !== "niri"
                        WCSpin {
                            icon: "splitscreen_bottom"
                            text: Translation.tr("Rows")
                            value: Config.options.overview.rows
                            from: 1
                            to: 20
                            stepSize: 1
                            onValueChanged: {
                                Config.options.overview.rows = value;
                            }
                        }
                        WCSpin {
                            icon: "splitscreen_right"
                            text: Translation.tr("Columns")
                            value: Config.options.overview.columns
                            from: 1
                            to: 20
                            stepSize: 1
                            onValueChanged: {
                                Config.options.overview.columns = value;
                            }
                        }
                    }

                    WCGroup {
                        uniform: true
                        visible: Config.options.overview.style !== "niri"
                        WCSelection {
                            text: Translation.tr("Workspace order (across)")
                            icon: "swap_horiz"
                            currentValue: Config.options.overview.orderRightLeft
                            onSelected: newValue => {
                                Config.options.overview.orderRightLeft = newValue
                            }
                            options: [
                                {
                                    displayName: Translation.tr("Left to right"),
                                    icon: "arrow_forward",
                                    value: 0
                                },
                                {
                                    displayName: Translation.tr("Right to left"),
                                    icon: "arrow_back",
                                    value: 1
                                }
                            ]
                        }
                        WCSelection {
                            text: Translation.tr("Workspace order (down)")
                            icon: "swap_vert"
                            currentValue: Config.options.overview.orderBottomUp
                            onSelected: newValue => {
                                Config.options.overview.orderBottomUp = newValue
                            }
                            options: [
                                {
                                    displayName: Translation.tr("Top-down"),
                                    icon: "arrow_downward",
                                    value: 0
                                },
                                {
                                    displayName: Translation.tr("Bottom-up"),
                                    icon: "arrow_upward",
                                    value: 1
                                }
                            ]
                        }
                    }
                }
            }
        }

}
