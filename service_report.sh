#!/bin/bash

# Clear or create report file
> report.txt

# Get all active services
services=$(systemctl list-units --type=service --state=active --no-legend | awk '{print $1}')

for service in $services; do
    # Skip one-shot services
    type=$(systemctl show -p Type "$service" | cut -d= -f2)
    if [[ "$type" == "oneshot" ]]; then
        continue
    fi

    echo "Service Name: $service" | tee -a report.txt
    
    # Get the main PID
    pid=$(systemctl show -p MainPID "$service" | cut -d= -f2)
    
    if [[ -z "$pid" || "$pid" == "0" ]]; then
        echo "PID not found" | tee -a report.txt
        echo "" | tee -a report.txt
        continue
    fi
    
    # Determine technology based on the command line of the main PID
    cmd=$(ps -p "$pid" -o args= 2>/dev/null)
    if [[ -z "$cmd" ]]; then
        tech="Unknown"
    elif echo "$cmd" | grep -q -i 'python'; then
        tech="Python"
    elif echo "$cmd" | grep -q -i 'dotnet'; then
        tech=".NET"
    elif echo "$cmd" | grep -q -i 'java'; then
        tech="Java"
    elif echo "$cmd" | grep -q -i 'node'; then
        tech="Node.js"
    else
        tech="Other"
    fi
    echo "Technology: $tech" | tee -a report.txt
    
    # Collect CPU usage (-u) for main PID
    cpu_output=$(pidstat -p "$pid" -u 1 1 2>/dev/null | tail -n 1 | awk '{print $8}')
    total_cpu=$(printf "%.2f" "${cpu_output:-0}")
    
    # Collect memory usage (-r) for main PID
    mem_output=$(pidstat -p "$pid" -r 1 1 2>/dev/null | tail -n 1 | awk '{print $8}')
    total_mem=$(printf "%.2f" "${mem_output:-0}")
    
    # Collect disk I/O (-d) for main PID
    disk_output=$(pidstat -p "$pid" -d 1 1 2>/dev/null | tail -n 1)
    total_disk_read=$(echo "$disk_output" | awk '{print $4}' | grep -E '^[0-9]+(\.[0-9]+)?$' || echo "0")
    total_disk_write=$(echo "$disk_output" | awk '{print $5}' | grep -E '^[0-9]+(\.[0-9]+)?$' || echo "0")
    total_disk_read=$(printf "%.2f" "${total_disk_read:-0}")
    total_disk_write=$(printf "%.2f" "${total_disk_write:-0}")
    
    echo "CPU Usage: $total_cpu%" | tee -a report.txt
    echo "Memory Usage: $total_mem%" | tee -a report.txt
    echo "Disk Read: $total_disk_read kB/s" | tee -a report.txt
    echo "Disk Write: $total_disk_write kB/s" | tee -a report.txt
    echo "" | tee -a report.txt
done

echo "Note: Resource usage reflects the main process for each service, matching htop’s per-process stats. Multi-threaded services like Jenkins may have a larger total memory footprint due to shared thread memory (e.g., Jenkins ~12.5G total)." | tee -a report.txt
