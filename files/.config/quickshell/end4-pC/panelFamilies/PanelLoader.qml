import QtQuick
import Quickshell

import qs
import qs.modules.common

LazyLoader {
    property bool extraCondition: true
    // Phoenix (2026-10-15): with lock-screen sign-in, panels wait until the lock is up (GlobalStates.startupGateOpen);
    // the lock itself sets gated: false
    property bool gated: true
    active: Config.ready && extraCondition && (!gated || GlobalStates.startupGateOpen)
}
