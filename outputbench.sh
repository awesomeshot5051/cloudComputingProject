#!/bin/bash
echo "Switching to the project directory"
cd /home/project/IOR-MPI
date=$(date +%b%d)

# Check if a number was passed as an argument
if [[ $# -eq 1 ]]; then
    NUM=$1
else
    echo "Usage: $0 <num>"
    exit 1
fi

# Get the private IP addresses of running instances tagged as Compute nodes
PRIVATE_IPS=$(aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[PrivateIpAddress]' \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=Compute" \
  --output text)

# Convert the string to an array
IP_ARRAY=($PRIVATE_IPS)

# Construct a comma-separated list of IP addresses for mpiexec
NODE_LIST=$(IFS=,; echo "${IP_ARRAY[*]}")

echo "Checking to make sure IORoutputs directory exists"
sudo mkdir -p /home/project/IOR-MPI/IORoutputs  # '-p' will not throw an error if the directory already exists
echo "IORoutputs directory either exists or was just created."

# Run IOR benchmarks using mpiexec with the computed node list
for i in 1 2 4 6 8; do
    NODES=$(echo $NODE_LIST | cut -d ',' -f 1-$i)
    mpiexec -host $NODES /home/project/IOR-MPI/IOR/src/C/IOR > /home/project/IOR-MPI/IORoutputs/$date-$NUM.${i}node.txt && sudo chmod 777 /home/project/IOR-MPI/IORoutputs/$date-$NUM.${i}node.txt
    echo "$i Node IOR Benchmark Successful"
done

# Ensure the output directory exists
sudo mkdir -p /home/project/outputfiles

# Define the output file path
OUTPUT_FILE="/home/project/outputfiles/ior/$NUM-run-$date.txt"

# Extract and print the relevant sections from all generated files
echo "Extracted IOR Benchmark Results:" | tee "$OUTPUT_FILE"
for file in /home/project/IOR-MPI/IORoutputs/$date-$NUM.*node.txt; do
    NODE_COUNT=$(echo "$file" | grep -oP '\d+(?=node\.txt)')
    echo "===== Results from $NODE_COUNT-node(s) =====" | tee -a "$OUTPUT_FILE"
    awk '/^Operation/,/^Run finished/' "$file" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
done

echo "Results saved to $OUTPUT_FILE"
