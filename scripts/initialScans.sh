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
# Enumeration array of types
ENUM_ARR=()
ENUM_ARR+=('ssh')
ENUM_ARR+=('http')
ENUM_ARR+=('mongod')
# Scans directory
SCANS_DIR="/home/kali/GitWorkspace/oscpPrep/scans/"
# Target IP directory
IP_DIR=""
# Screenshots directory
SCREEN_DIR=""
# Discovered directories (from dirb, gobuster)
DISCOVERED_DIRS=""

#----- FILE NAMES -----#
# Custom list of wordlists for http
WRD_LSTS="/home/kali/GitWorkspace/oscpPrep/cfgs/discover-webdirs.txt"
# Seclist of web extensions
SECLIST_WEBEXT="/home/kali/GitWorkspace/oscpPrep/cfgs/web-extensions.txt"
# Web extension list separated by commas
WEBX_LST=""
while read webx;
do
  if [[ -z "$WEBX_LST" ]]; then
    WEBX_LST="$webx"
  else
    WEBX_LST="$WEBX_LST,$webx"
  fi
done < "$SECLIST_WEBEXT"
# Filename for wget output
WGET_OUT=""

#---- VERIFY CLI INPUT -----#
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
# Create directory for target's IP address
IP_DIR="$SCANS_DIR""$IP"
cd "$SCANS_DIR"
if [ ! -d "$IP_DIR" ]; then
  mkdir "$IP_DIR"
  echo -e "##### Created $IP_DIR"
fi
cd "$IP_DIR"

# Create screenshots directory
SCREEN_DIR="$IP_DIR""/screenshots"
if [ ! -d "$SCREEN_DIR" ]; then
  mkdir "$SCREEN_DIR"
  echo -e "##### Created $SCREEN_DIR"
fi

# Create wget directory
WGET_DIR="$IP_DIR""/wgetDir"
if [ ! -d "$WGET_DIR" ]; then
  mkdir "$WGET_DIR"
  echo -e "##### Created $WGET_DIR"
fi


#-----  DEFAULT TCP/UDP ENUM -----#
if [ "$#" -eq 1 ]; then
  ### TCP Scans
  echo -e "\n\n#TCP# 1. Running SYN Stealth, reason, verbose"
  echo "$PASS" | sudo -S nmap -p- --reason -v "$IP" -oA "$IP""_nmap_tcp_sS_reason_verbose"
  echo -e "\n\n#TCP# 2. Running: SYN Stealth, host discovery disabled"
  echo "$PASS" | sudo -S nmap -Pn -p- --reason "$IP" -oA "$IP""_nmap_tcp_sS_Pn_reason"
  echo -e "\n\n#TCP# 3. Running: SYN ACK, verbose. For firewall discovery"
  echo "$PASS" | sudo -S nmap -sA -p- -v "$IP" -oA "$IP""_nmap_tcp_sA_v"

  TCP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*tcp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### TCP_PORTS: $TCP_PORTS"
  echo "$TCP_PORTS" > tcp_ports

  echo -e "\n\n#TCP# 4. Running: SYN Stealth, version detection intensity 9"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -sV --version-intensity 9 "$IP" -oA "$IP""_nmap_tcp_sS_sV_intensity9"
  #echo -e "\n\n#TCP# 5. Running: Syn Stealth, aggressive scan" 
  #echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" -A "$IP" -oA "$IP""_nmap_tcp_sS_A"
  echo -e "\n\n#TCP# 6. Running: NSE scripts"
  echo "$PASS" | sudo -S nmap -p"$TCP_PORTS" --script default,safe,auth,vuln "$IP" -oA "$IP""_nmap_tcp_sS_nseDefaultSafeAuthVuln"

  ### UDP Scans
  echo -e "\n\n#UDP# 1. Running UDP defeat-icmp-ratelimit"
  echo "$PASS" | sudo -S nmap -sU -p- --defeat-icmp-ratelimit "$IP" -oA "$IP""_nmap_udp_sU_defIcmpRateLimit"

  UDP_PORTS=$(xmllint --xpath "//port/@portid" *nmap*udp*.xml | sed 's/"//g' | awk -F"=" '{print $NF}' | sort -n | uniq | tr '\n' ',' | sed 's/.$//')
  echo -e "\n\n##### UDP_PORTS: $UDP_PORTS"
  echo "$UDP_PORTS" > udp_ports

  if [ ! -z "$UDP_PORTS" ] ; then
    echo -e "\n\n#UDP# 1. Running UDP, verbose, reason"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -v --reason "$IP" -oA "$IP""_nmap_udp_sU_v_reason"
    echo -e "\n\n#UDP# 2. Running: UDP, version detection intensity 9"
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -sV --version-intensity 9 "$IP" -oA "$IP""_nmap_udp_sU_sV_intensity9"
    echo -e "\n\n#UDP# 3. Running: UDP, aggressive scan" 
    echo "$PASS" | sudo -S nmap -sU -p"$UDP_PORTS" -A "$IP" -oA "$IP""_nmap_udp_sU_A"
    echo -e "\n\n#UDP# 4. Running: NSE scripts"
    echo "$PASS" | sudo -S nmap -sU -p- --script default,safe,auth,vuln "$IP" -oA "$IP""_nmap_udp_sU_nseDefaultSafeAuthVuln"
  fi
fi

#----- SSH ENUM -----#
if [ "$ENUM" == "ssh" ]; then
  ### NSE
  #echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-v1 "$IP" -oA "$IP""_nmap_tcp_22_sshV1_p""$TPORT"
  # TODO echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh2-enum-algos "$IP" -oA "$IP""_nmap_tcp_ssh2EnumAlgos_p""$TPORT"
  # TODO echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-auth-methods --script-args="ssh.user=root" "$IP" -oA "$IP""_nmap_tcp_sshAuth_root_p""$TPORT"
  #echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-brute "$IP" -oA "$IP""_nmap_tcp_22_sshBrute_""$TPORT"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-hostkey --script-args ssh_hostkey=all "$IP" -oA "$IP""_nmap_tcp_sshHostkey_all_p""$TPORT"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance --script-args 'ssh.usernames={"root"}, publickeys={"./id_rsa1.pub", "./id_rsa2.pub"}' "$IP" -oA "$IP""_nmap_tcp_sshPKA_root_public_rsa1_rsa2_p""$TPORT"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script ssh-publickey-acceptance --script-args 'ssh.usernames={"root"}, ssh.privatekeys={"./id_rsa1.pub", "./id_rsa2.pub"}' "$IP" -oA "$IP""_nmap_tcp_sshHPKA_root_private_rsa1_rsa2_p""$TPORT"
fi

#----- HTTP ENUM -----#
if [ "$ENUM" == "http" ]; then
  DISCOVERED_DIRS="discovered_dirs_p$TPORT"
  
  ### Run NSE
  echo -e "##### Running: NSE http-auth-finder"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-auth-finder" "$IP" -oA "$IP""_nmap_tcp_nse_httpAuthFinder_p""$TPORT"
  echo -e "##### Running: NSE http-auth"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-auth" "$IP" -oA "$IP""_nmap_tcp_nse_httpAuth_p""$TPORT"
  echo -e "##### Running: NSE http-backup-finder"
  echo "$PASS" | sudo -S nmap -p"$TPORT" -d --script "http-backup-finder" "$IP" -oA "$IP""_nmap_tcp_nse_httpBackupFinder_p""$TPORT"
  echo -e "##### Running: NSE http-config-backup"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-config-backup" "$IP" -oA "$IP""_nmap_tcp_nse_httpConfigBackup_p""$TPORT"
  echo -e "##### Running: NSE http-cookie-flags"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-cookie-flags" "$IP" -oA "$IP""_nmap_tcp_nse_httpCookieFlags_p""$TPORT"
  echo -e "##### Running: NSE http-default-accounts"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-default-accounts" "$IP" -oA "$IP""_nmap_tcp_nse_httpDefaultAccounts_p""$TPORT"
  echo -e "##### Running: NSE http-fileupload-exploiter"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-fileupload-exploiter" "$IP" -oA "$IP""_nmap_tcp_nse_httpFileUploadExploiter_p""$TPORT"
  echo -e "##### Running: NSE http-form-brute"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-form-brute" "$IP" -oA "$IP""_nmap_tcp_nse_httpFormBrute_p""$TPORT"
  echo -e "##### Running: NSE http-rfi-spider"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-rfi-spider" "$IP" -oA "$IP""_nmap_tcp_nse_http-rfi-spider_p""$TPORT"
  echo -e "##### Running: NSE http-server-header"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-server-header" "$IP" -oA "$IP""_nmap_tcp_nse_http-ServerHeader_p""$TPORT"
  echo -e "##### Running: NSE http-sql-injection"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-sql-injection" "$IP" -oA "$IP""_nmap_tcp_nse_http-SqlInjection_p""$TPORT"
  # TODO http-passwd, http-put
  # Parse out the discovered directories from nmap

  ### Run Nikto
  echo -e "##### Running: nikto all plugins"
  nikto -h "$IP" -p "$TPORT" -C all -Plugins @@ALL -Save "nikto_requestResponse_p""$TPORT" -output "$IP""_nikto_cAll_pluginsAll_p""$TPORT"".txt"
  # TODO Parse out the discovered directories from nikto
 
  ### Discover Directories
  # Run dirb
  echo -e "##### Running: dirb non-recursive"
  dirb http://"$IP"":""$TPORT" -r -o "$IP""_dirb_nonRecursive_p""$TPORT"".txt"
  #echo -e "##### Running: dirb recursive"
  #dirb http://"$IP"":""$TPORT" -o "$IP""_dirb_recursive_p""$TPORT"".txt"
  cat *dirb* | grep ^+ | sort | uniq | awk -F" " '{ print $2 }' >> "$DISCOVERED_DIRS" 

  # Run GoBuster
  while IFS= read -r line; do
    echo "##### Running: GoBuster, wordlist=$line"
    #gobuster dir -e -u "http://""$IP"":""$TPORT" -t 100 -x "$WEBX_LST" -w "$line" >> "$IP""_gobuster_p$TPORT.txt"
    gobuster dir -e -u "http://""$IP"":""$TPORT" -t 100 -w "$line" >> "$IP""_gobuster_p$TPORT.txt"
  done < "$WRD_LSTS"
  cat *gobuster_p$TPORT.txt | grep ^http | sort | uniq | awk -F" " '{ print $1}' >> "$DISCOVERED_DIRS"

  ### Once some directories are found, scan for specific file extensions and headers

  ### Take screenshots
  echo "##### Running: Taking screenshots..."
  cat "$DISCOVERED_DIRS" | sort | uniq -i  >> tmp.txt
  cat tmp.txt > "$DISCOVERED_DIRS"
  rm tmp.txt
  for h in $(cat "$DISCOVERED_DIRS"); do (cutycapt --url=$h --out=$(echo "$h" | awk -F"//" '{print $NF}' | tr '\/' '_' | tr '.' '_' | awk -F" " '{ print $NF".png"}')); done
  mv *.png "$SCREEN_DIR"

  ### Download source code using wget
  WGET_OUT="wgetOut_p$TPORT"
  wget -i "$DISCOVERED_DIRS" -xattr -o "$WGET_OUT" -S -r -l 2 -np -P "$WGET_DIR"
fi

#----- MONGODB -----#
if [ "$ENUM" == "mongod" ]; then
  echo -e "##### Running: NSE mongod"
  echo "$PASS" | sudo -S nmap -p"$TPORT" --script "*mongo*" "$IP" -oA "$IP""_nmap_tcp_nse_mongod_p""$TPORT"
fi
