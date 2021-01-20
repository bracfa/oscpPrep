#!/bin/bash

source /home/kali/Documents/mypass.sh

<<COMMENT
#-- SCANS FOR A SINGLE TARGET--#
-INPUT		: the target's IP address
-PURPOSE	: scan each IP with each script before moving on to next scan
-OUTPUT		: place a results file for each scan into a folder named after the IP

USAGE		: bash $0 <IP Address>
COMMENT

# Array of different service scans
SCAN_ARR=(initial http ftp ssh)
# Target IP address
IP="$1"
# Target Port 
TARGET_PORT="$2"
# Attack machine password
PASS="$pass"
# Scans directory
SCANS_DIR="/home/kali/GitWorkspace/oscpPrep/scans/"
# Target IP directory
IP_DIR="$SCANS_DIR""$IP"
# Found TCP Ports
TCP_ARR=()
# Found UDP Ports
UDP_ARR=()
# TCP ports filename
TCP_FN="tcpPorts"
# UDP ports filename
UDP_FN="udpPorts"

echo "##### Running $0 on $IP ..."

# Check if CLI arguments are part of the service array
for arg in "$@"
do
  if [[ ${SCAN_ARR[*]} =~ "$arg" ]]
  then
    echo "##### Scan chosen: $arg"
  fi
done

# Change to the scans directory
cd "$SCANS_DIR"

# Create/verify the target IP directory exists
if [ ! -d "$IP_DIR" ]; then
  mkdir "$IP_DIR"
  echo "##### Created $IP_DIR"
fi

# Change to the directory for the target IP
cd "$IP_DIR"

## TCP Scans
echo -e "\n\n#TCP# 1. Running SYN Stealth, reason"
echo "$PASS" | sudo -S nmap -p- --reason -oA "$IP""_nmap_tcp_sS_reason" "$IP"
echo -e "\n\n#TCP# 2. Running: SYN Stealth, host discovery disabled"
echo "$PASS" | sudo -S nmap -Pn -p- --reason -oA "$IP""_nmap_tcp_sS_Pn_reason" "$IP"
# If there are other scans that reveal other ports, we'll have to add those

# At this point, perhaps we can parse only for open TCP ports, then continue scanning from there
#TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ' '")
TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
echo -e "\n\n##### TCP_PORTS: $TCP_PORTS"

echo -e "\n\n#TCP# 3. Running: SYN Stealth, version detection intensity 9"
#echo "$PASS" | sudo -S nmap -p- -sV --version-intensity 9 -oA "$IP""_nmap_tcp_sS_sV_intensity9" "$IP"
echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -sV --version-intensity 9 -oA "$IP""_nmap_tcp_sS_sV_intensity9" "$IP"
echo -e "\n\n#TCP# 4. Running: Syn Stealth, aggressive scan" 
#echo "$PASS" | sudo -S nmap -p- -A -oA "$IP""_nmap_tcp_sS_A" "$IP"
echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -A -oA "$IP""_nmap_tcp_sS_A" "$IP"
echo -e "\n\n#TCP# 5. Running: NSE scripts"
#echo "$PASS" | sudo -S nmap -p- --script default,safe,auth,vuln -oA "$IP""_tcp_sS_nseDefaultSafeAuthVuln" "$IP"
echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --script default,safe,auth,vuln -oA "$IP""_tcp_sS_nseDefaultSafeAuthVuln" "$IP"

exit 0
## UDP Scans
echo -e "\n\n#UDP# 1. Running UDP defeat-icmp-ratelimit"
echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit -oA "$IP""_udp_sU_defIcmpRateLimit" "$IP" 
# At this point, perhaps we can parse only for UDP ports, then continue scanning from there 
echo -e "\n\n#UDP# 2. Running: NSE scripts"
echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln -oA "$IP""_udp_sU_nseDefaultSafeAuthVuln" "$IP"
