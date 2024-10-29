#!/bin/bash
comm -23 <(seq 1 65535 | sort) <(ss -tuln | awk '{print $4}' | grep -oE '[0-9]+$' | sort | uniq)

# This script finds the largest range of consecutive available ports.

# Get a list of all used ports
# used_ports=$(ss -tuln | awk 'NR > 1 {print $4}' | cut -d':' -f2 | sort -n | uniq)

# # Define the range of ports to check (1-65535)
# port_range=($(seq 1 65535))

# # Initialize variables
# largest_range_start=0
# largest_range_end=0
# current_range_start=0
# current_range_length=0
# max_length=0

# # Iterate through the port range
# for port in "${port_range[@]}"; do
#     if ! echo "$used_ports" | grep -q "^$port$"; then
#         if [[ $current_range_length -eq 0 ]]; then
#             current_range_start=$port
#         fi
#         ((current_range_length++))
#     else
#         if [[ $current_range_length -gt $max_length ]]; then
#             largest_range_start=$current_range_start
#             largest_range_end=$((current_range_start + current_range_length - 1))
#             max_length=$current_range_length
#         fi
#         current_range_length=0
#     fi
# done

# # Final check for the last range
# if [[ $current_range_length -gt $max_length ]]; then
#     largest_range_start=$current_range_start
#     largest_range_end=$((current_range_start + current_range_length - 1))
# fi

# # Output the largest range of consecutive available ports
# if [[ $max_length -gt 0 ]]; then
#     echo "Largest range of consecutive available ports: $largest_range_start to $largest_range_end"
# else
#     echo "No available ports found."
# fi
