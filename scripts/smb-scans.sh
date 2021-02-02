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
### NSE
if [ "$TPORT" -eq 4455 ]; then
  echo -e "##### Running	: NSE smb2"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb2*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb2_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-domains"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-domains" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-domains_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-groups"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-groups" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-groups_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-processes"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-processes" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-processes_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-services"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-services" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-services_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-sessions"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-sessions" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-sessions_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-shares"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-shares" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-shares_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-users"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-enum-users" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-enum-users_p""$TPORT"
  echo -e "##### Running	: NSE smb-mbenum"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-mbenum" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-mbenum_p""$TPORT"
  echo -e "##### Running	: NSE smb-os-discovery"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-os-discovery" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-os-discovery_p""$TPORT"
  echo -e "##### Running	: NSE smb-ls"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-ls" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-ls_p""$TPORT"
  echo -e "##### Running	: NSE smb-protocols"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-protocols" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-protocols_p""$TPORT"
  echo -e "##### Running	: NSE smb-brute"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-brute" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-brute_p""$TPORT"
  #echo -e "##### Running	: NSE smb-flood"
  #echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-flood" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-flood_p""$TPORT"
  echo -e "##### Running	: NSE smb-security-mode"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-security-mode" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-security-mode_p""$TPORT"
  echo -e "##### Running	: NSE smb-stats"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-server-stats" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-server-stats_p""$TPORT"
  echo -e "##### Running	: NSE smb-system-info"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-system-info" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-system-info_p""$TPORT"
  echo -e "##### Running	: NSE smb-vuln*"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-vuln*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-vuln_p""$TPORT"
  echo -e "##### Running	: NSE smb-vuln-cve-2017-7494 script-args "
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-vuln-cve-2017-7494" --script-args "smb-vuln-cve-2017-7494.check-version" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-vuln-cve-2017-7494_script-args_p""$TPORT"
  echo -e "##### Running	: NSE smb-vuln-ms10-054 --script-args unsafe"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb-vuln-ms10-054" --script-args "unssafe" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb-vuln-ms10-054_script-args_unsafe_p""$TPORT"
elif [ "$TPORT" -eq 139 ]; then
  echo -e "##### Running	: NSE smb2"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "smb2*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_smb2_p""$TPORT"
  echo -e "##### Running	: NSE smb-enum-domains"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-domains" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-domains_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-enum-groups"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-groups" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-groups_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-enum-processes"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-processes" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-processes_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-enum-services"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-services" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-services_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-enum-sessions"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-sessions" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-sessions_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-enum-shares"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-shares" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-shares_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-enum-users"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-enum-users" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-enum-users_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-os-discovery"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-os-discovery" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-os-discovery_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-protocols"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-protocols" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-protocols_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-brute"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-brute" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-brute_p_T""$TPORT""_U137"
  #echo -e "##### Running	: NSE smb-flood"
  #echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-flood" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-flood_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-security-mode"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-security-mode" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-security-mode_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-server-stats"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-server-stats" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-server-stats_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-system-info"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-system-info" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-system-info_p_T""$TPORT""_U137"
  echo -e "##### Running	: NSE smb-vuln"
  echo "$PASS" | sudo -S nmap -sU -sS -p U:137,T:139 --script "smb-vuln*" "$IP" -oA "$IP""_nmap_tcp_sU_sS_nse_smb-vuln_p_T""$TPORT""_U137"
else
  echo "Unusual port. Modify this script"
fi

### enum4linux
echo -e "##### Running	: enum4linux -a"
enum4linux -a "$IP" > "$IP""_enum4linux_a_p""$TPORT"".txt" 

### nmblookup to query NetBIOS names
echo -e "##### Running	: nmblookup"
nmblookup -A "$IP" > "$IP""_nmblookup_A_p""$TPORT"".txt"

### nbtscan to scan NetBIOS name servers
echo -e "##### Running	: nbtscan"
nbtscan "$IP" > "$IP""_nbtscan_p""$TPORT"".txt"

### SMBMAP to enumerate samba share drives across a domain
echo -e "##### Running	: smbmap"
smbmap -H "$IP" -P "$TPORT" > "$IP""_smbmap_p""$TPORT"".txt"

### smbclient to talk to SMB server
echo -e "##### Running	: smbclient"
echo "" | smbclient -L "$IP" > "$IP""_smbclient_p""$TPORT"".txt" 

### rpcclient to open an unauthenticated session
echo -e "##### Running	: rpcclient -a"
rpcclient -p "$TPORT" -U "" -N "$IP" > "$IP""_rpcclient_unauthenticated_p""$TPORT"".txt"

