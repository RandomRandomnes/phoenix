import qs.services

// Phoenix (2026-10-15): illogical-impulse's HyprOptionSwitch in the Windows-style look (HyprlandOptions get/apply).
WCSwitch {
    id: root
    required property string optionKey
    property bool fallback: false

    checked: Boolean(HyprlandOptions.get(root.optionKey, root.fallback))
    onCheckedChanged: {
        if (checked === Boolean(HyprlandOptions.get(root.optionKey, root.fallback))) return
        HyprlandOptions.apply(root.optionKey, checked)
    }
}
