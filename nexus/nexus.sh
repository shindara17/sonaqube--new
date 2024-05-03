#!/bin/bash

# Update package lists
sudo apt update

cd /opt

# Install Java (if not already installed)
sudo apt install openjdk-8-jre-headless -y

# Download Nexus Repository Manager
wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz

# Extract the downloaded file
tar -zxvf latest-unix.tar.gz

# Rename the extracted folder for simplicity (adjust the name if needed)
mv nexus-* nexus

# Move Nexus to a desired location (optional)
sudo mv nexus /opt/

# Create a symbolic link (optional, for convenience)
sudo ln -s /opt/nexus/bin/nexus /etc/init.d/nexus

# Start Nexus as a service
sudo /opt/nexus/bin/nexus start