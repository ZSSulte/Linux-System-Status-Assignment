#!/usr/bin/env bash

# ============================================================
# Linux System Status Checker
#
# Usage:
#   ./system_status.sh
#   ./system_status.sh --json
#
# The script is read-only and does not modify system state.
# ============================================================

set -u

JSON_MODE=false

if [[ "${1:-}" == "--json" ]]; then
    JSON_MODE=true
fi

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_timestamp() {
    date --rfc-3339=seconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z'
}

get_hostname() {
    hostname 2>/dev/null || echo "unknown"
}

get_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-unknown}"
    else
        echo "unknown"
    fi
}

# ------------------------------------------------------------
# Basic system information
# ------------------------------------------------------------

HOSTNAME_VALUE="$(get_hostname)"
OS_VALUE="$(get_os)"
TIMESTAMP="$(get_timestamp)"
CURRENT_USER="$(id -un 2>/dev/null || echo unknown)"

if [[ "$(id -u 2>/dev/null || echo 999)" -eq 0 ]]; then
    IS_ROOT="true"
else
    IS_ROOT="false"
fi

# ------------------------------------------------------------
# CPU information
# ------------------------------------------------------------

CPU_CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"

read_cpu_times() {
    awk '/^cpu / {
        total=$2+$3+$4+$5+$6+$7+$8+$9+$10
        idle=$5+$6
        print total, idle
        exit
    }' /proc/stat 2>/dev/null
}

CPU1="$(read_cpu_times)"

sleep 0.2

CPU2="$(read_cpu_times)"

CPU_USAGE="unknown"

if [[ -n "$CPU1" && -n "$CPU2" ]]; then
    read -r TOTAL1 IDLE1 <<< "$CPU1"
    read -r TOTAL2 IDLE2 <<< "$CPU2"

    TOTAL_DIFF=$((TOTAL2 - TOTAL1))
    IDLE_DIFF=$((IDLE2 - IDLE1))

    if (( TOTAL_DIFF > 0 )); then
        CPU_USAGE="$(awk -v total="$TOTAL_DIFF" -v idle="$IDLE_DIFF" \
            'BEGIN { printf "%.1f", (100 * (total - idle) / total) }')"
    fi
fi

# ------------------------------------------------------------
# Load average
# ------------------------------------------------------------

LOAD_AVG="$(awk '{print $1, $2, $3}' /proc/loadavg 2>/dev/null || echo "unknown unknown unknown")"

read -r LOAD1 LOAD5 LOAD15 <<< "$LOAD_AVG"

# ------------------------------------------------------------
# Memory information
# ------------------------------------------------------------

MEM_TOTAL="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
MEM_AVAILABLE="$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
MEM_FREE="$(awk '/^MemFree:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"

if [[ "$MEM_TOTAL" =~ ^[0-9]+$ && "$MEM_AVAILABLE" =~ ^[0-9]+$ ]]; then
    MEM_USED=$((MEM_TOTAL - MEM_AVAILABLE))
else
    MEM_USED=0
fi

SWAP_TOTAL="$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
SWAP_FREE="$(awk '/^SwapFree:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"

if [[ "$SWAP_TOTAL" =~ ^[0-9]+$ && "$SWAP_FREE" =~ ^[0-9]+$ ]]; then
    SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
else
    SWAP_USED=0
fi

# ------------------------------------------------------------
# Uptime
# ------------------------------------------------------------

UPTIME_SECONDS="$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)"

# ------------------------------------------------------------
# Top processes
# ------------------------------------------------------------

TOP_CPU="unavailable"
TOP_MEM="unavailable"

if command_exists ps; then
    TOP_CPU="$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu 2>/dev/null | head -n 6)"
    TOP_MEM="$(ps -eo pid,user,%cpu,%mem,comm --sort=-%mem 2>/dev/null | head -n 6)"
fi

# ------------------------------------------------------------
# Disk usage
# ------------------------------------------------------------

DISK_INFO="unavailable"

if command_exists df; then
    DISK_INFO="$(df -P -h 2>/dev/null | awk 'NR==1 || $6 ~ /^\//')"
fi

# ------------------------------------------------------------
# Network interfaces
# ------------------------------------------------------------

NETWORK_INFO="unavailable"

if command_exists ip; then
    NETWORK_INFO="$(ip -brief address 2>/dev/null || echo "unavailable")"
fi

# ------------------------------------------------------------
# Listening ports
# ------------------------------------------------------------

PORT_INFO="unavailable"

if command_exists ss; then
    PORT_INFO="$(ss -lntup 2>/dev/null || ss -lnt 2>/dev/null || echo "unavailable")"
fi

# ------------------------------------------------------------
# Logged-in users
# ------------------------------------------------------------

USERS="unavailable"

if command_exists who; then
    USERS="$(who 2>/dev/null)"; [[ -z "$USERS" ]] && USERS="none (no login sessions in utmp)"
fi

# ------------------------------------------------------------
# Container detection
# ------------------------------------------------------------

CONTAINER="false"

if [[ -f /.dockerenv ]]; then
    CONTAINER="true"
elif grep -qaE 'docker|containerd|kubepods|podman' /proc/1/cgroup 2>/dev/null; then
    CONTAINER="true"
fi

# ------------------------------------------------------------
# Human-readable output
# ------------------------------------------------------------

print_human() {
    echo "========================================"
    echo "       LINUX SYSTEM STATUS"
    echo "========================================"
    echo

    echo "System"
    echo "------"
    echo "Hostname:       $HOSTNAME_VALUE"
    echo "OS:             $OS_VALUE"
    echo "Time:           $TIMESTAMP"
    echo "User:           $CURRENT_USER"
    echo "Running as root: $IS_ROOT"
    echo "Container:      $CONTAINER"
    echo

    echo "CPU"
    echo "---"
    echo "CPU cores:      $CPU_CORES"
    echo "CPU usage:      ${CPU_USAGE}%"
    echo "Load average:   $LOAD1 $LOAD5 $LOAD15"
    echo

    echo "Memory"
    echo "------"
    echo "Total:          ${MEM_TOTAL} kB"
    echo "Used:           ${MEM_USED} kB"
    echo "Available:      ${MEM_AVAILABLE} kB"
    echo "Free:           ${MEM_FREE} kB"
    echo "Swap total:     ${SWAP_TOTAL} kB"
    echo "Swap used:      ${SWAP_USED} kB"
    echo

    echo "Disk"
    echo "----"
    echo "$DISK_INFO"
    echo

    echo "Top Processes by CPU"
    echo "--------------------"
    echo "$TOP_CPU"
    echo

    echo "Top Processes by Memory"
    echo "-----------------------"
    echo "$TOP_MEM"
    echo

    echo "Network Interfaces"
    echo "------------------"
    echo "$NETWORK_INFO"
    echo

    echo "Listening Ports"
    echo "---------------"
    echo "$PORT_INFO"
    echo

    echo "Logged-in Users"
    echo "---------------"
    echo "$USERS"
    echo

    echo "========================================"
    echo "             END OF REPORT"
    echo "========================================"
}

# ------------------------------------------------------------
# JSON output
# ------------------------------------------------------------

print_json() {
    if ! command_exists python3; then
        echo '{"error":"python3 is required for JSON output"}'
        return
    fi

    python3 - \
        "$HOSTNAME_VALUE" \
        "$OS_VALUE" \
        "$TIMESTAMP" \
        "$CURRENT_USER" \
        "$IS_ROOT" \
        "$CONTAINER" \
        "$CPU_CORES" \
        "$CPU_USAGE" \
        "$LOAD1" \
        "$LOAD5" \
        "$LOAD15" \
        "$MEM_TOTAL" \
        "$MEM_USED" \
        "$MEM_AVAILABLE" \
        "$MEM_FREE" \
        "$SWAP_TOTAL" \
        "$SWAP_USED" \
        "$UPTIME_SECONDS" \
        "$DISK_INFO" \
        "$NETWORK_INFO" \
        "$PORT_INFO" \
        "$TOP_CPU" \
        "$TOP_MEM" \
        "$USERS" <<'PY'

import json
import sys

(
    hostname,
    os_name,
    timestamp,
    user,
    is_root,
    container,
    cpu_cores,
    cpu_usage,
    load1,
    load5,
    load15,
    mem_total,
    mem_used,
    mem_available,
    mem_free,
    swap_total,
    swap_used,
    uptime_seconds,
    disk_info,
    network_info,
    port_info,
    top_cpu,
    top_mem,
    users
) = sys.argv[1:]


def number(value):
    try:
        return float(value)
    except (ValueError, TypeError):
        return None


def integer(value):
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


def lines(value):
    """Convert multi-line command output into a JSON array."""
    if not value or value == "unavailable":
        return []

    return [
        line
        for line in value.splitlines()
        if line.strip()
    ]


data = {
    "system": {
        "hostname": hostname,
        "os": os_name,
        "timestamp": timestamp,
        "user": user,
        "running_as_root": is_root == "true",
        "container": container == "true"
    },

    "cpu": {
        "cores": integer(cpu_cores),
        "usage_percent": number(cpu_usage),
        "load_average": {
            "1_minute": number(load1),
            "5_minutes": number(load5),
            "15_minutes": number(load15)
        }
    },

    "memory": {
        "total_kb": integer(mem_total),
        "used_kb": integer(mem_used),
        "available_kb": integer(mem_available),
        "free_kb": integer(mem_free),
        "swap_total_kb": integer(swap_total),
        "swap_used_kb": integer(swap_used)
    },

    "uptime": {
        "seconds": integer(uptime_seconds)
    },

    "disk": {
        "filesystems": lines(disk_info)
    },

    "processes": {
        "top_cpu": lines(top_cpu),
        "top_memory": lines(top_mem)
    },

    "network": {
        "interfaces": lines(network_info),
        "listening_ports": lines(port_info)
    },

    "logged_in_users": lines(users)
}

print(json.dumps(data, indent=2))
PY
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

if [[ "$JSON_MODE" == true ]]; then
    print_json
else
    print_human
fi

