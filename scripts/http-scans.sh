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
# Custom list of wordlists for http
WRD_LSTS="/home/kali/GitWorkspace/oscpPrep/cfgs/discover-webdirs.txt"
# Seclist of web extensions
SECLIST_WEBEXT="/home/kali/GitWorkspace/oscpPrep/cfgs/web-extensions.txt"
# Discovered directories through dirb and gobuster
DISCOVERED_DIRS_AND_FILES=""
# A list of web extensions, separated by commas
WEBX_LST=""
# Directory name for screenshots
SCREENSHOTS_DIR=""
# Directory name for parent wget source code files
WGET_DIR=""
# Temporary file
TMP=""


#---- VERIFY CLI INPUT -----#
# 3 arguments required (IP, port, scan type)
if [ "$#" -eq 3 ]; then
  IP="$1"
  TPORT="$2"
  if [[ "$3" != "http" ]]; then
    echo "##### $3 is not expected enum type: http"
    exit 0	
  else
    ENUM="$3"
    echo -e "##### Running	: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
  fi
else
  echo "##### USAGE	: bash $0 <IP Address> <Port> http"
  exit 0
fi

#----- CREATE SUBDIRECTORIES -----#
# At this point, we should already be in the target IP directory
# Directory name for screenshots
SCREENSHOTS_DIR="screenshots_p""$TPORT"
if [ ! -d "$SCREENSHOTS_DIR" ]; then
  mkdir "$SCREENSHOTS_DIR"
  echo -e "##### Created $SCREENSHOTS_DIR"
fi
# Directory name for parent wget source code files
WGET_DIR="wget_sourceCodes_p""$TPORT"
if [ ! -d "$WGET_DIR" ]; then
  mkdir "$WGET_DIR"
  echo -e "##### Created $WGET_DIR"
fi

#----- CREATE WEB EXTENSION LIST -----#
while read webx;
do
  if [[ -z "$WEBX_LST" ]]; then
    WEBX_LST="$webx"
  else
    WEBX_LST="$WEBX_LST,$webx"
  fi
done < "$SECLIST_WEBEXT"

#----- ENUMERATE -----#
### Manual enumeration  ###
# Look for file extensions

### Run NSE ###
# TODO http-passwd, http-put
echo -e "##### Running	: NSE http-auth-finder"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-auth-finder" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-auth-finder_p""$TPORT"
echo -e "##### Running	: NSE http-auth"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-auth" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-auth_p""$TPORT"
echo -e "##### Running	: NSE http-backup-finder"
echo "$PASS" | sudo -S nmap -p"$TPORT" -d --script "http-backup-finder" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-backup-finder_p""$TPORT"
echo -e "##### Running	: NSE http-config-backup"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-config-backup" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-config-backup_p""$TPORT"
echo -e "##### Running	: NSE http-cookie-flags"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-cookie-flags" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-cookie-flags_p""$TPORT"
echo -e "##### Running	: NSE http-default-accounts"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-default-accounts" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-default-accounts_p""$TPORT"
echo -e "##### Running	: NSE http-fileupload-exploiter"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-fileupload-exploiter" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-fileupload-exploiter_p""$TPORT"
echo -e "##### Running	: NSE http-form-brute"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-form-brute" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-form-brute_p""$TPORT"
echo -e "##### Running	: NSE http-rfi-spider"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-rfi-spider" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-rfi-spider_p""$TPORT"
echo -e "##### Running	: NSE http-server-header"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-server-header" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-server-header_p""$TPORT"
echo -e "##### Running	: NSE http-sql-injection"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-sql-injection" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http-sql-injection_p""$TPORT"


### Run Nikto ###
echo -e "##### Running	: nikto all plugins"
nikto -h "$IP" -p "$TPORT" -C all -Plugins @@ALL -Save "nikto_requestResponse_p""$TPORT" -output "$IP""_nikto_cAll_plugins-all_p""$TPORT"".txt"

 
### Discover Directories/Files ###
DISCOVERED_DIRS_AND_FILES="discovered_dirs_and_files_p$TPORT"

# Run dirb non-recursive
echo -e "##### Running	: dirb non-recursive"
dirb http://"$IP"":""$TPORT" -r -o "$IP""_dirb_nonRecursive_p""$TPORT"".txt"
#echo -e "##### Running: dirb recursive"
#dirb http://"$IP"":""$TPORT" -o "$IP""_dirb_recursive_p""$TPORT"".txt"
cat *dirb*p"$TPORT"".txt" | grep ^+ | sort | uniq | awk -F" " '{ print $2 }' >> "$DISCOVERED_DIRS_AND_FILES" 

# Run GoBuster
while IFS= read -r line; do
  echo "##### Running	: GoBuster, wordlist=$line"
  #gobuster dir -e -u "http://""$IP"":""$TPORT" -t 100 -x "$WEBX_LST" -w "$line" >> "$IP""_gobuster_p$TPORT.txt"
  gobuster dir -e -u "http://""$IP"":""$TPORT" -t 100 -w "$line" >> "$IP""_gobuster_p$TPORT.txt"
done < "$WRD_LSTS"
cat *gobuster_p$TPORT.txt | grep ^http | sort | uniq | awk -F" " '{ print $1 }' >> "$DISCOVERED_DIRS_AND_FILES"

### scan for headers ###

### Take screenshots ###
echo "##### Running	: Taking screenshots..."
TMP="tmp_p$TPORT.txt"
cat "$DISCOVERED_DIRS_AND_FILES" | sort | uniq -i  >> "$TMP"
cat "$TMP" > "$DISCOVERED_DIRS_AND_FILES"
rm "$TMP"
if [ -s "$DISCOVERED_DIRS_AND_FILES" ]; then
  for h in $(cat "$DISCOVERED_DIRS_AND_FILES"); do (cutycapt --url=$h --out=$(echo "$h" | awk -F"//" '{print $NF}' | tr '\/' '_' | tr '.' '_' | awk -F" " '{ print $NF".png"}')); done
else
  cutycapt --url="http://$IP:$TPORT" --out=$(echo "$IP:$TPORT" | tr '.' '_' | awk -F" " '{ print $NF".png"}')
fi
mv *.png "$SCREENSHOTS_DIR"

### Download source code ###
if [ -s "$DISCOVERED_DIRS_AND_FILES" ]; then
  wget -i "$DISCOVERED_DIRS_AND_FILES" -xattr -o "wget_source_p$TPORT.txt" -S -r -l 1 -np -P "$WGET_DIR"
else
  wget "http://$IP:$TPORT" -xattr -o "wget_source_p$TPORT.txt" -S -r -l 1 -np -P "$WGET_DIR"
fi
