#!/bin/bash

LOG_FILE=${1:-"usage_log.csv"}  # Allow user to specify filename, default to "usage_log.csv"

# Print CSV header if file doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    echo "Timestamp,CPU Usage,Memory Usage,GPU Index,GPU UUID,GPU Usage,GPU Memory Total,GPU Memory Used,GPU Memory Free,GPU Name,GPU Serial,GPU Processes" > "$LOG_FILE"
fi

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    # Get CPU and Memory usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}')
    MEM_USAGE=$(free | awk '/Mem:/ {printf "%.2f%%", $3/$2 * 100}')

    # Get detailed GPU usage and memory information
    GPU_INFO=$(nvidia-smi --query-gpu=timestamp,index,uuid,utilization.gpu,memory.total,memory.used,memory.free,name,gpu_serial --format=csv,noheader,nounits)

    # Get running GPU processes (handle empty case)
    GPU_PROCESS_LIST=$(nvidia-smi --query-compute-apps=name --format=csv,noheader 2>/dev/null | sort | uniq | paste -sd "," -)
    [ -z "$GPU_PROCESS_LIST" ] && GPU_PROCESS_LIST="None"

    # Process each GPU entry
    while IFS=',' read -r GPU_TIMESTAMP GPU_INDEX GPU_UUID GPU_USAGE GPU_MEM_TOTAL GPU_MEM_USED GPU_MEM_FREE GPU_NAME GPU_SERIAL; do
        GPU_USAGE="${GPU_USAGE}%"
        GPU_MEM_TOTAL="${GPU_MEM_TOTAL} MB"
        GPU_MEM_USED="${GPU_MEM_USED} MB"
        GPU_MEM_FREE="${GPU_MEM_FREE} MB"

        # Log to CSV file
        echo "\"$TIMESTAMP\",\"$CPU_USAGE\",\"$MEM_USAGE\",\"$GPU_INDEX\",\"$GPU_UUID\",\"$GPU_USAGE\",\"$GPU_MEM_TOTAL\",\"$GPU_MEM_USED\",\"$GPU_MEM_FREE\",\"$GPU_NAME\",\"$GPU_SERIAL\",\"$GPU_PROCESS_LIST\"" >> "$LOG_FILE"

        # Print output to console for verification
        echo "$TIMESTAMP, CPU: $CPU_USAGE, Mem: $MEM_USAGE, GPU $GPU_INDEX: $GPU_NAME ($GPU_UUID), GPU Util: $GPU_USAGE, Mem: $GPU_MEM_USED / $GPU_MEM_TOTAL (Free: $GPU_MEM_FREE), Serial: $GPU_SERIAL, Processes: $GPU_PROCESS_LIST"

    done <<< "$GPU_INFO"

    sleep 2
done
