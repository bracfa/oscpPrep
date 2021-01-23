#!/bin/bash

# TODO Fix default UDP when we come across a machine using UDP ports
# TODO Find a way to test for SSH version 1

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
# Enumeration array of types
ENUM_ARR=()
ENUM_ARR+=('ssh')
# Scans directory
SCANS_DIR="/home/kali/GitWorkspace/oscpPrep/scans/"
# Target IP directory
IP_DIR=""

#----- VERIFY CLI INPUT -----#
# 1 argument (IP address) or 3 arguments (IP, port, scan type)
if [ "$#" -eq 1 ]; then
  IP="$1"
  echo -e "##### Running: $0\n##### IP	: $IP"
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
  echo "##### USAGE (specific): bash $0 <IP Address> <Port> <Enum Type>"

  # Print out the different enum types
  echo -e  "\n##### Enum types: ${ENUM_ARR[*]}"	
  exit 0
fi

#----- CREATE/CHANGE TO TARGET IP SCANS DIR -----# 
IP_DIR="$SCANS_DIR""$IP"
cd "$SCANS_DIR"
if [ ! -d "$IP_DIR" ]; then
  mkdir "$IP_DIR"
  echo -e "\n\n##### Created $IP_DIR"
fi
cd "$IP_DIR"

#-----  DEFAULT TCP/UDP ENUM -----#
if [ "$#" -eq 1 ]; then
  # TCP Scans
  echo -e "\n\n#TCP# 1. Running SYN Stealth, reason, verbose"
  echo "$PASS" | sudo -S nmap -p- --reason -v -oA "$IP""_nmap_tcp_sS_reason_verbose" "$IP"
  echo -e "\n\n#TCP# 2. Running: SYN Stealth, host discovery disabled"
  echo "$PASS" | sudo -S nmap -Pn -p- --reason -oA "$IP""_nmap_tcp_sS_Pn_reason" "$IP"
  echo -e "\n\n#TCP# 3. Running: SYN ACK, verbose. For firewall discovery"
  echo "$PASS" | sudo -S nmap -sA -p- -v -oA "$IP""_nmap_tcp_sA_v" "$IP"

  TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### TCP_PORTS: $TCP_PORTS"

  echo -e "\n\n#TCP# 4. Running: SYN Stealth, version detection intensity 9"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -sV --version-intensity 9 -oA "$IP""_nmap_tcp_sS_sV_intensity9" "$IP"
  echo -e "\n\n#TCP# 5. Running: Syn Stealth, aggressive scan" 
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -A -oA "$IP""_nmap_tcp_sS_A" "$IP"
  echo -e "\n\n#TCP# 6. Running: NSE scripts"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --script default,safe,auth,vuln -oA "$IP""_nmap_tcp_sS_nseDefaultSafeAuthVuln" "$IP"

  # UDP Scans
  #echo -e "\n\n#UDP# 1. Running UDP defeat-icmp-ratelimit"
  #echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit -oA "$IP""_nmap_udp_sU_defIcmpRateLimit" "$IP" 

  #UDP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*udp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  #echo -e "\n\n##### UDP_PORTS:$UDP_PORTS"

  #if [ ! -z "$UDP_PORTS" ] ; then
  #  echo -e "\n\n#UDP# 1. Running UDP, verbose, reason"
  #  echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -v --reason -oA "$IP""_nmap_udp_sU_v_reason" "$IP" 
  #  echo -e "\n\n#UDP# 2. Running: UDP, version detection intensity 9"
  #  echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -sV --version-intensity 9 -oA "$IP""_nmap_udp_sU_sV_intensity9" "$IP"
  #  echo -e "\n\n#UDP# 3. Running: UDP, aggressive scan" 
  #  echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -A -oA "$IP""_nmap_udp_sU_A" "$IP"
  #  echo -e "\n\n#UDP# 4. Running: NSE scripts"
  #  echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln -oA "$IP""_nmap_udp_sU_nseDefaultSafeAuthVuln" "$IP"
fi

#----- SSH ENUM -----#
if [ "$ENUM" == "ssh" ]; then
  # NSE
  #echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-v1 "$IP" -oA "$IP""_nmap_tcp_22_sshV1_""$TPORT""_""$IP"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh2-enum-algos "$IP" -oA "$IP""_nmap_tcp_22_ssh2EnumAlgos_""$TPORT""_""$IP"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-auth-methods --script-args="ssh.user=root" "$IP" -oA "$IP""_nmap_tcp_22_sshAuth_root_""$TPORT""_""$IP"
  #echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-brute "$IP" -oA "$IP""_nmap_tcp_22_sshBrute_""$TPORT""_""$IP"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-hostkey --script-args ssh_hostkey=all "$IP" -oA "$IP""_nmap_tcp_22_sshHostkey_all_""$TPORT""_""$IP"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance --script-args 'ssh.usernames={"root"}, publickeys={"./id_rsa1.pub", "./id_rsa2.pub"}' "$IP" -oA "$IP""_nmap_tcp_22_sshPKA_root_public_rsa1_rsa2_""$TPORT""_""$IP"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance --script-args 'ssh.usernames={"root"}, ssh.privatekeys={"./id_rsa1.pub", "./id_rsa2.pub"}' "$IP" -oA "$IP""_nmap_tcp_22_sshHPKA_root_private_rsa1_rsa2_""$TPORT""_""$IP"
fi

echo "##### Completed: $0"
exit 0 


