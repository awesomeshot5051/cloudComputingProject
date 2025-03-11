#!/bin/bash

# Check if the script is run as root (sudo)
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  echo "Usage: sudo $0 <hostfile> [username] [-x]"
  exit 1
fi

# Ensure at least the hostfile parameter is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <hostfile> [username] [-x]"
    exit 1
fi

# Assign the hostfile parameter
hostfile="$1"

# Check if the username is provided as a second parameter, otherwise use the current username
if [ "$#" -eq 2 ]; then
    username="$2"
else
    # Get the current logged-in username if not provided
    username=$(whoami)
    echo "No username provided. Using the current username: $username"
fi

# Check if the -x flag is passed
if [[ " $* " == *" -x "* ]]; then
    suppress_output=false
else
    suppress_output=true
fi

# Run discovery script to update the hostfile, conditionally suppressing internal command output
if $suppress_output; then
    echo "Discovering nodes and updating $hostfile..."
    dscvrndes "$hostfile" > /dev/null 2>&1
else
    echo "Discovering nodes and updating $hostfile..."
    dscvrndes "$hostfile"
fi

# Call rootnodeaccess and rootsshnode with the same hostfile parameter, conditionally suppressing internal command output
if $suppress_output; then
    echo "Setting up access for root on remote nodes..."
    rootnodeaccess "$hostfile" > /dev/null 2>&1
    rootsshnode "$hostfile" > /dev/null 2>&1
else
    echo "Setting up access for root on remote nodes..."
    rootnodeaccess "$hostfile"
    rootsshnode "$hostfile"
fi

# Check if the current user is ec2-user
if [ "$username" == "ec2-user" ]; then
    # Compile the program
    clear
    # Print success message
    echo -e "You already exist on all the nodes\nBecause you are the main user!"
    exit 0  # Exit the script here if user is ec2-user
fi

# Run node user addition script, suppressing internal command output
if $suppress_output; then
    echo "Adding user $username to discovered nodes..."
    ndadwrp "$hostfile" "$username" > /dev/null 2>&1
else
    echo "Adding user $username to discovered nodes..."
    ndadwrp "$hostfile" "$username"
fi

echo "Setup complete!"

# Print success message
if [ "$username" != "ec2-user" ]; then
    clear
    echo -e "Successfully updated hostfile.\n$username (you, I hope) now exist on all the sub nodes.\nReady to run benchmarks and break stuff."
fi
