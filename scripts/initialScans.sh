#!/bin/bash

source /home/kali/Documents/mypass.sh

<<COMMENT
#-- SCANS FOR A SINGLE TARGET--#
-INPUT		: the target's IP address
-PURPOSE	: scan each IP with each script before moving on to next scan
-OUTPUT		: place a results file for each scan into a folder named after the IP

USAGE		: bash $0 <IP Address>
COMMENT

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

echo "##### Running $0 on $IP ..."


### Create target IP dir if necessary, then change to that dir 
cd "$SCANS_DIR"
if [ ! -d "$IP_DIR" ]; then
  mkdir "$IP_DIR"
  echo "##### Created $IP_DIR"
fi
cd "$IP_DIR"


### TCP Scans
echo -e "\n\n#TCP# 1. Running SYN Stealth, reason, verbose"
echo "$PASS" | sudo -S nmap -p- --reason -v -oA "$IP""_nmap_tcp_sS_reason_verbose" "$IP"
echo -e "\n\n#TCP# 2. Running: SYN Stealth, host discovery disabled"
echo "$PASS" | sudo -S nmap -Pn -p- --reason -oA "$IP""_nmap_tcp_sS_Pn_reason" "$IP"
echo -e "\n\n#TCP# 2. Running: SYN ACK, verbose. For firewall discovery"
echo "$PASS" | sudo -S nmap -sA -p- -v -oA "$IP""_nmap_tcp_sA_v" "$IP"

# Get only the TCP port numbers
TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
echo -e "\n\n##### TCP_PORTS: $TCP_PORTS"

# Scan only the ports identified by previous nmap scans
echo -e "\n\n#TCP# 3. Running: SYN Stealth, version detection intensity 9"
echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -sV --version-intensity 9 -oA "$IP""_nmap_tcp_sS_sV_intensity9" "$IP"
echo -e "\n\n#TCP# 4. Running: Syn Stealth, aggressive scan" 
echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -A -oA "$IP""_nmap_tcp_sS_A" "$IP"
echo -e "\n\n#TCP# 5. Running: NSE scripts"
echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --script default,safe,auth,vuln -oA "$IP""_nmap_tcp_sS_nseDefaultSafeAuthVuln" "$IP"


### UDP Scans
echo -e "\n\n#UDP# 1. Running UDP defeat-icmp-ratelimit"
echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit -oA "$IP""_nmap_udp_sU_defIcmpRateLimit" "$IP" 

# Get only the port numbers
UDP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*udp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')

if [[ "$UDP_PORTS" != *"empty"* ]]; then
  echo -e "\n\n##### UDP_PORTS: $UDP_PORTS"
  echo -e "\n\n#UDP# 1. Running UDP, verbose, reason"
  echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -v --reason -oA "$IP""_nmap_udp_sU_v_reason" "$IP" 
  echo -e "\n\n#UDP# 3. Running: UDP, version detection intensity 9"
  echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -sV --version-intensity 9 -oA "$IP""_nmap_udp_sU_sV_intensity9" "$IP"
  echo -e "\n\n#UDP# 4. Running: UDP, aggressive scan" 
  echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -A -oA "$IP""_nmap_udp_sU_A" "$IP"
  echo -e "\n\n#UDP# 2. Running: NSE scripts"
  echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln -oA "$IP""_nmap_udp_sU_nseDefaultSafeAuthVuln" "$IP"
fi
