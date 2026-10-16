import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

Item {
    id: root

    Loader {
        anchors.fill: parent
        sourceComponent: ({ "bluetooth": bluetooth, "mouse": mouse, "keyboard": keyboard, "input": inputPage,
            "phone": phonePage
        })[WState.sub] ?? overview
    }

    // Device row with connect/forget buttons (shared by overview + Devices page)
    component DeviceCard: WCard {
        id: dc
        required property var device
        readonly property bool connected: BluetoothStatus.isConnected(device)
        icon: device?.icon ? Icons.getBluetoothDeviceMaterialSymbol(device.icon) : "bluetooth"
        title: device?.name || device?.address || "Unknown device"
        description: {
            if (connected) return "Connected" + (device.batteryAvailable ? ` · Battery ${Math.round(device.battery * 100)}%` : "");
            if (device?.pairing) return "Pairing…";
            if (device?.state === BluetoothDeviceState.Connecting) return "Connecting…";
            return device?.paired ? "Paired" : "Not paired";
        }
        WButton {
            buttonText: dc.connected ? "Disconnect" : "Connect"
            accent: !dc.connected
            onClicked: dc.connected ? dc.device.disconnect() : dc.device.connect()
        }
        WButton {
            visible: dc.device?.paired ?? false
            buttonText: "Remove"
            onClicked: dc.device.forget()
        }
        WButton {
            visible: !(dc.device?.paired ?? true)
            buttonText: "Pair"
            onClicked: { dc.device.trusted = true; dc.device.pair(); }
        }
    }

    component BluetoothToggleCard: WToggle {
        icon: "bluetooth"
        title: "Bluetooth"
        description: !BluetoothStatus.available ? "No Bluetooth adapter found"
            : BluetoothStatus.enabled ? `Discoverable as "${Bluetooth.defaultAdapter?.name ?? ""}"` : "Off"
        enabled: BluetoothStatus.available
        checked: BluetoothStatus.enabled
        onToggled: v => { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = v }
    }

    // ── Overview ───────────────────────────────────────────────────
    Component {
        id: overview
        WPage {
            WSection {
                BluetoothToggleCard {}
                Repeater {
                    model: BluetoothStatus.connectedDevices
                    DeviceCard { required property var modelData; device: modelData }
                }
                WLink { icon: "devices"; title: "View more devices"; description: "Pair new devices, connect, remove"; sub: "bluetooth" }
            }
            WSection {
                title: "Phone"
                WLink {
                    icon: "smartphone"
                    title: PhoneLink.phone ? PhoneLink.phone.name : "Phone Link"
                    description: !PhoneLink.installed ? "Your phone's notifications, texts, files and more on this PC (set up once)"
                        : !PhoneLink.phone ? "No phone paired yet"
                        : PhoneLink.phone.reachable ? `Connected` + (PhoneLink.phone.battery !== null ? ` · battery ${PhoneLink.phone.battery}%` : "")
                        : "Paired · not connected right now"
                    sub: "phone"
                }
            }
            WSection {
                title: "Batteries"
                WToggle {
                    icon: "battery_full"
                    title: "Show device batteries in the sidebar"
                    description: "Battery levels of your mouse, headphones, controllers and other wireless devices, under the media controls"
                    checked: Config.options.sidebar.deviceBatteries
                    onToggled: v => Config.options.sidebar.deviceBatteries = v
                }
            }
            WSection {
                title: "Input"
                WLink { icon: "mouse"; title: "Mouse"; description: "Pointer speed, acceleration, scrolling, primary button"; sub: "mouse" }
                WLink { icon: "keyboard"; title: "Keyboard"; description: "Layout, repeat rate, on-screen keyboard"; sub: "keyboard" }
            }
            WSection {
                title: "Related settings"
                WLink { icon: "settings_bluetooth"; title: "More Bluetooth settings"; chevronIcon: "open_in_new"; action: () => Quickshell.execDetached(["bash", "-c", Config.options.apps.bluetooth]) }
            }
            WSection {
                title: "More"
                WLink { icon: "mouse"; title: "Mouse, keyboard & touchpad (advanced)"; description: "Pointer speed, acceleration, touchpad gestures, keyboard repeat"; sub: "input" }
            }
        }
    }

    // ── Devices ────────────────────────────────────────────────────
    Component {
        id: bluetooth
        WPage {
            Component.onDestruction: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.discovering = false
            WSection {
                BluetoothToggleCard {}
                WCard {
                    icon: "add"
                    title: "Add device"
                    description: (Bluetooth.defaultAdapter?.discovering ?? false) ? "Searching for nearby devices… make sure yours is in pairing mode" : "Search for headphones, controllers, keyboards and more"
                    enabled: BluetoothStatus.enabled
                    WButton {
                        accent: !(Bluetooth.defaultAdapter?.discovering ?? false)
                        buttonText: (Bluetooth.defaultAdapter?.discovering ?? false) ? "Stop" : "Add device"
                        onClicked: Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
                    }
                }
            }
            WSection {
                title: "Connected"
                visible: BluetoothStatus.connectedDevices.length > 0
                Repeater {
                    model: BluetoothStatus.connectedDevices
                    DeviceCard { required property var modelData; device: modelData }
                }
            }
            WSection {
                title: "Paired"
                visible: BluetoothStatus.pairedButNotConnectedDevices.length > 0
                Repeater {
                    model: BluetoothStatus.pairedButNotConnectedDevices
                    DeviceCard { required property var modelData; device: modelData }
                }
            }
            WSection {
                title: "Nearby"
                visible: Bluetooth.defaultAdapter?.discovering ?? false
                Repeater {
                    model: BluetoothStatus.unpairedDevices.filter(d => d.name && d.name !== d.address.replace(/:/g, "-"))
                    DeviceCard { required property var modelData; device: modelData }
                }
            }
        }
    }

    // ── Mouse ──────────────────────────────────────────────────────
    Component {
        id: mouse
        WPage {
            id: mp
            HyprlandConfigOption { id: sens; key: "input:sensitivity" }
            HyprlandConfigOption { id: accel; key: "input:accel_profile" }
            HyprlandConfigOption { id: natural; key: "input:natural_scroll" }
            HyprlandConfigOption { id: leftHanded; key: "input:left_handed" }
            HyprlandConfigOption { id: scroll; key: "input:scroll_factor" }
            function put(opt, v) { opt.value = v; opt.setValue(v); }

            property bool hasTouchpad: false
            Process {
                running: true
                command: ["bash", "-c", "hyprctl devices -j | jq '[.mice[].name | select(test(\"touchpad|trackpad\";\"i\"))] | length'"]
                stdout: StdioCollector { onStreamFinished: mp.hasTouchpad = parseInt(text) > 0 }
            }

            WSection {
                title: "Mouse"
                WCombo {
                    icon: "left_click"
                    title: "Primary mouse button"
                    model: [{ displayName: "Left", value: false }, { displayName: "Right", value: true }]
                    currentValue: !!leftHanded.value
                    onSelected: v => mp.put(leftHanded, v ? 1 : 0)
                }
                WSlider {
                    icon: "speed"
                    title: "Mouse pointer speed"
                    from: -1; to: 1; stepSize: 0.05
                    format: v => `${Math.round((v + 1) * 10)}`
                    value: sens.value ?? 0
                    onMoved: v => mp.put(sens, Math.round(v * 100) / 100)
                }
                WToggle {
                    icon: "trending_up"
                    title: "Enhanced pointer precision"
                    description: "Mouse acceleration: the pointer moves farther when you move the mouse faster"
                    checked: (accel.value ?? "") !== "flat"
                    onToggled: v => mp.put(accel, v ? "adaptive" : "flat")
                }
            }
            WSection {
                title: "Scrolling"
                WSlider {
                    icon: "swap_vert"
                    title: "Scroll speed"
                    from: 0.2; to: 3; stepSize: 0.1
                    format: v => `${v.toFixed(1)}×`
                    value: scroll.value ?? 1
                    onMoved: v => mp.put(scroll, Math.round(v * 10) / 10)
                }
                WToggle {
                    icon: "swipe_vertical"
                    title: "Natural scrolling"
                    description: "Content moves the same direction as your fingers (reverse scroll direction)"
                    checked: !!natural.value
                    onToggled: v => mp.put(natural, v ? 1 : 0)
                }
            }
            WSection {
                title: "Touchpad"
                visible: mp.hasTouchpad
                WToggle {
                    icon: "swipe"
                    title: "Natural scrolling on touchpad"
                    checked: Config.options.hyprland.input.touchpad.naturalScroll
                    onToggled: v => { Config.options.hyprland.input.touchpad.naturalScroll = v; HyprlandConfig.set("input:touchpad:natural_scroll", v ? 1 : 0); }
                }
                WToggle {
                    icon: "keyboard_hide"
                    title: "Disable touchpad while typing"
                    checked: Config.options.hyprland.input.touchpad.disableWhileTyping
                    onToggled: v => { Config.options.hyprland.input.touchpad.disableWhileTyping = v; HyprlandConfig.set("input:touchpad:disable_while_typing", v ? 1 : 0); }
                }
                WSlider {
                    icon: "swap_vert"
                    title: "Touchpad scroll speed"
                    from: 0.1; to: 2; stepSize: 0.1
                    format: v => `${v.toFixed(1)}×`
                    value: Config.options.hyprland.input.touchpad.scrollFactor
                    onMoved: v => { const r = Math.round(v * 10) / 10; Config.options.hyprland.input.touchpad.scrollFactor = r; HyprlandConfig.set("input:touchpad:scroll_factor", r); }
                }
            }
            WSection {
                title: "Related settings"
                WLink { icon: "ads_click"; title: "Focus follows mouse"; description: "In Multitasking"; page: "system"; sub: "multitasking" }
            }
        }
    }

    // ── Keyboard ───────────────────────────────────────────────────
    Component {
        id: keyboard
        WPage {
            WSection {
                title: "Typing"
                WCard {
                    icon: "language"
                    title: "Keyboard layout"
                    description: "XKB layout codes, comma separated for several (e.g. us,de). Current: " + HyprlandXkb.currentLayoutName
                    Rectangle {
                        implicitWidth: 160; implicitHeight: 34
                        radius: 12
                        color: Appearance.colors.colLayer4
                        border.width: kbInput.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary
                        TextInput {
                            id: kbInput
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: Text.AlignVCenter
                            color: Appearance.colors.colOnLayer3
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                            text: Config.options.hyprland.input.kbLayout
                            validator: RegularExpressionValidator { regularExpression: /^[a-z]{2,3}(\([a-z0-9_-]+\))?(,[a-z]{2,3}(\([a-z0-9_-]+\))?)*$/ }
                            onEditingFinished: if (acceptableInput && text !== Config.options.hyprland.input.kbLayout) {
                                Config.options.hyprland.input.kbLayout = text;
                                HyprlandConfig.set("input:kb_layout", text);
                            }
                        }
                    }
                }
                WSlider {
                    icon: "timer"
                    title: "Repeat delay"
                    description: "How long to hold a key before it starts repeating"
                    from: 150; to: 1000; stepSize: 25
                    format: v => `${Math.round(v)} ms`
                    value: Config.options.hyprland.input.repeatDelay
                    onMoved: v => { Config.options.hyprland.input.repeatDelay = Math.round(v); HyprlandConfig.set("input:repeat_delay", Math.round(v)); }
                }
                WSlider {
                    icon: "fast_forward"
                    title: "Repeat rate"
                    description: "How fast a held key repeats"
                    from: 10; to: 80; stepSize: 1
                    format: v => `${Math.round(v)}/s`
                    value: Config.options.hyprland.input.repeatRate
                    onMoved: v => { Config.options.hyprland.input.repeatRate = Math.round(v); HyprlandConfig.set("input:repeat_rate", Math.round(v)); }
                }
                WToggle {
                    icon: "dialpad"
                    title: "Turn on Num Lock at startup"
                    checked: Config.options.hyprland.input.numlock
                    onToggled: v => { Config.options.hyprland.input.numlock = v; HyprlandConfig.set("input:numlock_by_default", v ? 1 : 0); }
                }
            }
            WSection {
                title: "On-screen keyboard"
                WToggle {
                    icon: "keyboard"
                    title: "On-screen keyboard"
                    checked: GlobalStates.oskOpen
                    onToggled: v => GlobalStates.oskOpen = v
                }
                WToggle {
                    icon: "push_pin"
                    title: "Keep it pinned at startup"
                    checked: Config.options.osk.pinnedOnStartup
                    onToggled: v => Config.options.osk.pinnedOnStartup = v
                }
            }
            WSection {
                title: "Related"
                WLink { icon: "keyboard_command_key"; title: "Keyboard shortcuts"; description: "Edit your Hyprland keybinds file"; chevronIcon: "open_in_new"; action: () => Quickshell.execDetached(["xdg-open", `${Directories.config}/hypr/custom/keybinds.lua`.replace("file://", "")]) }
            }
        }
    }

    // Phoenix (2026-10-15): settings moved here from illogical-impulse's original settings
    Component {
        id: inputPage
        WPage {
            SInput {}
        }
    }

    // ── Phone (Phone Link / KDE Connect, P6 2026-10-15) ────────────
    Component {
        id: phonePage
        WPage {
            id: pp
            readonly property var phone: PhoneLink.phone
            readonly property bool online: phone?.reachable ?? false
            function pluginOn(name) { return pp.phone?.plugins?.[name] ?? true }
            function setPlugins(names, on) { names.forEach(n => PhoneLink.setPlugin(pp.phone.id, n, on)) }

            WSection {
                visible: !PhoneLink.installed || !PhoneLink.running
                WCard {
                    icon: "smartphone"
                    title: !PhoneLink.installed ? "Set up Phone Link" : "Phone Link isn't running"
                    description: !PhoneLink.installed ? "See your phone's notifications and texts, send files, ring it, share the clipboard and more. Installs KDE Connect and lets it through the firewall on your home network (asks for your password once)."
                        : Config.options.extras.phoneLinkStart === false
                            ? "Its background service is switched off at sign-in (Task Manager › Startup). Start runs it until you sign out."
                            : "KDE Connect is installed but its background service isn't running. Start runs it now."
                    WButton { accent: true; buttonText: PhoneLink.installed ? "Start" : "Set up"; onClicked: PhoneLink.installed ? PhoneLink.start() : PhoneLink.setup() }
                }
            }

            WSection {
                visible: PhoneLink.installed && pp.phone !== null
                WCard {
                    icon: pp.online ? "smartphone" : "phonelink_off"
                    title: pp.phone?.name ?? ""
                    description: !pp.online ? "Paired, not connected. Open KDE Connect on the phone; on Samsung, set its battery use to Unrestricted so it stays connected."
                        : ["Connected over Wi-Fi", pp.phone.battery !== null ? `battery ${pp.phone.battery}%${pp.phone.charging ? ", charging" : ""}` : "",
                           pp.phone.network ? pp.phone.network : ""].filter(s => s).join(" · ")
                    WButton { enabled: pp.online; accent: true; buttonText: "Ring"; onClicked: PhoneLink.ring(pp.phone.id) }
                    WButton { enabled: pp.online; buttonText: "Send a file"; onClicked: PhoneLink.sendFiles(pp.phone.id) }
                    WButton { enabled: pp.online; buttonText: "Browse files"; onClicked: PhoneLink.browse(pp.phone.id) }
                }
            }

            WSection {
                visible: PhoneLink.installed && pp.phone !== null
                title: "What your phone and PC share"
                WToggle {
                    icon: "notifications"
                    title: "Phone notifications on this PC"
                    description: "With reply for messages; dismissing on one dismisses on both. Needs notification access in the phone app"
                    checked: pp.pluginOn("kdeconnect_notifications")
                    onToggled: v => pp.setPlugins(["kdeconnect_notifications"], v)
                }
                WToggle {
                    icon: "sms"
                    title: "Text messages"
                    description: "Read and send texts from the PC (Messages in the phone card)"
                    checked: pp.pluginOn("kdeconnect_sms")
                    onToggled: v => pp.setPlugins(["kdeconnect_sms"], v)
                }
                WToggle {
                    icon: "call"
                    title: "Calls"
                    description: "Show incoming calls and pause music while you're on the phone"
                    checked: pp.pluginOn("kdeconnect_telephony")
                    onToggled: v => pp.setPlugins(["kdeconnect_telephony", "kdeconnect_pausemusic"], v)
                }
                WToggle {
                    icon: "content_paste"
                    title: "Shared clipboard"
                    description: "Copy on one, paste on the other (the Clipboard button sends it once either way)"
                    checked: pp.pluginOn("kdeconnect_clipboard")
                    onToggled: v => pp.setPlugins(["kdeconnect_clipboard"], v)
                }
                WToggle {
                    icon: "settings_remote"
                    title: "Use the phone as a remote"
                    description: "Music and video controls, touchpad and keyboard from the phone"
                    checked: pp.pluginOn("kdeconnect_mousepad")
                    onToggled: v => pp.setPlugins(["kdeconnect_mousepad", "kdeconnect_remotekeyboard", "kdeconnect_mpriscontrol"], v)
                }
                WToggle {
                    icon: "folder_open"
                    title: "Browse the phone's files"
                    description: "Open its storage in the file manager; recent photos in the phone card"
                    checked: pp.pluginOn("kdeconnect_sftp")
                    onToggled: v => pp.setPlugins(["kdeconnect_sftp"], v)
                }
                WToggle {
                    icon: "right_panel_open"
                    title: "Phone card in the sidebar"
                    checked: Config.options.sidebar.phoneLink
                    onToggled: v => Config.options.sidebar.phoneLink = v
                }
            }

            WSection {
                visible: PhoneLink.installed && PhoneLink.running
                title: pp.phone ? "Other phones" : "Pair your phone"
                WCard {
                    visible: !pp.phone
                    icon: "help"
                    title: "How to pair"
                    description: "1. Install KDE Connect on the phone (Galaxy Store, Google Play or F-Droid). 2. Connect it to the same Wi-Fi as this PC. 3. Press Pair below and accept on the phone; both show the same code."
                }
                Repeater {
                    model: PhoneLink.devices.filter(d => !d.paired)
                    WCard {
                        required property var modelData
                        icon: "smartphone"
                        title: modelData.name
                        description: modelData.pairRequested ? "Wants to pair with this PC" : (modelData.reachable ? "On your network · not paired" : "Not paired")
                        WButton { visible: !modelData.pairRequested; accent: true; buttonText: "Pair"; onClicked: PhoneLink.pair(modelData.id) }
                        WButton { visible: modelData.pairRequested; accent: true; buttonText: "Accept"; onClicked: PhoneLink.accept(modelData.id) }
                        WButton { visible: modelData.pairRequested; buttonText: "Decline"; onClicked: PhoneLink.reject(modelData.id) }
                    }
                }
                WCard {
                    icon: "refresh"
                    title: "Don't see your phone?"
                    description: "Open KDE Connect on the phone and pull down to refresh, then look again here"
                    WButton { buttonText: "Look again"; onClicked: PhoneLink.refresh() }
                }
            }

            WSection {
                visible: PhoneLink.installed
                title: "More"
                WCard {
                    visible: pp.phone !== null
                    icon: "link_off"
                    title: "Unpair " + (pp.phone?.name ?? "phone")
                    description: "The phone and PC forget each other; pair again any time"
                    WButton { buttonText: "Unpair"; onClicked: PhoneLink.unpair(pp.phone.id) }
                }
                WCard {
                    icon: "block"
                    title: "Turn off Phone Link"
                    description: "Stops KDE Connect and closes its firewall ports again (asks for your password)"
                    WButton {
                        buttonText: "Turn off"
                        onClicked: Quickshell.execDetached(["kitty", "--class", "phoenix-setup", "--title", "Phone Link", "--hold",
                            "bash", "-c", "phoenix phone-link remove; echo; echo 'You can close this window.'"])
                    }
                }
            }
        }
    }
}
