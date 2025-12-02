#!/bin/bash
# Post-freeze diagnostic script for Proxmox host
# Run this immediately after the system becomes accessible

echo "=== System Freeze Diagnostics - $(date) ==="
echo ""

echo "=== Checking for kernel panics in previous boot ==="
journalctl -b -1 -p err | tail -50
echo ""

echo "=== Hardware errors from dmesg ==="
dmesg -T --level=emerg,alert,crit,err | tail -100
echo ""

echo "=== Disk health (SMART status) ==="
smartctl -H /dev/sda
smartctl -A /dev/sda | grep -E '(Current_Pending_Sector|Reallocated_Sector_Ct|Temperature_Celsius|UDMA_CRC_Error_Count)'
echo ""

echo "=== Check for I/O errors ==="
dmesg -T | grep -i "I/O error\|ata.*error\|blk_update_request"
echo ""

echo "=== Memory errors ==="
dmesg -T | grep -i "memory\|mce\|hardware error"
echo ""

echo "=== LVM/Device-mapper issues ==="
dmesg -T | grep -i "device-mapper\|dm-\|lvm"
echo ""

echo "=== USB subsystem issues (Zigbee stick) ==="
dmesg -T | grep -i "usb" | tail -50
lsusb
echo ""

echo "=== Inotify limits ==="
sysctl fs.inotify.max_user_watches
sysctl fs.inotify.max_user_instances
cat /proc/sys/fs/inotify/max_user_watches
echo ""

echo "=== File descriptor limits ==="
sysctl fs.file-nr
cat /proc/sys/fs/file-max
echo ""

echo "=== System load before freeze (from last boot) ==="
journalctl -b -1 --since "03:00" | grep -E "load average|Out of memory|blocked for more than"
echo ""

echo "=== Check for OOM killer ==="
journalctl -b -1 | grep -i "out of memory\|oom"
echo ""

echo "=== k3s node pressure conditions ==="
journalctl -b -1 -u k3s | grep -i "pressure\|evict\|throttl" | tail -20
echo ""

echo "=== System temperature/thermal ==="
sensors 2>/dev/null || echo "lm-sensors not installed"
echo ""

echo "=== Container/VM resource usage before freeze ==="
journalctl -b -1 --since "02:40" --until "03:30" | grep -E "cgroup|slice|memory|cpu" | tail -30
echo ""

echo "=== Check systemd freezes ==="
journalctl -b -1 | grep -i "watchdog\|hung_task\|blocked"
echo ""

echo "=== Kernel version and uptime info ==="
uname -a
echo ""

echo "=== Last successful log entries ==="
journalctl -b -1 | tail -100
