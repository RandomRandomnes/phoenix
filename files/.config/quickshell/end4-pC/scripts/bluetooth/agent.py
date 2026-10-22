#!/usr/bin/env python3
"""Bluetooth pairing agent for Phoenix on Hyprland (2026-10-22).

BlueZ asks an "agent" to confirm a pairing (and to show or ask for a passkey). KDE brings its own (bluedevil);
Hyprland had Blueman's until it was removed as a duplicate app on 2026-10-15, after which every new pairing failed
with "Authentication Failed" (devices connected for a second, then dropped). This is that agent, nothing more:
  - pairings you start (Settings › Bluetooth & devices, the sidebar) are confirmed; a passkey or PIN the device shows
    or needs appears as a notification
  - pairing requests that come from other devices are refused (the adapter isn't pairable from outside anyway)
  - services of a device are allowed once it's paired or trusted
Started by custom/scripts/autostart.sh in the Hyprland session; exits on its own when another agent is the default.
"""
import subprocess
import sys

try:
    import dbus
    import dbus.service
    import dbus.mainloop.glib
    from gi.repository import GLib
except ImportError:
    sys.exit(0)

AGENT_PATH = "/org/phoenix/bluetooth/agent"
CAPABILITY = "KeyboardDisplay"   # numeric comparison and passkeys work; headphones get "just works"
LEGACY_PIN = "0000"              # older headsets that ask for a PIN almost all use 0000


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


def notify(title, body):
    subprocess.Popen(["notify-send", "-a", "Bluetooth", "-i", "bluetooth", title, body],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


class Agent(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, AGENT_PATH)
        self.bus = bus

    def device(self, path):
        try:
            props = dbus.Interface(self.bus.get_object("org.bluez", path), "org.freedesktop.DBus.Properties")
            return props.GetAll("org.bluez.Device1")
        except dbus.DBusException:
            return {}

    def name(self, path):
        d = self.device(path)
        return str(d.get("Alias") or d.get("Name") or d.get("Address") or "A device")

    def started_here(self, path):
        """a pairing this PC started is in progress (Pairing is set on our side), or the device is already trusted"""
        d = self.device(path)
        return bool(d.get("Trusted")) or bool(d.get("Paired"))

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        if not self.started_here(device):
            raise Rejected("not paired")

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        if not self.started_here(device):
            raise Rejected("not started here")
        notify(f"Pairing with {self.name(device)}", f"Using PIN {LEGACY_PIN}")
        return LEGACY_PIN

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        if not self.started_here(device):
            raise Rejected("not started here")
        return dbus.UInt32(int(LEGACY_PIN))

    @dbus.service.method("org.bluez.Agent1", in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        if entered == 0:
            notify(f"Pairing with {self.name(device)}", f"Type {int(passkey):06d} on the device, then press Enter")

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        notify(f"Pairing with {self.name(device)}", f"Type {pincode} on the device, then press Enter")

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        if not self.started_here(device):
            raise Rejected("not started here")
        notify(f"Pairing with {self.name(device)}", f"Code {int(passkey):06d}; accept it on the device if it asks")

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        # "just works" pairing that a device started: only for devices this PC already trusts
        if not self.started_here(device):
            raise Rejected("not started here")

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        pass


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    Agent(bus)
    loop = GLib.MainLoop()

    def register():
        try:
            mgr = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
            mgr.RegisterAgent(AGENT_PATH, CAPABILITY)
            mgr.RequestDefaultAgent(AGENT_PATH)
        except dbus.DBusException as e:
            if "AlreadyExists" not in str(e):
                print("agent:", e, file=sys.stderr)
        return False

    # bluetoothd may start after us, or restart: register again whenever it (re)appears
    bus.watch_name_owner("org.bluez", lambda owner: owner and GLib.timeout_add(500, register))
    loop.run()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
