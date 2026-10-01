# Linux System Status Checker

A portable Bash script that reports the current status and health information of a Linux system.

## Features

The script reports:

* CPU usage and CPU core count
* 1, 5, and 15-minute load averages
* Memory usage
* Available and free RAM
* Swap usage
* Disk usage for mounted filesystems
* System uptime
* Top processes by CPU usage
* Top processes by memory usage
* Network interfaces and IP addresses
* Listening network ports
* Currently logged-in users
* Current user and root privileges
* Basic container detection
* Human-readable output
* JSON output for machine processing
* RFC 3339 timestamps

## Requirements

The script is designed to run on most Linux distributions.

It primarily uses standard Linux interfaces and commonly available utilities such as:

* Bash
* `/proc`
* `ps`
* `df`
* `ip`
* `ss`
* `who`
* Python 3 for JSON output

The script checks whether optional commands are available before using them.

## Installation
Clone the repository:
```bash
git clone https://github.com/ZSSulte/Linux-System-Status-Assignment.git
```
Enter the project directory:
```bash
cd Linux-System-Status-Assignment
```
Make the script executable:
```bash
chmod +x linux-system-status.sh
```

## Usage

### Human-readable output

Run:

```bash
./linux-system-status.sh
```

The script displays information such as:

```text
========================================
       LINUX SYSTEM STATUS
========================================

System
------
Hostname:        ubuntu-server
OS:              Ubuntu 24.04.3 LTS
Time:            2026-09-30T22:30:15+08:00
User:            steven
Running as root: false
Container:       false

CPU
---
CPU cores:       8
CPU usage:       6.8%
Load average:    0.52 0.44 0.39

Memory
------
Total:           16000000 kB
Used:            6500000 kB
Available:       9500000 kB
Free:            1800000 kB
Swap total:      2000000 kB
Swap used:       0 kB

Disk
----
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       100G   42G   58G  42% /
/dev/sdb1       500G  210G  290G  42% /home

Top Processes by CPU
--------------------
    PID USER     %CPU %MEM COMMAND
   2314 steven    18.2  4.1 firefox
   1842 steven     7.5  2.3 code
   1023 root       2.1  0.8 Xorg
   3211 steven     1.4  1.2 chrome
   1456 root       0.9  0.5 systemd

Top Processes by Memory
-----------------------
    PID USER     %CPU %MEM COMMAND
   2314 steven     18.2  4.1 firefox
   3211 steven      1.4  3.8 chrome
   1842 steven      7.5  2.3 code
   1023 root        2.1  0.8 Xorg
   1456 root        0.9  0.5 systemd

Network Interfaces
------------------
lo       UNKNOWN 127.0.0.1/8
eth0     UP      192.168.1.25/24

Listening Ports
---------------
Netid State  Local Address:Port
tcp   LISTEN 0.0.0.0:22
tcp   LISTEN 0.0.0.0:80

Logged-in Users
---------------
steven   pts/0   2026-09-30 21:45

========================================
             END OF REPORT
========================================
```

The actual values depend on the system where the script is executed.

### JSON output

For machine-readable output:

```bash
./linux-system-status.sh --json
```

The JSON output contains the same major categories as the human-readable report.

Example:

```json
{
  "system": {
    "hostname": "ubuntu-server",
    "os": "Ubuntu 24.04.3 LTS",
    "timestamp": "2026-09-30T22:30:15+08:00",
    "user": "steven",
    "running_as_root": false,
    "container": false
  },

  "cpu": {
    "cores": 8,
    "usage_percent": 6.8,
    "load_average": {
      "1_minute": 0.52,
      "5_minutes": 0.44,
      "15_minutes": 0.39
    }
  },

  "memory": {
    "total_kb": 16000000,
    "used_kb": 6500000,
    "available_kb": 9500000,
    "free_kb": 1800000,
    "swap_total_kb": 2000000,
    "swap_used_kb": 0
  },

  "uptime": {
    "seconds": 86400
  },

  "disk": {
    "filesystems": [
      "Filesystem      Size  Used Avail Use% Mounted on",
      "/dev/sda2       100G   42G   58G  42% /",
      "/dev/sdb1       500G  210G  290G  42% /home"
    ]
  },

  "processes": {
    "top_cpu": [
      "PID USER     %CPU %MEM COMMAND",
      "2314 steven   18.2  4.1 firefox",
      "1842 steven    7.5  2.3 code"
    ],
    "top_memory": [
      "PID USER     %CPU %MEM COMMAND",
      "2314 steven   18.2  4.1 firefox",
      "3211 steven    1.4  3.8 chrome"
    ]
  },

  "network": {
    "interfaces": [
      "lo       UNKNOWN 127.0.0.1/8",
      "eth0     UP      192.168.1.25/24"
    ],
    "listening_ports": [
      "Netid State Local Address:Port",
      "tcp LISTEN 0.0.0.0:22",
      "tcp LISTEN 0.0.0.0:80"
    ]
  },

  "logged_in_users": [
    "steven   pts/0   2026-09-30 21:45"
  ]
}
```

## Design Requirements

### Platform Agnostic

The script avoids distribution-specific commands where possible and uses standard Linux interfaces and utilities.

### Graceful Degradation

Optional commands are checked before being used. If a utility is unavailable, the corresponding section reports that the information is unavailable instead of terminating the entire script.

### User Permissions

The script checks the current user's identity and determines whether it is running as root.

It does not automatically invoke `sudo` or request an interactive password.

### Non-Interactive Safe

The script does not require user input or a TTY. It can therefore be used manually or from automation such as cron or systemd.

### Idempotent and Read-Only

The script only reads system information.

It does not:

* Modify configuration files
* Install packages
* Stop or restart services
* Kill processes
* Create or delete system resources

Running the script multiple times does not intentionally change system state.

### Human and Machine Readable

The default output is formatted for people to read in a terminal.

The `--json` option provides structured output for other applications, monitoring tools, or scripts.

### RFC 3339 Dates

System timestamps are generated using RFC 3339-compatible formatting, for example:

```text
2026-09-30T22:30:15+08:00
```

### Container Awareness

The script performs basic container detection using indicators such as `/.dockerenv` and container-related cgroup information.

## Project Structure

```text
linux-system-status/
├── .gitignore
├── README.md
└── linux-system-status.sh
```

## Author

ZSSulte
