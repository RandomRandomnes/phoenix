hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )





-- Super+I: the stock bind runs `qs -p .../end4-pC/settings.qml`, which this fork doesn't have (it uses the
-- Windows-style settings window, settingsW11), so it did nothing. Open that window over IPC instead.
hl.unbind("SUPER + I")
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs -c end4-pC ipc call settings toggle"), { description = "App: Settings app" })

-- App shortcuts open the apps chosen in Settings › Apps (2026-10-15), through ~/.local/bin/phoenix-open like every other
-- button and menu entry. The stock binds picked "the first installed" app from fixed lists (Chrome before Firefox,
-- kate/gnome-text-editor for text), so Super+W, Super+X, Ctrl+Shift+Esc… could open a different app than the taskbar,
-- the power menu or Settings.
for _, key in ipairs({ "SUPER + Return", "SUPER + T", "CTRL + ALT + T", "SUPER + E", "SUPER + W", "SUPER + X",
                       "CTRL + SUPER + V", "CTRL + SHIFT + Escape" }) do
    hl.unbind(key)
end
hl.bind("SUPER + Return", hl.dsp.exec_cmd("phoenix-open terminal"), { description = "App: Terminal" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("phoenix-open terminal"))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("phoenix-open terminal"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("phoenix-open files"), { description = "App: File manager" })
hl.bind("SUPER + W", hl.dsp.exec_cmd("phoenix-open browser"), { description = "App: Browser" })
hl.bind("SUPER + X", hl.dsp.exec_cmd("phoenix-open editor"), { description = "App: Text editor" })
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd("phoenix-open volume"), { description = "App: Volume mixer" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("phoenix-open taskmanager"), { description = "App: Task manager" })

-- Shift+Super+Alt+/: the stock bind opens the upstream welcome window (welcome.qml); this desktop uses the setup
-- assistant instead (the same as Settings › Extras › Run the first-time setup again).
hl.unbind("SHIFT + SUPER + ALT + Slash")
hl.bind("SHIFT + SUPER + ALT + Slash", hl.dsp.exec_cmd("mkdir -p ~/.local/state/setup-wizard && touch ~/.local/state/setup-wizard/pending && qs -p ~/.config/quickshell/end4-pC/setup-wizard.qml"), { description = "Shell: Setup assistant" })

-- Screen recording and screenshots: not on the lock screen (2026-10-15). The stock binds are marked `locked`, so they
-- also worked while locked: someone at the PC could start a recording (with sound) that kept running after unlocking.
-- Same keys and actions, just without `locked`. Volume, brightness and media keys still work on the lock screen.
do
    local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
    local qsIsAlive = "qs -c $qsConfig ipc call TEST_ALIVE"
    local grimhyprctl = "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\""
    for _, key in ipairs({ "SUPER + SHIFT + R", "SUPER + ALT + R", "CTRL + ALT + R", "SUPER + SHIFT + ALT + R", "Print", "CTRL + Print" }) do
        hl.unbind(key)
    end
    hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { description = "Utilities: Record region (no sound)" })
    hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/videos/record.sh"))
    hl.bind("SUPER + ALT + R", hl.dsp.global("quickshell:regionRecord"))
    hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/videos/record.sh"))
    hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"))
    hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen --sound"),
        { description = "Utilities: Record screen (with sound)" })
    hl.bind("Print", hl.dsp.exec_cmd(grimhyprctl .. " - | wl-copy"), { description = "Utilities: Screenshot >> clipboard" })
    hl.bind("CTRL + Print", hl.dsp.exec_cmd(
        "mkdir -p $(xdg-user-dir PICTURES)/Screenshots && " ..
        grimhyprctl .. " $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"
    ), { non_consuming = true, description = "Utilities: Screenshot >> clipboard & file" })
    hl.bind("CTRL + Print", hl.dsp.exec_cmd(grimhyprctl .. " - | wl-copy"), { non_consuming = true })
end
