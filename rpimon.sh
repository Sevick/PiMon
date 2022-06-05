#!/bin/bash

source ./.env

HOST_NAME=$(hostname)

Temp=$(vcgencmd measure_temp | cut -f2 -d= | cut -f1 -d\')
Clockspeed=$(vcgencmd measure_clock arm | awk -F"=" '{printf ("%0.0f",$2/1000000); }' )
Corespeed=$(vcgencmd measure_clock core | awk -F"=" '{printf ("%0.0f",$2/1000000); }' )
Health=$(vcgencmd get_throttled | awk -F"=" '{printf("0x%08x\n",$2)}')
CoreVolt=$(vcgencmd measure_volts | cut -f2 -d=)
ETH0RX=$(ifconfig eth0 | grep "RX packets" | awk -F ' ' '{print $5}')
ETH0TX=$(ifconfig eth0 | grep "TX packets" | awk -F ' ' '{print $5}')
WLAN0RX=$(ifconfig wlan0 | grep "RX packets" | awk -F ' ' '{print $5}')
WLAN0TX=$(ifconfig wlan0 | grep "TX packets" | awk -F ' ' '{print $5}')
Uptime=$(cat /proc/uptime | awk -F ' ' '{print $1}')
LoadAverage=$(cat /proc/loadavg | awk -F ' ' '{print $1}')
MemTotal=$(cat /proc/meminfo | grep MemTotal | awk -F ' ' '{print $2}')
MemAvailable=$(cat /proc/meminfo | grep MemAvailable | awk -F ' ' '{print $2}')
MemFree=$(cat /proc/meminfo | grep MemFree | awk -F ' ' '{print $2}')
SwapTotal=$(cat /proc/meminfo | grep SwapTotal | awk -F ' ' '{print $2}')
SwapFree=$(cat /proc/meminfo | grep SwapFree | awk -F ' ' '{print $2}')
DiskReadSectors=$(vmstat -D | grep "read sectors" | awk -F ' ' '{print $1}')
DiskWriteSectors=$(vmstat -D | grep "written sectors" | awk -F ' ' '{print $1}')
DiskTotal1K=$(df | grep /dev/root | awk -F ' ' '{print $2}')
DiskUsed=$(df | grep /dev/root | awk -F ' ' '{print $3}')
DiskAvailable=$(df | grep /dev/root | awk -F ' ' '{print $4}')
CpuIdle=$(vmstat | tail -1 | awk -F ' ' '{print $15}')
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
			--arg uptime "$Uptime" \
			--arg loadavg "$LoadAverage" \
			--arg memtotal "$MemTotal" \
			--arg memavailable "$MemAvailable" \
			--arg memfree "$MemFree" \
			--arg swaptotal "$SwapTotal" \
			--arg swapfree "$SwapFree" \
			--arg diskread "$DiskReadSectors" \
			--arg diskwrite "$DiskWriteSectors" \
			--arg disktotal "$DiskTotal" \
			--arg diskused "$DiskUsed" \
			--arg diskavailable "$DiskAvailable" \
			--arg cpuidle "$CpuIdle" \
			--arg sshsessions "$SshSessions" \
                  '{state: "OK", attributes: {temp: $temp, clockspeed: $clockspeed, corespeed: $corespeed, health: $health, corevolt: $corevolt, eth0rx: $eth0rx, eth0tx: $eth0tx, 
				  wlan0rx: $wlan0rx, wlan0tx: $wlan0tx, uptime: $uptime, loadavg: $loadavg, memtotal: $memtotal, memavailable: $memavailable, memfree: $memfree, swaptotal: $swaptotal, swapfree: $swapfree, diskread: $diskread, diskwrite: $diskwrite, disktotal: $disktotal, diskused: $diskused, diskavailable: $diskavailable, cpuidle: $cpuidle, sshsessions: $sshsessions}}' )


echo $JSON_STRING

curl -X POST -H "Authorization: Bearer $HASS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$JSON_STRING" \
  http://192.168.1.16:8123/api/states/sensor.$HOST_NAME

