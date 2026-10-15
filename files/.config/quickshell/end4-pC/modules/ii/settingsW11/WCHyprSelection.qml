import qs.services

// Phoenix (2026-10-15): illogical-impulse's HyprOptionSelection in the Windows-style look.
WCSelection {
    id: root
    required property string optionKey
    property var fallback: ""

    currentValue: HyprlandOptions.get(root.optionKey, root.fallback)
    onSelected: newValue => HyprlandOptions.apply(root.optionKey, newValue)
}
