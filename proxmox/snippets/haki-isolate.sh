#!/bin/bash
# Proxmox hookscript: isolate customer containers from each other on vmbr1.
# Isolated bridge ports can reach the gateway (the host) but not other isolated ports.
vmid=$1 phase=$2
if [[ $phase == post-start ]]; then
  for dev in /sys/class/net/veth"${vmid}"i*; do
    [[ -e $dev ]] && bridge link set dev "$(basename "$dev")" isolated on
  done
fi
exit 0
