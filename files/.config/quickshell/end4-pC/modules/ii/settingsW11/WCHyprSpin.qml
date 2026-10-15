import qs.services

// Phoenix (2026-10-15): illogical-impulse's HyprOptionSpinBox in the Windows-style look.
WCSpin {
    id: root
    required property string optionKey
    property real factor: 1
    property real fallback: 0

    value: Math.round(Number(HyprlandOptions.get(root.optionKey, root.fallback)) * root.factor)
    onValueModified: {
        const next = root.value / root.factor
        if (Math.abs(next - Number(HyprlandOptions.get(root.optionKey, root.fallback))) < 1e-6) return
        HyprlandOptions.apply(root.optionKey, next)
    }
}
