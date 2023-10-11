#!/bin/bash

# Create a Memory SWAP that equivalent of 50% of Memory RAM
# This was test on ubuntu. Primary was made to work with AWS
# use sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/frani/tools/main/create_swap.sh)"

# Get the amount of RAM in MB
ram_memory=$(free -m | awk '/^Mem:/{print $2}')

# Calculate the size of the swap memory (50% of RAM)
swap_size=$((ram_memory / 2))

# Create a file for swap memory using dd
sudo dd if=/dev/zero of=/swapfile bs=128M count=$((swap_size / 128))

# Set secure permissions for the file
sudo chmod 600 /swapfile

# Format the file as swap memory
sudo mkswap /swapfile

# Activate the swap memory
sudo swapon /swapfile

# Make the configuration permanent by adding an entry to the /etc/fstab file
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Display confirmation message
echo "Swap memory of ${swap_size} MegaBytes has been created and activated."
