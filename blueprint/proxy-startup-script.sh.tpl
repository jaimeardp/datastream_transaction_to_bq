#!/bin/bash

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Get the private IP of this VM using the robust metadata server URL
LOCAL_IP_ADDR=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

# Use the variables passed in from Terraform
DB_ADDR="${db_ip}"
DB_PORT="${db_port}"

# Clear any existing NAT rules to ensure a clean state on every boot
iptables -t nat -F

# --- Add iptables rules for NAT ---

# PREROUTING: Change the destination of incoming packets to the Cloud SQL IP
iptables -t nat -A PREROUTING -p tcp --dport $DB_PORT -j DNAT --to-destination $DB_ADDR:$DB_PORT

# POSTROUTING: Change the source of outgoing packets to this VM's IP
iptables -t nat -A POSTROUTING -p tcp -d $DB_ADDR --dport $DB_PORT -j SNAT --to-source $LOCAL_IP_ADDR