# Proxmox Host Freeze Diagnostics

## Issue Summary
System freezes completely around 03:00-03:25 AM:
- Host becomes unresponsive (no ACPI shutdown response)
- Zigbee USB stick loses communication with Home Assistant VM
- SSH connection refused
- Backups complete successfully at 03:00 before freeze

## Symptoms Timeline
- **02:45:39**: MetalLB reassigns LoadBalancer IPs (possible early warning)
- **03:00:00**: Backup jobs run successfully
- **03:25:34**: Last log entry - system appears to freeze shortly after
- **No kernel panic or OOM messages in logs**

## Diagnostic Steps

### 1. Immediate Post-Recovery
Run the diagnostic script as soon as the system is accessible:
```bash
cd /workspaces/homelab/diagnostics
chmod +x post-freeze-check.sh
./post-freeze-check.sh > freeze-diagnostic-$(date +%Y%m%d).log
```

### 2. Ongoing Monitoring
Start the monitoring script to capture data before the next freeze:
```bash
chmod +x monitor-k3s-health.sh
nohup ./monitor-k3s-health.sh > /var/log/k3s-monitor.log 2>&1 &
```

## Likely Causes (Host-Level Freeze)

### Hardware Issues
1. **Storage**: Disk I/O hang or controller issue
2. **Memory**: Hardware errors causing kernel deadlock
3. **USB subsystem**: Deadlock affecting Zigbee stick and potentially triggering cascade
4. **Thermal**: CPU/chipset overheating

### Kernel-Level Issues
1. **Device-mapper/LVM deadlock**: Heavy container I/O causing storage stack hang
2. **inotify exhaustion**: k3s watches too many files
3. **Network driver hang**: Affecting both k3s and host networking
4. **Kernel bug**: Specific to your kernel version

### System Resource Exhaustion
1. **File descriptors**: Kernel-level exhaustion
2. **Memory pressure**: Leading to kernel deadlock
3. **I/O scheduler**: Starving critical processes

## Recommended Actions

### Short-term
1. Check `/var/log/kern.log` for hardware errors
2. Review SMART data: `smartctl -A /dev/sda`
3. Check kernel messages: `dmesg -T | less`
4. Verify USB stability: `lsusb -t`

### Long-term Prevention
1. **Increase inotify limits** (for k3s):
   ```bash
   echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
   echo "fs.inotify.max_user_instances=512" >> /etc/sysctl.conf
   sysctl -p
   ```

2. **Monitor disk health regularly**:
   ```bash
   smartctl -H /dev/sda
   ```

3. **Add kernel watchdog** (auto-reboot on freeze):
   ```bash
   echo "kernel.panic=10" >> /etc/sysctl.conf
   echo "kernel.hung_task_timeout_secs=120" >> /etc/sysctl.conf
   ```

4. **Consider moving k3s to dedicated LXC/VM** instead of host to isolate issues

5. **Schedule resource-intensive tasks** (backups, updates) at different times

## Investigation Questions
- Does the freeze always happen around the same time (3 AM)?
- Are there scheduled tasks running at that time? (check `crontab -l` and `/etc/cron.d/`)
- Is there a pattern with backup completion? (freeze happens shortly after)
- What kernel version? (`uname -r`)
- How much RAM is installed?
- What disk controller/type?
