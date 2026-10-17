-- features-start
-- Custom-feature switches (2026-10-03). ~/.local/bin/setup-features writes features.lua from the shell's
-- config.json "extras" (Settings › Extras or a setup profile). A missing file or key means the feature is on.
do
    local ok, f = pcall(dofile, HOME .. "/.config/hypr/custom/features.lua")
    FEATURES = (ok and type(f) == "table") and f or {}
end
function feature(name) return FEATURES[name] ~= false end
-- features-end
-- Phoenix runs its own Quickshell config. Set here (custom/ loads after illogical-impulse's defaults), so swapping
-- the custom folder (phoenix activate / deactivate) also switches the shell.
hl.env("qsConfig", "end4-pC")
-- user-keybinds-start
-- Your own shortcut changes (Settings › Bluetooth & devices › Keyboard › Shortcuts, 2026-10-16), kept in
-- custom/user-keybinds.lua (written by the shell's scripts/hyprland/shortcuts.py; personal, never shipped or replaced):
--   moved = { ["SUPER + E"] = "SUPER + B" }   a shortcut on other keys (the same action)
--   off   = { ["SUPER + Q"] = "Close window" } a shortcut switched off
--   added = { { keys = "SUPER + M", command = "spotify", description = "Spotify" } }   your own commands
-- Moving works by translating the keys of hl.bind / hl.unbind while illogical-impulse's and Phoenix's shortcut files
-- load (custom/env.lua loads before them), so every action stays exactly as those files define it.
do
    local ok, u = pcall(dofile, HOME .. "/.config/hypr/custom/user-keybinds.lua")
    USER_KEYBINDS = (ok and type(u) == "table") and u or {}
    local MODS = { SUPER = true, CTRL = true, ALT = true, SHIFT = true }
    function keynorm(s)
        if type(s) ~= "string" then return s end
        local mods, key = {}, nil
        for part in s:gmatch("[^+]+") do
            local p = (part:gsub("^%s+", "")):gsub("%s+$", "")
            local up = p:upper()
            if up == "CONTROL" then up = "CTRL" end
            if MODS[up] then mods[#mods + 1] = up else key = up end
        end
        table.sort(mods)
        if key then mods[#mods + 1] = key end
        return table.concat(mods, "+")
    end
    local moved, off = {}, {}
    for k, v in pairs(USER_KEYBINDS.moved or {}) do if type(v) == "string" then moved[keynorm(k)] = v end end
    for k, v in pairs(USER_KEYBINDS.off or {}) do if v then off[keynorm(k)] = true end end
    HL_BIND = HL_BIND or hl.bind          -- the real functions, once (in case the config state is reused)
    HL_UNBIND = HL_UNBIND or hl.unbind
    if next(moved) or next(off) then
        local function translate(keys)
            local ok2, n = pcall(keynorm, keys)
            if not ok2 then return keys, false end
            if off[n] then return keys, true end
            return moved[n] or keys, false
        end
        hl.bind = function(keys, ...)
            local k, skip = translate(keys)
            if skip then return nil end
            return HL_BIND(k, ...)
        end
        hl.unbind = function(keys, ...)
            local k, skip = translate(keys)
            if skip then return nil end
            return HL_UNBIND(k, ...)
        end
    else
        hl.bind, hl.unbind = HL_BIND, HL_UNBIND
    end
end
-- user-keybinds-end
