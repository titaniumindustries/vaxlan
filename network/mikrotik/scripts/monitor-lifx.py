#!/usr/bin/env python3
"""
LIFX Bulb Network Connectivity Monitor

Multi-layer monitoring to diagnose intermittent LIFX WiFi disconnections:
  Layer 1 - ICMP ping (every 30s): basic IP reachability
  Layer 2 - LIFX LAN protocol (every 60s): firmware/app responsiveness
  Layer 3 - CAPsMAN WiFi (every 60s): WiFi association, signal, rates

Usage:
  python3 monitor-lifx.py

Logs to: mikrotik/scripts/logs/lifx-YYYY-MM-DD.csv

Requires: Python 3.8+, SSH key auth via 'vaxlan-router' host alias (~/.ssh/config).
No pip dependencies.

Updated: 2026-04-14 — Removed sshpass/ROUTER_PASS dependency, migrated to SSH key
  auth via 'vaxlan-router' host alias. Requires ~/.ssh/config (run setup-ssh.sh on
  a new Mac). UNTESTED after update.
"""

import csv
import io
import os
import re
import socket
import struct
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# ─── Configuration ───────────────────────────────────────────────────────────

# SSH host alias from ~/.ssh/config (resolves to admin@10.0.20.1 with key auth)
SSH_HOST = "vaxlan-router"

# Known LIFX MAC addresses (from DHCP leases)
# D0:73:D5 = LIFX OUI
KNOWN_LIFX_MACS = [
    "D0:73:D5:12:74:F0",
    "D0:73:D5:12:55:5A",
    "D0:73:D5:12:1D:E1",
    "D0:73:D5:12:9A:2A",
    "D0:73:D5:12:65:B8",
    "D0:73:D5:12:B0:AA",
    "D0:73:D5:12:78:30",
    "D0:73:D5:12:68:F4",
    "D0:73:D5:12:A0:D3",
]

LIFX_PORT = 56700
PING_INTERVAL = 30       # seconds between ping sweeps
PROTOCOL_INTERVAL = 60   # seconds between LIFX protocol checks
CAPSMAN_INTERVAL = 60    # seconds between CAPsMAN SSH checks
DISCOVERY_INTERVAL = 300  # seconds between full rediscovery

# ─── LIFX LAN Protocol ──────────────────────────────────────────────────────

LIFX_GET_SERVICE = 2
LIFX_STATE_SERVICE = 3
LIFX_GET_LABEL = 23
LIFX_STATE_LABEL = 25
LIFX_GET_POWER = 20
LIFX_STATE_POWER = 22
LIFX_GET_HOST_INFO = 12
LIFX_STATE_HOST_INFO = 13
LIFX_LIGHT_GET = 101
LIFX_LIGHT_STATE = 107


def build_lifx_message(
    msg_type: int,
    tagged: bool = False,
    target_mac: Optional[str] = None,
    source: int = 0xABCD1234,
    sequence: int = 0,
    res_required: bool = True,
    payload: bytes = b"",
) -> bytes:
    """Build a LIFX LAN protocol message."""
    size = 36 + len(payload)

    # Frame header: size(16), protocol+flags(16), source(32)
    protocol_field = 1024  # protocol number
    protocol_field |= (1 << 12)  # addressable = 1
    if tagged:
        protocol_field |= (1 << 13)  # tagged = 1

    # Frame address: target(64), reserved(48), flags(8), sequence(8)
    if target_mac:
        mac_bytes = bytes.fromhex(target_mac.replace(":", ""))
        target = mac_bytes + b"\x00\x00"
    else:
        target = b"\x00" * 8

    flags = 0
    if res_required:
        flags |= 0x01  # res_required

    msg = struct.pack("<HHI", size, protocol_field, source)
    msg += target
    msg += b"\x00" * 6  # reserved
    msg += struct.pack("BB", flags, sequence)
    # Protocol header: reserved(64), type(16), reserved(16)
    msg += b"\x00" * 8
    msg += struct.pack("<HH", msg_type, 0)
    msg += payload

    return msg


def parse_lifx_header(data: bytes) -> Optional[dict]:
    """Parse LIFX message header, return dict with key fields."""
    if len(data) < 36:
        return None
    size = struct.unpack_from("<H", data, 0)[0]
    source = struct.unpack_from("<I", data, 4)[0]
    target = data[8:14]
    target_mac = ":".join(f"{b:02X}" for b in target)
    msg_type = struct.unpack_from("<H", data, 32)[0]
    payload = data[36:size] if size <= len(data) else data[36:]
    return {
        "size": size,
        "source": source,
        "target_mac": target_mac,
        "type": msg_type,
        "payload": payload,
    }


def lifx_query(ip: str, msg_type: int, timeout: float = 2.0) -> Optional[dict]:
    """Send a LIFX query to a specific bulb IP and return the response."""
    msg = build_lifx_message(msg_type, tagged=False, target_mac=None)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(timeout)
    try:
        sock.sendto(msg, (ip, LIFX_PORT))
        data, addr = sock.recvfrom(1024)
        return parse_lifx_header(data)
    except (socket.timeout, OSError):
        return None
    finally:
        sock.close()


def lifx_get_label(ip: str, timeout: float = 2.0) -> Optional[str]:
    """Get the label (name) of a LIFX bulb via LAN protocol."""
    resp = lifx_query(ip, LIFX_GET_LABEL, timeout)
    if resp and resp["type"] == LIFX_STATE_LABEL and resp["payload"]:
        label = resp["payload"][:32].split(b"\x00")[0].decode("utf-8", errors="replace")
        return label.strip() if label.strip() else None
    return None


def lifx_check_alive(ip: str, timeout: float = 2.0) -> bool:
    """Check if a LIFX bulb responds to GetService (protocol-level health)."""
    resp = lifx_query(ip, LIFX_GET_SERVICE, timeout)
    return resp is not None and resp["type"] == LIFX_STATE_SERVICE


def lifx_get_light_state(ip: str, timeout: float = 2.0) -> Optional[dict]:
    """Get full light state including power, label, and HSBK."""
    resp = lifx_query(ip, LIFX_LIGHT_GET, timeout)
    if resp and resp["type"] == LIFX_LIGHT_STATE and len(resp["payload"]) >= 52:
        p = resp["payload"]
        hue, sat, brightness, kelvin = struct.unpack_from("<HHHH", p, 0)
        power = struct.unpack_from("<H", p, 10)[0]
        label = p[12:44].split(b"\x00")[0].decode("utf-8", errors="replace").strip()
        return {
            "hue": hue,
            "saturation": sat,
            "brightness": brightness,
            "kelvin": kelvin,
            "power": "on" if power > 0 else "off",
            "label": label,
        }
    return None


# ─── Router SSH Commands ─────────────────────────────────────────────────────


def ssh_command(cmd: str, timeout: int = 10) -> Optional[str]:
    """Execute a RouterOS command via SSH using key auth (vaxlan-router host alias)."""
    try:
        result = subprocess.run(
            [
                "ssh",
                "-o", "ConnectTimeout=5",
                "-o", "BatchMode=yes",
                SSH_HOST,
                cmd,
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.stdout if result.returncode == 0 else None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None


def get_dhcp_leases() -> dict[str, dict]:
    """Query router DHCP leases for LIFX devices. Returns {mac: {ip, comment, status}}."""
    output = ssh_command(
        '/ip dhcp-server lease print detail where mac-address~"D0:73:D5"'
    )
    if not output:
        return {}

    leases = {}
    current = {}
    for line in output.split("\n"):
        line = line.strip()
        # New entry starts with a number
        if re.match(r"^\d+\s", line) or re.match(r"^\d+\s*;;;", line):
            if current.get("mac"):
                leases[current["mac"].upper()] = current
            current = {}

        # Parse comment (;;; lines)
        comment_match = re.search(r";;;(.+)", line)
        if comment_match:
            current["comment"] = comment_match.group(1).strip()

        # Parse fields
        mac_match = re.search(r"mac-address=([0-9A-Fa-f:]+)", line)
        if mac_match:
            current["mac"] = mac_match.group(1).upper()

        ip_match = re.search(r"address=(\d+\.\d+\.\d+\.\d+)", line)
        if ip_match:
            current["ip"] = ip_match.group(1)

        status_match = re.search(r"status=(\w+)", line)
        if status_match:
            current["status"] = status_match.group(1)

        host_match = re.search(r"host-name=(\S+)", line)
        if host_match:
            current["hostname"] = host_match.group(1)

    # Don't forget the last entry
    if current.get("mac"):
        leases[current["mac"].upper()] = current

    return leases


def _split_routeros_entries(output: str) -> list[str]:
    """Split multi-line RouterOS output into per-entry strings."""
    entries = []
    current_lines = []
    for line in output.split("\n"):
        # New entry starts with a number at the beginning of the line
        if re.match(r"^\s*\d+\s", line) and current_lines:
            entries.append(" ".join(current_lines))
            current_lines = []
        if line.strip():
            current_lines.append(line.strip())
    if current_lines:
        entries.append(" ".join(current_lines))
    return entries


def get_capsman_registration() -> dict[str, dict]:
    """Query CAPsMAN registration table for LIFX devices. Returns {mac: {signal, uptime, iface, ssid}}."""
    # Get stats in one call (includes signal, rates, uptime, interface, ssid)
    output = ssh_command(
        '/caps-man registration-table print stats where mac-address~"D0:73:D5"'
    )
    if not output:
        return {}

    registrations = {}
    for entry_text in _split_routeros_entries(output):
        mac_match = re.search(r"mac-address=([0-9A-Fa-f:]+)", entry_text)
        if not mac_match:
            continue

        mac = mac_match.group(1).upper()
        entry = {"mac": mac}

        iface_match = re.search(r"interface=(\S+)", entry_text)
        if iface_match:
            entry["interface"] = iface_match.group(1)

        ssid_match = re.search(r'ssid="([^"]*)"', entry_text)
        if ssid_match:
            entry["ssid"] = ssid_match.group(1)

        sig_match = re.search(r"rx-signal=(-?\d+)", entry_text)
        if sig_match:
            entry["signal_dbm"] = int(sig_match.group(1))

        up_match = re.search(r"uptime=(\S+)", entry_text)
        if up_match:
            entry["uptime"] = up_match.group(1)

        tx_match = re.search(r'tx-rate="([^"]*)"', entry_text)
        if tx_match:
            entry["tx_rate"] = tx_match.group(1)

        rx_match = re.search(r'rx-rate="([^"]*)"', entry_text)
        if rx_match:
            entry["rx_rate"] = rx_match.group(1)

        # Extract packet counts for traffic analysis
        packets_match = re.search(r"packets=(\S+)", entry_text)
        if packets_match:
            entry["packets"] = packets_match.group(1)

        bytes_match = re.search(r"bytes=(\S+)", entry_text)
        if bytes_match:
            entry["bytes"] = bytes_match.group(1)

        registrations[mac] = entry

    return registrations


# ─── Ping ────────────────────────────────────────────────────────────────────


def ping_host(ip: str, timeout: int = 2) -> tuple[bool, Optional[float]]:
    """Ping a host. Returns (success, latency_ms)."""
    try:
        result = subprocess.run(
            ["ping", "-c", "1", "-W", str(timeout * 1000), ip],
            capture_output=True,
            text=True,
            timeout=timeout + 2,
        )
        if result.returncode == 0:
            # Parse latency from ping output
            match = re.search(r"time=(\d+\.?\d*)\s*ms", result.stdout)
            latency = float(match.group(1)) if match else None
            return True, latency
        return False, None
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False, None


# ─── Bulb State ──────────────────────────────────────────────────────────────


@dataclass
class BulbState:
    mac: str
    ip: Optional[str] = None
    name: Optional[str] = None
    dhcp_status: Optional[str] = None
    # Monitoring results
    ping_ok: bool = False
    ping_ms: Optional[float] = None
    lifx_ok: bool = False
    lifx_power: Optional[str] = None
    capsman_registered: bool = False
    signal_dbm: Optional[int] = None
    tx_rate: Optional[str] = None
    rx_rate: Optional[str] = None
    uptime: Optional[str] = None
    ap_interface: Optional[str] = None
    ssid: Optional[str] = None
    # State tracking
    online: bool = False
    last_online: Optional[str] = None
    last_signal: Optional[int] = None
    last_ap: Optional[str] = None
    offline_since: Optional[str] = None
    state_changes: list = field(default_factory=list)


# ─── CSV Logging ─────────────────────────────────────────────────────────────

CSV_FIELDS = [
    "timestamp", "mac", "name", "ip", "dhcp_status",
    "ping_ok", "ping_ms", "lifx_ok", "lifx_power",
    "capsman_registered", "signal_dbm", "tx_rate", "rx_rate",
    "uptime", "ap_interface", "ssid",
]


class CSVLogger:
    def __init__(self, log_dir: Path):
        self.log_dir = log_dir
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self._current_date = None
        self._writer = None
        self._file = None

    def _rotate(self):
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        if today != self._current_date:
            if self._file:
                self._file.close()
            filepath = self.log_dir / f"lifx-{today}.csv"
            is_new = not filepath.exists()
            self._file = open(filepath, "a", newline="")
            self._writer = csv.DictWriter(self._file, fieldnames=CSV_FIELDS)
            if is_new:
                self._writer.writeheader()
            self._current_date = today

    def log(self, bulb: BulbState):
        self._rotate()
        row = {
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "mac": bulb.mac,
            "name": bulb.name or "",
            "ip": bulb.ip or "",
            "dhcp_status": bulb.dhcp_status or "",
            "ping_ok": bulb.ping_ok,
            "ping_ms": f"{bulb.ping_ms:.1f}" if bulb.ping_ms else "",
            "lifx_ok": bulb.lifx_ok,
            "lifx_power": bulb.lifx_power or "",
            "capsman_registered": bulb.capsman_registered,
            "signal_dbm": bulb.signal_dbm if bulb.signal_dbm is not None else "",
            "tx_rate": bulb.tx_rate or "",
            "rx_rate": bulb.rx_rate or "",
            "uptime": bulb.uptime or "",
            "ap_interface": bulb.ap_interface or "",
            "ssid": bulb.ssid or "",
        }
        self._writer.writerow(row)
        self._file.flush()

    def close(self):
        if self._file:
            self._file.close()


# ─── Terminal Display ────────────────────────────────────────────────────────

# ANSI colors
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"


def clear_screen():
    print("\033[2J\033[H", end="")


def print_dashboard(bulbs: dict[str, BulbState], cycle_count: int, last_capsman_time: str):
    clear_screen()
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    print(f"{BOLD}╔══════════════════════════════════════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}║  LIFX Bulb Network Monitor                                             ║{RESET}")
    print(f"{BOLD}╚══════════════════════════════════════════════════════════════════════════╝{RESET}")
    print(f"  {DIM}Time: {now}  |  Cycle: {cycle_count}  |  Router: {ROUTER_IP}{RESET}")
    print(f"  {DIM}Last CAPsMAN check: {last_capsman_time}{RESET}")
    print()

    # Header
    print(f"  {'Name':<28} {'IP':<16} {'Ping':^6} {'LIFX':^6} {'WiFi':^6} {'Signal':>7} {'Uptime':>14} {'AP':>8}")
    print(f"  {'─'*28} {'─'*16} {'─'*6} {'─'*6} {'─'*6} {'─'*7} {'─'*14} {'─'*8}")

    # Sort: online first, then by name
    sorted_bulbs = sorted(
        bulbs.values(),
        key=lambda b: (not b.online, b.name or b.mac),
    )

    for b in sorted_bulbs:
        name = (b.name or b.mac)[:28]
        ip = (b.ip or "unknown")[:16]

        ping_str = f"{GREEN}✓{RESET}" if b.ping_ok else f"{RED}✗{RESET}"
        if b.ping_ok and b.ping_ms:
            ping_str = f"{GREEN}✓{RESET}{DIM}{b.ping_ms:>4.0f}ms{RESET}"
        else:
            ping_str = f"  {ping_str}     "

        lifx_str = f"  {GREEN}✓{RESET}   " if b.lifx_ok else f"  {RED}✗{RESET}   "
        wifi_str = f"  {GREEN}✓{RESET}   " if b.capsman_registered else f"  {RED}✗{RESET}   "

        sig_str = ""
        if b.signal_dbm is not None:
            sig = b.signal_dbm
            if sig > -60:
                sig_str = f"{GREEN}{sig:>4}dBm{RESET}"
            elif sig > -70:
                sig_str = f"{YELLOW}{sig:>4}dBm{RESET}"
            else:
                sig_str = f"{RED}{sig:>4}dBm{RESET}"
        else:
            sig_str = f"{DIM}     --{RESET}"

        up_str = f"{DIM}{(b.uptime or '--'):>14}{RESET}"
        ap_str = f"{DIM}{(b.ap_interface or '--'):>8}{RESET}"

        # Status indicator
        if b.ping_ok and b.lifx_ok and b.capsman_registered:
            status_color = GREEN
        elif b.capsman_registered and not b.lifx_ok:
            status_color = YELLOW  # WiFi ok but firmware unresponsive - zombie!
        else:
            status_color = RED

        print(f"  {status_color}{name:<28}{RESET} {ip:<16} {ping_str}{lifx_str}{wifi_str}{sig_str} {up_str} {ap_str}")

        # Special annotation for zombie state
        if b.capsman_registered and not b.lifx_ok and b.ip:
            print(f"  {YELLOW}  ⚠ ZOMBIE: WiFi connected but LIFX firmware unresponsive{RESET}")

    print()

    # Show recent state changes
    all_changes = []
    for b in bulbs.values():
        for change in b.state_changes[-5:]:
            all_changes.append(change)
    all_changes.sort(key=lambda c: c["time"], reverse=True)

    if all_changes:
        print(f"  {BOLD}Recent State Changes:{RESET}")
        for change in all_changes[:10]:
            if change["new_state"] == "offline":
                icon = f"{RED}▼{RESET}"
                detail = f"  last signal: {change.get('last_signal', '?')}dBm, last AP: {change.get('last_ap', '?')}"
            elif change["new_state"] == "zombie":
                icon = f"{YELLOW}⚡{RESET}"
                detail = "  WiFi connected but LIFX firmware unresponsive"
            else:
                icon = f"{GREEN}▲{RESET}"
                detail = ""
            print(f"  {icon} {change['time']} {change['name']}: {change['old_state']} → {change['new_state']}{detail}")

    print(f"\n  {DIM}Press Ctrl+C to stop monitoring{RESET}")


# ─── Main Monitor ────────────────────────────────────────────────────────────


class LIFXMonitor:
    def __init__(self):
        self.bulbs: dict[str, BulbState] = {}
        script_dir = Path(__file__).parent
        self.logger = CSVLogger(script_dir / "logs")
        self.cycle_count = 0
        self.last_capsman_time = "not yet"

    def discover(self):
        """Discover LIFX bulbs from router DHCP leases and resolve names via LIFX protocol."""
        print(f"  {DIM}Discovering LIFX bulbs from router DHCP leases...{RESET}")

        # Get DHCP leases
        leases = get_dhcp_leases()

        # Initialize/update bulb entries for all known MACs
        for mac in KNOWN_LIFX_MACS:
            if mac not in self.bulbs:
                self.bulbs[mac] = BulbState(mac=mac)
            if mac in leases:
                lease = leases[mac]
                self.bulbs[mac].ip = lease.get("ip")
                self.bulbs[mac].dhcp_status = lease.get("status")
                if lease.get("comment"):
                    # Use DHCP comment as name (strip "LIFX - " prefix if present)
                    name = lease["comment"]
                    if name.startswith("LIFX - "):
                        name = name[7:]
                    self.bulbs[mac].name = name

        # Also add any LIFX MACs found in leases that aren't in KNOWN_LIFX_MACS
        for mac, lease in leases.items():
            if mac not in self.bulbs:
                self.bulbs[mac] = BulbState(
                    mac=mac,
                    ip=lease.get("ip"),
                    dhcp_status=lease.get("status"),
                )
                name = lease.get("comment", "")
                if name.startswith("LIFX - "):
                    name = name[7:]
                self.bulbs[mac].name = name if name else None

        # Try to resolve names via LIFX LAN protocol for any bulbs that have IPs
        for mac, bulb in self.bulbs.items():
            if bulb.ip and not bulb.name:
                label = lifx_get_label(bulb.ip, timeout=2.0)
                if label:
                    bulb.name = label

        found = sum(1 for b in self.bulbs.values() if b.ip)
        total = len(self.bulbs)
        print(f"  Found {found}/{total} LIFX bulbs with active DHCP leases")
        for b in sorted(self.bulbs.values(), key=lambda x: x.name or x.mac):
            status = f"{GREEN}bound{RESET}" if b.dhcp_status == "bound" else f"{RED}{b.dhcp_status or 'no lease'}{RESET}"
            print(f"    {b.mac} → {b.ip or 'no IP':<16} {b.name or '(unknown)':<30} [{status}]")
        print()

    def run_ping_sweep(self):
        """Ping all bulbs with known IPs."""
        for mac, bulb in self.bulbs.items():
            if bulb.ip:
                ok, ms = ping_host(bulb.ip, timeout=2)
                bulb.ping_ok = ok
                bulb.ping_ms = ms
            else:
                bulb.ping_ok = False
                bulb.ping_ms = None

    def run_lifx_check(self):
        """Check LIFX protocol responsiveness for all bulbs with IPs."""
        for mac, bulb in self.bulbs.items():
            if bulb.ip:
                bulb.lifx_ok = lifx_check_alive(bulb.ip, timeout=2.0)
                # Also try to get power state
                state = lifx_get_light_state(bulb.ip, timeout=2.0)
                if state:
                    bulb.lifx_power = state["power"]
                    if not bulb.name and state["label"]:
                        bulb.name = state["label"]
                else:
                    bulb.lifx_power = None
            else:
                bulb.lifx_ok = False
                bulb.lifx_power = None

    def run_capsman_check(self):
        """Get CAPsMAN registration data for all LIFX bulbs."""
        self.last_capsman_time = datetime.now(timezone.utc).strftime("%H:%M:%S UTC")
        regs = get_capsman_registration()

        for mac, bulb in self.bulbs.items():
            if mac in regs:
                reg = regs[mac]
                bulb.capsman_registered = True
                bulb.signal_dbm = reg.get("signal_dbm")
                bulb.tx_rate = reg.get("tx_rate")
                bulb.rx_rate = reg.get("rx_rate")
                bulb.uptime = reg.get("uptime")
                bulb.ap_interface = reg.get("interface")
                bulb.ssid = reg.get("ssid")
            else:
                bulb.capsman_registered = False
                bulb.signal_dbm = None
                bulb.tx_rate = None
                bulb.rx_rate = None
                bulb.uptime = None
                bulb.ap_interface = None
                bulb.ssid = None

    def detect_state_changes(self):
        """Detect and record state transitions for each bulb."""
        now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

        for mac, bulb in self.bulbs.items():
            # Determine current state
            if bulb.capsman_registered and bulb.lifx_ok:
                new_state = "online"
            elif bulb.capsman_registered and not bulb.lifx_ok:
                new_state = "zombie"  # WiFi ok but firmware hung
            else:
                new_state = "offline"

            old_online = bulb.online
            old_state = "online" if old_online else "offline"

            # Skip state change detection on first cycle
            if self.cycle_count <= 1:
                bulb.online = new_state in ("online", "zombie")
                if bulb.online:
                    bulb.last_online = now
                    bulb.last_signal = bulb.signal_dbm
                    bulb.last_ap = bulb.ap_interface
                continue

            # Check for state change
            if new_state != old_state and not (
                old_state == "offline" and new_state == "offline"
            ):
                change = {
                    "time": now,
                    "name": bulb.name or bulb.mac,
                    "old_state": old_state,
                    "new_state": new_state,
                    "last_signal": bulb.last_signal,
                    "last_ap": bulb.last_ap,
                }
                bulb.state_changes.append(change)

                # Print alert immediately
                if new_state == "offline":
                    print(
                        f"\n  {RED}{BOLD}⚠ {bulb.name or bulb.mac} went OFFLINE{RESET}"
                        f"  {DIM}(last signal: {bulb.last_signal}dBm, last AP: {bulb.last_ap}){RESET}"
                    )
                    bulb.offline_since = now
                elif new_state == "zombie":
                    print(
                        f"\n  {YELLOW}{BOLD}⚡ {bulb.name or bulb.mac} is ZOMBIE{RESET}"
                        f"  {DIM}(WiFi connected but LIFX firmware unresponsive){RESET}"
                    )
                else:
                    duration = ""
                    if bulb.offline_since:
                        duration = f" (was offline since {bulb.offline_since})"
                    print(
                        f"\n  {GREEN}{BOLD}▲ {bulb.name or bulb.mac} came ONLINE{RESET}"
                        f"  {DIM}{duration}{RESET}"
                    )
                    bulb.offline_since = None

            # Update tracking state
            bulb.online = new_state in ("online", "zombie")
            if bulb.capsman_registered:
                bulb.last_online = now
                if bulb.signal_dbm is not None:
                    bulb.last_signal = bulb.signal_dbm
                if bulb.ap_interface:
                    bulb.last_ap = bulb.ap_interface

    def log_all(self):
        """Log current state of all bulbs to CSV."""
        for bulb in self.bulbs.values():
            self.logger.log(bulb)

    def run(self):
        """Main monitoring loop."""
        print(f"{BOLD}LIFX Bulb Network Monitor{RESET}")
        print(f"{'─' * 40}")

        # Check prerequisites — verify SSH key auth to router works
        test = ssh_command("/system identity print", timeout=5)
        if test is None:
            print(f"{RED}Error: Cannot SSH to router via '{SSH_HOST}' host alias.{RESET}")
            print(f"Ensure ~/.ssh/config is set up (run setup-ssh.sh) and SSH key is deployed to router.")
            sys.exit(1)

        # Initial discovery
        self.discover()

        if not any(b.ip for b in self.bulbs.values()):
            print(f"{RED}No LIFX bulbs found with active IPs. Check router connectivity.{RESET}")
            sys.exit(1)

        last_ping = 0
        last_protocol = 0
        last_capsman = 0
        last_discovery = time.time()

        print(f"\n  {DIM}Starting monitoring loop... (Ctrl+C to stop){RESET}\n")

        try:
            while True:
                now = time.time()
                did_something = False

                # Rediscovery
                if now - last_discovery >= DISCOVERY_INTERVAL:
                    self.discover()
                    last_discovery = now

                # Ping sweep
                if now - last_ping >= PING_INTERVAL:
                    self.run_ping_sweep()
                    last_ping = now
                    did_something = True

                # LIFX protocol check
                if now - last_protocol >= PROTOCOL_INTERVAL:
                    self.run_lifx_check()
                    last_protocol = now
                    did_something = True

                # CAPsMAN check
                if now - last_capsman >= CAPSMAN_INTERVAL:
                    self.run_capsman_check()
                    last_capsman = now
                    did_something = True

                if did_something:
                    self.cycle_count += 1
                    self.detect_state_changes()
                    self.log_all()
                    print_dashboard(self.bulbs, self.cycle_count, self.last_capsman_time)

                time.sleep(1)

        except KeyboardInterrupt:
            print(f"\n\n{BOLD}Monitoring stopped.{RESET}")
            self._print_summary()
            self.logger.close()

    def _print_summary(self):
        """Print summary of monitoring session."""
        print(f"\n{BOLD}Session Summary{RESET}")
        print(f"  Cycles: {self.cycle_count}")
        log_dir = Path(__file__).parent / "logs"
        print(f"  Logs: {log_dir}")
        print()

        changes = []
        for b in self.bulbs.values():
            changes.extend(b.state_changes)
        changes.sort(key=lambda c: c["time"])

        if changes:
            print(f"  {BOLD}All State Changes:{RESET}")
            for c in changes:
                print(f"    {c['time']}  {c['name']}: {c['old_state']} → {c['new_state']}")
        else:
            print(f"  No state changes detected during monitoring.")

        print()
        print(f"  {BOLD}Current Status:{RESET}")
        for b in sorted(self.bulbs.values(), key=lambda x: x.name or x.mac):
            state = "ONLINE" if b.online else "OFFLINE"
            color = GREEN if b.online else RED
            if b.capsman_registered and not b.lifx_ok:
                state = "ZOMBIE"
                color = YELLOW
            print(f"    {color}{state:<8}{RESET} {b.name or b.mac}")



if __name__ == "__main__":
    monitor = LIFXMonitor()
    monitor.run()
