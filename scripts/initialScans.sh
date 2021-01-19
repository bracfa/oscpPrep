#!/bin/bash

source /home/kali/Documents/mypass.sh

<<COMMENT
#-- SCANS FOR A SINGLE TARGET--#
-INPUT		: the target's IP address
-PURPOSE	: scan each IP with each script before moving on to next scan
-OUTPUT		: place a results file for each scan into a folder named after the IP

COMMENT

# Array of different service scans
SCAN_ARR=(initial http ftp ssh)
# Target IP address
IP="$1"
# Target Port 
PORT="$2"
# Attack machine password
PASS="$pass"
# Scans directory
SCANS_DIR="/home/kali/GitWorkspace/oscpPrep/scans/"
# Target IP directory
IP_DIR="$SCANS_DIR""$IP"

echo "##### Running $0 on $IP ..."

Check if CLI arguments are part of the service array
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

# TCP Scans
echo -e "\n\n#TCP# 1. Running SYN Stealth, reason"
echo "$PASS" | sudo -S nmap -p- --reason -oN "$IP""_nmap_sS_reason.nmap" "$IP"
echo -e "\n\n#TCP# 2. Running: SYN Stealth, host discovery disabled" 
echo "$PASS" | sudo -S nmap -Pn -p- --reason -oN "$IP""_nmap_sS_Pn_reason.nmap" "$IP"
echo -e "\n\n#TCP# 3. Running: SYN Stealth, version detection intensity 9"
echo "$PASS" | sudo -S nmap -p- -sV --version-intensity 9 -oN "$IP""_nmap_sS_sV_intensity9.nmap" "$IP"
echo -e "\n\n#TCP# 4. Running: Syn Stealth, aggressive scan" 
echo "$PASS" | sudo -S nmap -p- -A -oN "$IP""_nmap_sS_A.nmap" "$IP"
echo -e "\n\n#TCP# 5. Running: NSE scripts"
echo "$PASS" | sudo -S nmap -p- --script default,safe,auth,vuln -oN "$IP""_sS_nseDefaultSafeAuthVuln.nmap" "$IP"

# UDP Scans
echo -e "\n\n#UDP# 1. Running UDP defeat-icmp-ratelimit"
echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit -oN "$IP""_sU_defIcmpRateLimit.nmap" "$IP" 
echo -e "\n\n#UDP# 2. Running: NSE scripts"
echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln -oN "$IP""_sU_nseDefaultSafeAuthVuln.nmap" "$IP"
