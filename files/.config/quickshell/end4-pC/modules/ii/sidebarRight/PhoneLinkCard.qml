import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

// Phone Link card in the right sidebar (Phoenix P6, 2026-10-15). Compact: the phone's battery and signal with Ring,
// Send a file, Browse and Clipboard. The expand button (like the Wallpaper Engine card) adds the phone's
// notifications (reply / dismiss), its newest photos and what it's playing. Data: services/PhoneLink.qml.
Rectangle {
    id: root
    readonly property var phone: PhoneLink.phone
    readonly property bool online: phone?.reachable ?? false
    property bool expanded: false
    property string replyTo: ""        // notification id with the reply field open

    implicitHeight: content.implicitHeight + 20
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    // fresh photos each time the card opens (new pictures, or file access allowed since the last try)
    onExpandedChanged: if (expanded && online) PhoneLink.loadPhotos(phone.id)

    component RoundButton: RippleButton {
        property string symbol
        property string tip
        implicitWidth: 32
        implicitHeight: 32
        buttonRadius: Appearance.rounding.full
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: parent.symbol
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer1
        }
        StyledToolTip { text: parent.tip }
    }
    component ActionTile: RippleButton {
        property string symbol
        property string label
        Layout.fillWidth: true
        implicitHeight: 58
        buttonRadius: Appearance.rounding.normal
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover
        enabled: root.online
        opacity: enabled ? 1 : 0.5
        contentItem: ColumnLayout {
            spacing: 2
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.symbol
                iconSize: 20
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: parent.parent.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer2
            }
        }
    }

    ColumnLayout {
        id: content
        anchors { fill: parent; margins: 10 }
        spacing: 8

        RowLayout {   // header
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: Appearance.rounding.small
                color: root.online ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer2
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.online ? "smartphone" : "phonelink_off"
                    iconSize: 20
                    color: root.online ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.phone?.name ?? "Phone"
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    text: !root.online ? "Not connected · open KDE Connect on the phone"
                        : [root.phone.battery !== null ? `${root.phone.battery}%${root.phone.charging ? ", charging" : ""}` : "",
                           root.phone.network ? `${root.phone.network}${root.phone.signal >= 0 ? " · " + "▂▄▆█".slice(0, root.phone.signal) : ""}` : ""]
                          .filter(s => s).join(" · ")
                }
            }
            // battery bar
            Rectangle {
                visible: root.online && root.phone?.battery !== null && root.phone?.battery !== undefined
                Layout.preferredWidth: 44
                Layout.preferredHeight: 6
                radius: 3
                color: Appearance.colors.colLayer2
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, (root.phone?.battery ?? 0) / 100))
                    height: parent.height
                    radius: 3
                    color: (root.phone?.battery ?? 100) <= 15 && !root.phone?.charging ? Appearance.colors.colError : Appearance.colors.colPrimary
                }
            }
            RoundButton {
                symbol: root.expanded ? "expand_less" : "expand_more"
                tip: root.expanded ? "Less" : "More"
                onClicked: root.expanded = !root.expanded
            }
        }

        RowLayout {   // A: the four actions
            Layout.fillWidth: true
            spacing: 6
            ActionTile { symbol: "notifications_active"; label: "Ring"; onClicked: PhoneLink.ring(root.phone.id) }
            ActionTile { symbol: "upload_file"; label: "Send file"; onClicked: { GlobalStates.sidebarRightOpen = false; PhoneLink.sendFiles(root.phone.id) } }
            ActionTile { symbol: "folder_open"; label: "Browse"; onClicked: { GlobalStates.sidebarRightOpen = false; PhoneLink.browse(root.phone.id) } }
            ActionTile { symbol: "content_paste_go"; label: "Clipboard"; onClicked: PhoneLink.sendClipboard(root.phone.id) }
        }

        // ── B: expanded ──────────────────────────────────────────────────────────────────────────────────────────
        ColumnLayout {
            visible: root.expanded
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                StyledText {
                    Layout.fillWidth: true
                    text: "From your phone"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                }
                RippleButton {
                    implicitHeight: 28
                    implicitWidth: msgText.implicitWidth + 24
                    buttonRadius: 14
                    enabled: root.online
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: { GlobalStates.sidebarRightOpen = false; PhoneLink.messages(root.phone.id) }
                    contentItem: Item {
                        StyledText {
                            id: msgText
                            anchors.centerIn: parent
                            text: "Messages"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer2
                        }
                    }
                }
            }
            StyledText {
                visible: (root.phone?.notifications ?? []).length === 0
                Layout.fillWidth: true
                Layout.leftMargin: 2
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: !root.online ? "Phone not connected"
                    : (root.phone?.plugins?.kdeconnect_notifications === false ? "Phone notifications are off in Settings"
                    : "No notifications. None ever? Allow notification access in KDE Connect")
            }
            Repeater {
                model: (root.phone?.notifications ?? []).slice(-3).reverse()
                Rectangle {
                    id: note
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: noteCol.implicitHeight + 16
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2
                    ColumnLayout {
                        id: noteCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; leftMargin: 12 }
                        spacing: 2
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            StyledText {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: note.modelData.app + (note.modelData.title ? " · " + note.modelData.title : "")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer2
                            }
                            RoundButton {
                                visible: note.modelData.reply !== ""
                                implicitWidth: 26; implicitHeight: 26
                                symbol: "reply"; tip: "Reply"
                                onClicked: root.replyTo = root.replyTo === note.modelData.id ? "" : note.modelData.id
                            }
                            RoundButton {
                                visible: note.modelData.dismissable
                                implicitWidth: 26; implicitHeight: 26
                                symbol: "close"; tip: "Dismiss on the phone too"
                                onClicked: PhoneLink.dismiss(root.phone.id, note.modelData.id)
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: note.modelData.text
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        RowLayout {
                            visible: root.replyTo === note.modelData.id
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 6
                            MaterialTextField {
                                id: replyField
                                Layout.fillWidth: true
                                placeholderText: "Reply"
                                onVisibleChanged: if (visible) forceActiveFocus()
                                onAccepted: sendReply.clicked()
                            }
                            RoundButton {
                                id: sendReply
                                symbol: "send"; tip: "Send"
                                onClicked: {
                                    if (replyField.text.trim() === "") return
                                    PhoneLink.reply(root.phone.id, note.modelData.reply, replyField.text)
                                    replyField.text = ""
                                    root.replyTo = ""
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.topMargin: 4
                text: "Recent photos"
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: Appearance.colors.colSubtext
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 6
                rowSpacing: 6
                Repeater {
                    model: PhoneLink.photosFor === root.phone?.id ? PhoneLink.photos : []
                    RippleButton {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 60
                        implicitHeight: 64
                        buttonRadius: Appearance.rounding.small
                        padding: 0
                        onClicked: { GlobalStates.sidebarRightOpen = false; Quickshell.execDetached(["xdg-open", modelData]) }
                        contentItem: Item {
                            Image {
                                anchors.fill: parent
                                source: `file://${modelData}`
                                sourceSize.width: 160
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                layer.enabled: true
                            }
                        }
                    }
                }
            }
            StyledText {
                visible: PhoneLink.photosLoading || PhoneLink.photosFor !== root.phone?.id || PhoneLink.photos.length === 0
                Layout.fillWidth: true
                Layout.leftMargin: 2
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                text: !root.online ? "Phone not connected"
                    : PhoneLink.photosLoading ? "Getting photos…"
                    : "No photos. Allow storage access in KDE Connect"
            }

            Rectangle {   // what the phone plays
                visible: root.online && (root.phone?.media?.title ?? "") !== ""   // not for an idle player (e.g. "Phone calls")
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 56
                radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2
                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 6 }
                    spacing: 10
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 8
                        color: Appearance.colors.colLayer3
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: root.phone?.media?.art ?? ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.phone?.media?.title || root.phone?.media?.player || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: (root.phone?.media?.artist ? root.phone.media.artist + " · " : "") + "on your phone"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                    RoundButton { symbol: "skip_previous"; tip: "Previous"; onClicked: PhoneLink.media(root.phone.id, "Previous") }
                    RoundButton {
                        symbol: root.phone?.media?.playing ? "pause" : "play_arrow"
                        tip: root.phone?.media?.playing ? "Pause" : "Play"
                        onClicked: PhoneLink.media(root.phone.id, "PlayPause")
                    }
                    RoundButton { symbol: "skip_next"; tip: "Next"; onClicked: PhoneLink.media(root.phone.id, "Next") }
                }
            }
        }
    }
}
