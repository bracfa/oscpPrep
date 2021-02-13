#!/bin/bash

source /home/kali/Documents/mypass.sh
source /home/kali/GitWorkspace/oscpPrep/cfgs/enum-types.sh

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
# Enumeration array of types
ENUM_ARR=("${enum_types[@]}")
# Scans directory
SCANS_DIR="/home/kali/GitWorkspace/oscpPrep/scans/"
# Target IP directory
IP_DIR=""

#---- VERIFY CLI INPUT -----#
# 1 argument (IP address) or 3 arguments (IP, port, scan type)
if [ "$#" -eq 1 ]; then
  IP="$1"
  echo -e "##### Running	: $0\n##### IP	: $IP"
elif [ "$#" -eq 3 ]; then
  IP="$1"
  TPORT="$2"
  if [[ " ${ENUM_ARR[*]} " != *"$3"* ]]; then
    echo "##### $3 not a valid enum type."
    echo "##### Valid enum types: ${ENUM_ARR[*]}"
    exit 0	
  else
    ENUM="$3"
  fi
  echo -e "##### Running	: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
else
  echo "##### USAGE (default)	: bash $0 <IP Address>"
  echo "##### USAGE (specific)	: bash $0 <IP Address> <Port> <Enum Type>"

  # Print out the different enum types
  echo -e  "\n##### Enum types	: ${ENUM_ARR[*]}"	
  exit 0
fi

#----- CREATE/CHANGE TO TARGET IP SCANS DIR -----# 
# Create directory for target's IP address
IP_DIR="$SCANS_DIR""$IP"
cd "$SCANS_DIR"
if [ ! -d "$IP_DIR" ]; then
  mkdir "$IP_DIR"
  echo -e "##### Created	: $IP_DIR"
fi
cd "$IP_DIR"

#----- INITIAL SCANS -----#
if [ "$#" -eq 1 ]; then
  ### TCP  ###
  # Scan for open ports
  echo -e "\n\n##### Running	: TCP SYN Stealth, reason, verbose"
  echo "$PASS" | sudo -S nmap -p- --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_reason_verbose"
  echo -e "\n\n##### Running	: TCP SYN Stealth, reason, host discovery disabled"
  echo "$PASS" | sudo -S nmap -Pn -p- --reason "$IP" -oA "$IP""_nmap_tcp_sS_Pn_reason"
  
  # Save the ports to a variable
  TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### TCP ports found: $TCP_PORTS"
  echo "$TCP_PORTS" > tcp_ports
  sleep 2

  # Scan only the open TCP ports  
  echo -e "\n\n##### Running	: TCP SYN Stealth, timing1, version detection intensity 9"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -sV -T1 --version-intensity 9 "$IP" -oA "$IP""_nmap_tcp_timing1_sS_sV_intensity9"
  echo -e "\n\n##### Running	: Syn Stealth, timing1, aggressive scan" 
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -A -T1 "$IP" -oA "$IP""_nmap_tcp_sS_timing1_A"
  echo -e "\n\n##### Running	: TCP SYN Stealth, NSE scripts"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --script default,safe,auth,vuln "$IP" -oA "$IP""_nmap_tcp_sS_nse_default-safe-auth-vuln"
  
  # Firewall detection 
  #echo -e "\n\n##### Running	: Syn Stealth, timing 1, reason" 
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -T1 --reason "$IP" -oA "$IP""_nmap_tcp_sS_reason_timing1"
  #echo -e "\n\n##### Running	: TCP FIN, reason, verbose"
  #echo "$PASS" | sudo -S nmap -sF -p"$TCP_PORTS" --reason -v "$IP" -oA "$IP""_nmap_tcp_sF_reason_verbose"
  #echo -e "\n\n##### Running	: TCP SYN Stealth, source port 53 reason, verbose"
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -g53 --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_source-port53_reason_verbose"
  #echo -e "\n\n##### Running	: TCP SYN Stealth, source port 88, reason, verbose"
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -g88 --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_source-port88_reason_verbose"
  #echo -e "\n\n##### Running	: TCP SYN Stealth, fragmented, reason, verbose"
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -f --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_fragmented_reason_verbose"
  #echo -e "\n\n##### Running	: TCP SYN Stealth, mtu8, reason, verbose"
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --mtu 8 --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_mtu8_reason_verbose"
  #echo -e "\n\n##### Running	: TCP SYN Stealth, badsum, reason, verbose"
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --badsum --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_badsum_reason_verbose"
  
  # TCP Banner grabbing
  # netcat
  echo -e "\n\n##### Running	: TCP port nc banner grab ports $TCP_PORTS"
  for p in $(echo "$TCP_PORTS" | sed 's/,/\n/g'); do (echo "" | nc -nv -w 2 "$IP" "$p" >> "$IP""_nc_tcp_nv_w.txt" 2>&1); done   
  # Telnet
  # cURL

  ### UDP Port Scans ###
  # Scan for open ports
  echo -e "\n\n##### Running	: UDP defeat-icmp-ratelimit"
  echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit "$IP" -oA "$IP""_nmap_udp_sU_defeat-icmp-ratelimit"

  # Save the open ports to a variable
  UDP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*udp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### UDP ports found	: $UDP_PORTS"
  echo "$UDP_PORTS" > udp_ports

  if [ ! -z "$UDP_PORTS" ] ; then
    echo -e "\n\n##### Running	: UDP, verbose, reason, timing 1"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -T1 -v --reason "$IP" -oA "$IP""_nmap_udp_sU_v_reason_timing1"
    echo -e "\n\n##### Running	: UDP, verbose, reason"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -v --reason "$IP" -oA "$IP""_nmap_udp_sU_v_reason"
    echo -e "\n\n##### Running	: UDP, version detection intensity 9"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -sV --version-intensity 9 "$IP" -oA "$IP""_nmap_udp_sU_sV_intensity9"
    echo -e "\n\n##### Running	: UDP, aggressive scan" 
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -A "$IP" -oA "$IP""_nmap_udp_sU_A"
    echo -e "\n\n##### Running	: NSE scripts"
    echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln "$IP" -oA "$IP""_nmap_udp_sU_nse_default-safe-auth-vuln"
    
    # UDP  Banner grabbing
    # netcat
    echo -e "\n\n##### Running	: UDP port nc banner grab ports $UDP_PORTS"
    for p in $(echo "$UDP_PORTS" | sed 's/,/\n/g'); do (echo "" | nc -u -nv -w 2 "$IP" "$p" >> "$IP""_nc_udp_nv_w2.txt" 2>&1); done   
    # Telnet
    # cURL
  fi
#----- SPECIFIC SCANS -----#
else
  bash /home/kali/GitWorkspace/oscpPrep/scripts/"$ENUM"-scans.sh "$IP" "$TPORT" "$ENUM"
fi
