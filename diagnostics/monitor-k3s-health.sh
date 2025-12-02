#!/bin/bash
# Continuous monitoring script to catch issues before next freeze
# Run in background: nohup ./monitor-k3s-health.sh > /var/log/k3s-monitor.log 2>&1 &

LOG_FILE="/var/log/k3s-health-monitor.log"
INTERVAL=60  # Check every 60 seconds

echo "=== Starting k3s health monitoring at $(date) ===" | tee -a "$LOG_FILE"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if host is responsive
    if ! timeout 5 echo "alive" > /dev/null 2>&1; then
        echo "[$TIMESTAMP] WARNING: System appears to be hanging" >> "$LOG_FILE"
    fi
    
    # Check k3s node status
    NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    if [ "$NODE_STATUS" != "True" ]; then
        echo "[$TIMESTAMP] CRITICAL: k3s node not ready: $NODE_STATUS" >> "$LOG_FILE"
    fi
    
    # Check for node pressure
    PRESSURE=$(kubectl get nodes -o jsonpath='{.items[0].status.conditions[?(@.status=="True")].type}' 2>/dev/null | grep -i pressure)
    if [ -n "$PRESSURE" ]; then
        echo "[$TIMESTAMP] WARNING: Node pressure detected: $PRESSURE" >> "$LOG_FILE"
    fi
    
    # Check MetalLB speaker logs for IP reassignments
    METALLB_EVENTS=$(kubectl logs -n metallb-system -l component=speaker --since=1m 2>/dev/null | grep -i "updated\|error\|failed")
    if [ -n "$METALLB_EVENTS" ]; then
        echo "[$TIMESTAMP] MetalLB activity:" >> "$LOG_FILE"
        echo "$METALLB_EVENTS" >> "$LOG_FILE"
    fi
    
    # Check system load
    LOAD=$(cat /proc/loadavg | awk '{print $1}')
    echo "[$TIMESTAMP] Load: $LOAD" >> "$LOG_FILE"
    
    # Check available memory
    MEM_AVAIL=$(free -m | awk '/^Mem:/ {print $7}')
    echo "[$TIMESTAMP] Memory available: ${MEM_AVAIL}M" >> "$LOG_FILE"
    
    # Check for I/O wait
    IOWAIT=$(top -bn1 | grep "Cpu(s)" | awk '{print $10}' | sed 's/%wa,//')
    if (( $(echo "$IOWAIT > 10" | bc -l) )); then
        echo "[$TIMESTAMP] WARNING: High I/O wait: $IOWAIT%" >> "$LOG_FILE"
        iostat -x 1 1 >> "$LOG_FILE"
    fi
    
    # Check for container issues
    CONTAINER_ERRORS=$(journalctl -u k3s --since "1 minute ago" | grep -i "error\|failed\|timeout" | wc -l)
    if [ "$CONTAINER_ERRORS" -gt 5 ]; then
        echo "[$TIMESTAMP] WARNING: $CONTAINER_ERRORS errors in k3s logs" >> "$LOG_FILE"
    fi
    
    sleep "$INTERVAL"
done
