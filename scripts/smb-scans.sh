#!/bin/bash

source /home/kali/Documents/mypass.sh

<<COMMENT
#-- SCANS FOR A SINGLE TARGET--#
-INPUT		: the target's IP address
-PURPOSE	: scan each IP with each script before moving on to next scan
-OUTPUT		: place a results file for each scan into a folder named after the IP

USAGE (default)	: bash $0 <IP Address>
USAGE (specific): bash $0 <IP Address> <Port> <Scan Type>	
COMMENT

#----- VARIABLES -----#
# Target IP address CLI input
IP=""
# Target Port CLI input
TPORT=""
# Enumeration CLI input
ENUM=""
# Attack machine password
PASS="$pass"

# At this point, we should already be in the target IP directory
# Create a subdirectory here, if needed, make sure to include service and port number

#---- VERIFY CLI INPUT -----#
# 3 arguments required (IP, port, scan type)
if [ "$#" -eq 3 ]; then
  IP="$1"
  TPORT="$2"
  if [[ "$3" != "smb" ]]; then
    echo "##### $3 is not expected enum type	: smb"
    exit 0	
  else
    ENUM="$3"
    echo -e "##### Running	: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
  fi
else
  echo "##### USAGE: bash $0 <IP Address> <Port> smb"
  exit 0
fi

#----- ENUMERATE -----#
### enum4linux
echo -e "##### Running	: enum4linux -a"
enum4linux -a "$IP" > "$IP""_enum4linux_a.txt" 

### nmblookup to query NetBIOS names
echo -e "##### Running	: nmblookup"
nmblookup -A "$IP" > "$IP""_nmblookup_A.txt"

### nbtscan to scan NetBIOS name servers
echo -e "##### Running	: nbtscan"
nbtscan "$IP" > "$IP""_nbtscan.txt"

### SMBMAP to enumerate samba share drives across a domain
echo -e "##### Running	: smbmap"
smbmap -H "$IP" -P "$TPORT" > "$IP""_smbmap_p""$TPORT"".txt"

### smbclient to talk to SMB server
echo -e "##### Running	: smbclient"
echo "" | smbclient -L "$IP" -p "$TPORT" > "$IP""_smbclient_p""$TPORT"".txt" 

### rpcclient to open an unauthenticated session
echo -e "##### Running	: rpcclient -a"
rpcclient -p "$TPORT" -U "" -N "$IP" -c "srvinfo;quit" > "$IP""_rpcclient_unauthenticated_p""$TPORT"".txt"

### NSE
if [ "$TPORT" -eq 445 ]; then
  echo -e "##### Running	: NSE smb2"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb2*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb2_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum_p""$TPORT"
  echo -e "##### Running	: NSE smb-vuln*"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-vuln*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-vuln_p""$TPORT"
elif [ "$TPORT" -eq 139 ]; then
  #echo -e "##### Running	: NSE smb2"
  #echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb2*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb2_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum*" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-vuln"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-vuln*" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-vuln_p_T""$TPORT""_U137"
else
  echo "Running	: Unusual port for smb. Modify this script"
fi

