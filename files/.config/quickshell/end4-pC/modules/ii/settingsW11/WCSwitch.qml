import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Phoenix (2026-10-15): illogical-impulse's ConfigSwitch in the Windows-style look. API: text, buttonIcon, checked,
// toggled(checked). A click reports the new state through toggled() and leaves `checked` to the page's binding
// (2026-10-16: it used to set `checked` itself, which cut the binding, so the switch showed a stale state when the
// setting changed elsewhere, e.g. Game Mode or the sidebar). Only an unbound switch sets itself.
WCard {
    id: root
    property string text: ""
    property string buttonIcon: ""
    property bool checked: false
    signal toggled(bool checked)
    function flip() {
        const v = !root.checked;
        root.toggled(v);
        if (root.checked !== v) root.checked = v;   // nothing outside changed it: a local switch
    }

    icon: root.buttonIcon
    title: root.text
    clickable: true
    opacity: enabled ? 1 : 0.5
    onClicked: root.flip()

    StyledSwitch {
        checked: root.checked
        onClicked: root.flip()
        onCheckedChanged: if (checked !== root.checked) checked = Qt.binding(() => root.checked)
    }
}
