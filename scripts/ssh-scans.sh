#!/bin/bash

source /home/kali/Documents/mypass.sh

<<COMMENT
#-- SCANS FOR A SINGLE TARGET--#
-INPUT		: the target's IP address, port and scan type
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
  if [[ "$3" != "ssh" ]]; then
    echo "##### $3 is not expected enum type	: ssh"
    exit 0	
  else
    ENUM="$3"
    echo -e "##### Running	: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
  fi
else
  echo "##### USAGE: bash $0 <IP Address> <Port> ssh"
  exit 0
fi

#----- ENUMERATE -----#
### NSE
#echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-v1 "$IP" -oA "$IP""_nmap_tcp_22_sshV1_p""$TPORT"
# TODO echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh2-enum-algos "$IP" -oA "$IP""_nmap_tcp_ssh2EnumAlgos_p""$TPORT"
# TODO echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-auth-methods --script-args="ssh.user=root" "$IP" -oA "$IP""_nmap_tcp_sshAuth_root_p""$TPORT"
#echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-brute "$IP" -oA "$IP""_nmap_tcp_22_sshBrute_""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-hostkey --script-args ssh_hostkey=all "$IP" -oA "$IP""_nmap_tcp_sS_nse_ssh-hostkey_all_p""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance --script-args 'ssh.usernames={"root"}, publickeys={"./id_rsa1.pub", "./id_rsa2.pub"}' "$IP" -oA "$IP""_nmap_tcp_sS_nse_ssh-publickey-acceptance_root_public_rsa1_rsa2_p""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance --script-args 'ssh.usernames={"root"}, ssh.privatekeys={"./id_rsa1.pub", "./id_rsa2.pub"}' "$IP" -oA "$IP""_nmap_tcp_sS_nse_ssh-publickey-acceptance_root_private_rsa1_rsa2_p""$TPORT"
