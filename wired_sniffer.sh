#!/bin/bash

# Check if the script is being run with sudo privileges
if [[ $(id -u) -ne 0 ]]; then
    echo "This script requires sudo privileges. Please run with sudo."
    exit 1
fi

# Configuration
BRIDGE_NAME="br0"
CAPTURE_FILE="captured_packets.pcap"
ETH_ADAPTER_1="eth0"
ETH_ADAPTER_2="eth1"

# Capture file size limit in megabytes (25MB)
CAPTURE_FILE_SIZE_MB=25

# Function to start packet sniffing
start_sniffing() {
    echo "Starting packet sniffing..."

    # Enable promiscuous mode on Ethernet adapter 1 and 2
    ifconfig $ETH_ADAPTER_1 promisc
    ifconfig $ETH_ADAPTER_2 promisc

    # Create bridge interface
    brctl addbr $BRIDGE_NAME
    brctl stp $BRIDGE_NAME off
    ifconfig $BRIDGE_NAME up

    # Add Ethernet adapters to the bridge
    brctl addif $BRIDGE_NAME $ETH_ADAPTER_1
    brctl addif $BRIDGE_NAME $ETH_ADAPTER_2

    # Start packet capturing with tcpdump on the bridge interface
    # Limit capture file size to $CAPTURE_FILE_SIZE_MB MB
    tcpdump -i $BRIDGE_NAME -w $CAPTURE_FILE -C $CAPTURE_FILE_SIZE_MB &
    echo "Packet sniffing started. Capturing packets to $CAPTURE_FILE (up to $CAPTURE_FILE_SIZE_MB MB)"
}

# Function to stop packet sniffing
stop_sniffing() {
    echo "Stopping packet sniffing..."

    # Kill the tcpdump process
    killall tcpdump

    # Remove the bridge interface
    brctl delbr $BRIDGE_NAME
    echo "Packet sniffing stopped."

    # Disable promiscuous mode on Ethernet adapter 1 and 2
    ifconfig $ETH_ADAPTER_1 -promisc
    ifconfig $ETH_ADAPTER_2 -promisc
    echo "Promiscuous mode disabled."
}

# Main script logic
case "$1" in
    start)
        start_sniffing
        ;;
    stop)
        stop_sniffing
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
esac
