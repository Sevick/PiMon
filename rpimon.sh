#!/bin/bash

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

source "$SCRIPTPATH/.env"

HOST_NAME=$(hostname)

Temp=$(vcgencmd measure_temp | cut -f2 -d= | cut -f1 -d\')
Clockspeed=$(vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f",$2/1000000); }' )
Corespeed=$(vcgencmd measure_clock core | awk -F"=" '{printf ("%0.0f",$2/1000000); }' )
Health=$(vcgencmd get_throttled | awk -F"=" '{printf("0x%08x\n",$2)}')
CoreVolt=$(vcgencmd measure_volts | cut -f2 -d=)
ETH0RX=$(/sbin/ifconfig eth0 | grep "RX packets" | awk -F ' ' '{print $5}')
ETH0TX=$(/sbin/ifconfig eth0 | grep "TX packets" | awk -F ' ' '{print $5}')
WLAN0RX=$(/sbin/ifconfig wlan0 | grep "RX packets" | awk -F ' ' '{print $5}')
WLAN0TX=$(/sbin/ifconfig wlan0 | grep "TX packets" | awk -F ' ' '{print $5}')
WLAN0SIGNAL=$(/sbin/iwconfig wlan0 | grep -i --color quality | awk -F ' ' '{print $4}' | awk -F '=' '{print $2}')
Uptime=$(cat /proc/uptime | awk -F ' ' '{print $1}')
LoadAverage=$(cat /proc/loadavg | awk -F ' ' '{print $1}')
MemTotal=$(cat /proc/meminfo | grep MemTotal | awk -F ' ' '{print $2}')
MemAvailable=$(cat /proc/meminfo | grep MemAvailable | awk -F ' ' '{print $2}')
MemFree=$(cat /proc/meminfo | grep MemFree | awk -F ' ' '{print $2}')
MemUsed=$(/usr/bin/free | grep 'Mem' | awk -F ' ' '{print $3}')
SwapTotal=$(cat /proc/meminfo | grep SwapTotal | awk -F ' ' '{print $2}')
SwapFree=$(cat /proc/meminfo | grep SwapFree | awk -F ' ' '{print $2}')
SwapUsed=$(/usr/bin/free | grep 'Swap' | awk -F ' ' '{print $3}')
DiskReadSectors=$(/usr/bin/vmstat -D | grep "read sectors" | awk -F ' ' '{print $1}')
DiskWriteSectors=$(/usr/bin/vmstat -D | grep "written sectors" | awk -F ' ' '{print $1}')
DiskTotal1K=$(/usr/bin/df | grep /dev/root | awk -F ' ' '{print $2}')
DiskUsed=$(/usr/bin/df | grep /dev/root | awk -F ' ' '{print $3}')
DiskAvailable=$(/usr/bin/df | grep /dev/root | awk -F ' ' '{print $4}')
DiskSectorSize=$(cat /sys/block/mmcblk0/queue/physical_block_size)
CpuIdle=$(/usr/bin/vmstat | tail -1 | awk -F ' ' '{print $15}')
SshSessions=$(netstat | grep ssh | wc -l)


JSON_STRING=$( jq -n \
			--arg temp "$Temp" \
			--arg clockspeed "$Clockspeed" \
			--arg corespeed "$Corespeed" \
			--arg health "$Health" \
			--arg corevolt "$CoreVolt" \
			--arg eth0rx "$ETH0RX" \
			--arg eth0tx "$ETH0TX" \
			--arg wlan0rx "$WLAN0RX" \
			--arg wlan0tx "$WLAN0TX" \
			--arg wlan0signal "$WLAN0SIGNAL" \
			--arg uptime "$Uptime" \
			--arg loadavg "$LoadAverage" \
			--arg memtotal "$MemTotal" \
			--arg memavailable "$MemAvailable" \
			--arg memfree "$MemFree" \
			--arg memused "$MemUsed" \
			--arg swaptotal "$SwapTotal" \
			--arg swapfree "$SwapFree" \
			--arg swapused "$SwapUsed" \
			--arg diskread "$DiskReadSectors" \
			--arg diskwrite "$DiskWriteSectors" \
			--arg disktotal "$DiskTotal1K" \
			--arg diskused "$DiskUsed" \
			--arg diskavailable "$DiskAvailable" \
			--arg disksectorsize "$DiskSectorSize" \
			--arg cpuidle "$CpuIdle" \
			--arg sshsessions "$SshSessions" \
                  '{state: "OK", attributes: {temp: $temp, clockspeed: $clockspeed, corespeed: $corespeed, health: $health, corevolt: $corevolt, eth0rx: $eth0rx, eth0tx: $eth0tx, 
				  wlan0rx: $wlan0rx, wlan0tx: $wlan0tx, wlan0signal: $wlan0signal, uptime: $uptime, loadavg: $loadavg, memtotal: $memtotal, memavailable: $memavailable, memfree: $memfree, memused: $memused, swaptotal: $swaptotal, swapfree: $swapfree, swapused: $swapused, diskread: $diskread, diskwrite: $diskwrite, disktotal: $disktotal, diskused: $diskused, diskavailable: $diskavailable, disksectorsize: $disksectorsize, cpuidle: $cpuidle, sshsessions: $sshsessions}}' )


echo $JSON_STRING

curl -X POST -H "Authorization: Bearer $HASS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_STRING" \
  "http://$HASS_HOST/api/states/sensor.$HOST_NAME"

