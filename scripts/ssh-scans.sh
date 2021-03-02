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
# Better default password list
BETTER_DEFAULT="/usr/share/seclists/Passwords/Default-Credentials/ssh-betterdefaultpasslist.txt"
# Common SSH passwords
COMMON_SSH="/usr/share/seclists/Passwords/Common-Credentials/top-20-common-SSH-passwords.txt"
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
echo -e "##### Running	: ssh-audit"
python3 /home/kali/GitWorkspace/oscpPrep/downloadedScripts/ssh-audit/ssh-audit.py "$IP" > "$IP""_ssh-audit_p""$TPORT"".txt"
# TODO: Depending on the version, you might be able to do a policy scan
# python3 /home/kali/GitWorkspace/oscpPrep/downloadedScripts/ssh-audit -P ["policy name" | path/to/server_policy.txt] "$IP" > "$IP""_ssh-audit_policy_p""$TPORT"".txt"

echo -e "##### Running	: ssh-keyscan"
ssh-keyscan "$IP" -p "$TPORT" > "$IP""_ssh-keyscan_p""$TPORT"".txt" 2>&1

echo -e "##### Running	: sslscan"
sslscan --xml="$IP""_sslscan_ssh_p""$TPORT"".xml" "$IP"":""$TPORT"

echo -e "##### Running	: sslyze"
sslyze "$IP"":""$TPORT" > "$IP""_sslyze_ssh_p""$TPORT"".txt"

echo -e "##### Running	: hydra on user:pass list $BETTER_DEFAULT"
hydra -s "$TPORT" -C "$BETTER_DEFAULT" "$IP" -t 4 ssh > "$IP""_hydra_better-default-list-ssh_p""$TPORT"".txt"

echo -e "##### Running	: hydra on password list $COMMON_SSH"
hydra -s "$TPORT" -l root -P "$COMMON_SSH" "$IP" -t 4 ssh > "$IP""_hydra_common-ssh_p""$TPORT"".txt"

### NSE
echo "$PASS" | sudo -S nmap -p"$TPORT" --script sshv1 "$IP" -oA "$IP""_nmap_tcp_22_sshV1_p""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh2-enum-algos "$IP" -oA "$IP""_nmap_tcp_ssh2EnumAlgos_p""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-auth-methods "$IP" -oA "$IP""_nmap_tcp_sshAuth_root_p""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-hostkey --script-args ssh_hostkey=all "$IP" -oA "$IP""_nmap_tcp_sS_nse_ssh-hostkey_all_p""$TPORT"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance "$IP" -oA "$IP""_nmap_tcp_sS_nse_ssh-publickey-acceptance_p""$TPORT"

# TODO: What do we do with keys we find? Try NSE ssh-publickey-acceptance
# TODO: can we automate trying to use the known bad keys
# TODO: crackmapexec ssh --help. Can authenticate via kerberos?
# TODO: Run SSH just by itself with verbose. It should show debug info
# TODO: Force password method. ssh -v "$IP" -o PreferredAuthentications=password
# TODO: check config files: ssh_config, sshd_config, authorized_keys, ssh_known_hosts, known_hosts, id_rsa
# TODO: Get this to work https://packetstormsecurity.com/files/download/71252/sshfuzz.txt
# TODO: Metasploit auxiliary/fuzzers/ssh/ssh_version_2
# TODO: LibSSH versions 0.6 and above RCE. CVE-2018-10933
