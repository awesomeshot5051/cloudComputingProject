 #!/bin/bash

# Ensure a hostfile is specified
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <hostfile>"
    exit 1
fi

# Output file for valid hosts
hostfile="$1"

# Ensure the hostfile is writable
touch "$hostfile" || { echo "Error: Cannot write to $hostfile"; exit 1; }

# Clear the hostfile before writing
> "$hostfile"

# Extract IPs from `arp -a` into a variable to avoid subshell issues
ips=$(arp -a | awk '{print $2}' | tr -d '()')

# Loop through each IP
for ip in $ips; do
    # Skip empty lines
    [[ -z "$ip" ]] && continue

    echo "Trying to SSH into $ip..."

    # Attempt SSH with a short timeout
    if ssh -o ConnectTimeout=3 -o BatchMode=yes -q ec2-user@"$ip" exit; then
        echo "Success: Adding $ip to $hostfile"
        echo "$ip:1" >> "$hostfile"
    else
        echo "Failed: Skipping $ip"
    fi
done

echo "Discovery complete. Valid hosts saved to $hostfile."
