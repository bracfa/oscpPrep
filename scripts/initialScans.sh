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
  echo -e "##### Running: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
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
  echo -e "##### Created $IP_DIR"
fi
cd "$IP_DIR"

#-----  DEFAULT TCP/UDP ENUM -----#
if [ "$#" -eq 1 ]; then
  ### TCP Scans
  echo -e "\n\n##### Running	: TCP SYN Stealth, reason, verbose"
  echo "$PASS" | sudo -S nmap -p- --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_reason_verbose"
  echo -e "\n\n##### Running	: TCP SYN Stealth, host discovery disabled"
  echo "$PASS" | sudo -S nmap -Pn -p- --reason "$IP" -oA "$IP""_nmap_tcp_sS_Pn_reason"
  #echo -e "\n\n##### Running: SYN ACK, verbose. For firewall discovery"
  #echo "$PASS" | sudo -S nmap -sA -p- -v "$IP" -oA "$IP""_nmap_tcp_sA_v"

  TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### TCP ports found: $TCP_PORTS"
  echo "$TCP_PORTS" > tcp_ports
  sleep 2

  echo -e "\n\n##### Running	: TCP SYN Stealth, version detection intensity 9"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -sV --version-intensity 9 "$IP" -oA "$IP""_nmap_tcp_sS_sV_intensity9"
  #echo -e "\n\n#TCP# 5. Running: Syn Stealth, aggressive scan" 
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -A "$IP" -oA "$IP""_nmap_tcp_sS_A"
  echo -e "\n\n##### Running	: TCP SYN Stealth, NSE scripts"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --script default,safe,auth,vuln "$IP" -oA "$IP""_nmap_tcp_sS_nse_default-safe-auth-vuln"

  ### UDP Scans
  echo -e "\n\n##### Running	: UDP defeat-icmp-ratelimit"
  echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit "$IP" -oA "$IP""_nmap_udp_sU_defeat-icmp-ratelimit"

  UDP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*udp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### UDP ports found	: $UDP_PORTS"
  echo "$UDP_PORTS" > udp_ports

  if [ ! -z "$UDP_PORTS" ] ; then
    echo -e "\n\n##### Running	: UDP, verbose, reason"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -v --reason "$IP" -oA "$IP""_nmap_udp_sU_v_reason"
    echo -e "\n\n##### Running	: UDP, version detection intensity 9"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -sV --version-intensity 9 "$IP" -oA "$IP""_nmap_udp_sU_sV_intensity9"
    echo -e "\n\n##### Running	: UDP, aggressive scan" 
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -A "$IP" -oA "$IP""_nmap_udp_sU_A"
    echo -e "\n\n##### Running	: NSE scripts"
    echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln "$IP" -oA "$IP""_nmap_udp_sU_nse_default-safe-auth-vuln"
  fi
else
  bash /home/kali/GitWorkspace/oscpPrep/scripts/"$ENUM"-scans.sh "$IP" "$TPORT" "$ENUM"
fi
