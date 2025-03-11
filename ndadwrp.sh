#!/bin/bash

# Ensure both parameters are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <hostfile> <username>"
    exit 1
fi

# Define your actual username (the one with SSH access)
YOUR_USER="ec2-user"

# Run the original script as your user
sudo -u "$YOUR_USER" /bin/nodeuseradd.sh "$1" "$2"
