#!/bin/bash

# Original script: https://github.com/MatthewVance/unbound-docker

# Reserved memory (12 MiB)
RESERVED=12582912

# Default values (will be auto-detected if not provided)
MANUAL_AVAILABLE_MEMORY=""
MANUAL_THREADS=""

# Parse command-line options
while getopts "m:t:h" opt; do
  case "$opt" in
    m)
      MANUAL_AVAILABLE_MEMORY="$OPTARG"
      ;;
    t)
      MANUAL_THREADS="$OPTARG"
      ;;
    h)
      echo "Usage: $0 [-m memory] [-t threads]"
      echo "  -m  Manually specify available memory in MiB"
      echo "  -t  Manually specify number of CPU threads"
      exit 0
      ;;
    *)
      echo "Invalid option. Use -h for help." >&2
      exit 1
      ;;
  esac
done

# Determine available memory
if [[ -n "$MANUAL_AVAILABLE_MEMORY" ]]; then
    AVAILABLE_MEMORY="$((MANUAL_AVAILABLE_MEMORY * 1024 * 1024))"
else
    AVAILABLE_MEMORY=$((1024 * $( (grep MemAvailable /proc/meminfo || grep MemTotal /proc/meminfo) | sed 's/[^0-9]//g' )))
fi

# Check if there's enough memory
if [[ $AVAILABLE_MEMORY -le $((RESERVED * 2)) ]]; then
    echo "Not enough memory" >&2
    exit 1
fi

# Calculate cache sizes
AVAILABLE_MEMORY=$((AVAILABLE_MEMORY - RESERVED))
RRSET_CACHE_SIZE=$((AVAILABLE_MEMORY / 3))
MSG_CACHE_SIZE=$((RRSET_CACHE_SIZE / 2))

# Determine number of threads
if [[ -n "$MANUAL_THREADS" ]]; then
    NPROC="$MANUAL_THREADS"
else
    NPROC=$(nproc)
fi

if [[ "$NPROC" -gt 1 ]]; then
    NUM_THREADS=$((NPROC - 1))
    # Calculate base-2 logarithm using bc
    NPROC_LOG=$(echo "l($NPROC)/l(2)" | bc -l)
    # Round the result to the nearest integer
    ROUNDED_NPROC_LOG=$(printf '%.0f' "$NPROC_LOG")
    # Calculate slabs as a power of 2
    MSG_CACHE_SLABS=$(( 2 ** ROUNDED_NPROC_LOG ))
else
    NUM_THREADS=1
    MSG_CACHE_SLABS=4
fi

# Calculate number of slabs
if [[ "$NUM_THREADS" -gt 1 ]]; then
    # Calculate base-2 logarithm using bc
    NPROC_LOG=$(echo "l($NUM_THREADS)/l(2)" | bc -l)
    # Round the result to the nearest integer
    ROUNDED_NPROC_LOG=$(printf '%.0f' "$NPROC_LOG")
    # Compute slabs as power of 2
    MSG_CACHE_SLABS=$(( 2 ** ROUNDED_NPROC_LOG ))
else
    MSG_CACHE_SLABS=4
fi

# Output recommended configuration
echo "
========================================
Recommended parameters for unbound.conf:

msg-cache-size = $MSG_CACHE_SIZE
rrset-cache-size = $RRSET_CACHE_SIZE
num-threads = $NUM_THREADS
msg-cache-slabs = $MSG_CACHE_SLABS
rrset-cache-slabs = $MSG_CACHE_SLABS
========================================
"
