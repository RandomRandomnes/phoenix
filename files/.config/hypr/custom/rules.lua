-- The shell's Settings window draws its own header (back, title, close) and is dragged by it: no hyprbars title bar.
-- Only while the plugin is loaded (windowsStyle on): without it the field is unknown and Hyprland reports an error (F11).
if feature("windowsStyle") and hl.plugin and hl.plugin.hyprbars then
    hl.window_rule({
        name = "settings-no-titlebar",
        match = { class = "^(org.quickshell)$", title = "^(Settings)$" },
        ["hyprbars:no_bar"] = true,
    })
end

-- First-time setup wizard (end4-pC setup-wizard.qml): always a centered floating window, also with tiling.
hl.window_rule({
    name = "setup-wizard",
    match = { title = "^(Set up your PC|Quick Start)$" },
    float = true,
    center = true,
})

-- Terminals the setup assistant opens (app installs, drivers, updates, boot menu; kitty --class phoenix-setup):
-- a centered window in front of the assistant. Without this, a maximized window on the workspace made the new
-- terminal take over as maximized (illogical-impulse's on_focus_under_fullscreen = 2), and Phoenix's
-- float-over-maximized fix then lifted the assistant above it.
hl.window_rule({
    name = "setup-terminal",
    match = { class = "^(phoenix-setup)$" },
    float = true,
    center = true,
    size = {"(monitor_w*0.50)", "(monitor_h*0.55)"},
    fullscreen_state = "0 0",
})

-- All rules here belong to the windowsStyle feature (features-start in env.lua).
if feature("windowsStyle") then

hl.window_rule({
    name = "float-all-windows",
    match = { class = ".*" },
    float = true,
})

-- Firefox asks for a tiny 500x120 window when floating; give main browser windows a real size.
-- Matched on initial title so Picture-in-Picture and dialogs keep their own sizes.
hl.window_rule({
    name = "firefox-main-size",
    match = { initial_class = "^(firefox)$", initial_title = "^(Mozilla Firefox)$" },
    size = {"(monitor_w*0.70)", "(monitor_h*0.80)"},
    center = true,
})

-- Steam's main window opens at 1280x720 (logical px), centered, instead of the size it remembers (~full screen).
-- Matched on initial title so the friends list, game windows and dialogs keep their own sizes.
hl.window_rule({
    name = "steam-main-size",
    match = { initial_class = "^(steam)$", initial_title = "^(Steam)$" },
    size = {"1280", "720"},
    center = true,
})

end

-- Your own window rules (Settings › Apps › Window rules, ~/.local/bin/window-rules). Loaded last, so they win.
-- A broken file never stops the rest of the configuration from loading.
do
    local f = HOME .. "/.config/hypr/custom/user-rules.lua"
    if is_file_exists(f) then
        local ok, err = pcall(dofile, f)
        if not ok then print("user-rules.lua: " .. tostring(err)) end
    end
end

-- Wine's own tray window (2026-10-17): when no tray bridge is running (xembedsniproxy, started by autostart.sh), Wine
-- shows its tray as a small window that landed in the top left. Keep it out of sight in a hidden workspace; its icons
-- are then simply not shown (with the bridge running there is no such window at all).
hl.window_rule({
    name = "wine-system-tray",
    match = { class = "^(explorer.exe)$", title = "^(Wine System Tray)$" },
    float = true,
    no_focus = true,
    workspace = "special:wine-tray silent",
})

-- The tray bridge's own helper window (xembedsniproxy, 32x32): it only owns the tray, nothing to show (2026-10-17).
hl.window_rule({
    name = "xembedsniproxy-window",
    match = { class = "^(xembedsniproxy)$" },
    float = true,
    no_focus = true,
    no_anim = true,
    no_shadow = true,
    no_blur = true,
    opacity = "0.0 override 0.0 override",
    workspace = "special:wine-tray silent",
})
