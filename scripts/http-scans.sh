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
WRD_LSTS_GOBUSTER="/home/kali/GitWorkspace/oscpPrep/cfgs/discover-webdirs-gobuster.txt"
WRD_LSTS_FFUF="/home/kali/GitWorkspace/oscpPrep/cfgs/discover-webdirs-ffuf.txt"
# Seclist of web extensions
SECLIST_WEBEXT="/home/kali/GitWorkspace/oscpPrep/cfgs/web-extensions.txt"
# Brute forced directories/files filenme
BRUTED_ALL=""
# A list of web extensions, separated by commas
WEBX_LST=""
# Directory name for screenshots
SCREENSHOTS_DIR=""
# Directory name for parent wget source code files
WGET_DIR=""
# Temporary file
TMP=""
# HTTP status codes filename
HTTP_CODES="http-status-codes"

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
  echo -e "##### Created	: $SCREENSHOTS_DIR"
fi
# Directory name for parent wget source code files
WGET_DIR="wget_sourceCodes_p""$TPORT"
if [ ! -d "$WGET_DIR" ]; then
  mkdir "$WGET_DIR"
  echo -e "##### Created	: $WGET_DIR"
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

#----- MANUAL ENUMERATION -----#
# check for file extensions

#----- GENERAL SCANNING -----#
### Nikto ###
echo -e "##### Running	: Nikto all plugins"
nikto -h "$IP" -p "$TPORT" -C all -Plugins @@ALL -Save "nikto_requestResponse_p""$TPORT" -output "$IP""_nikto_cAll_plugins-all_p""$TPORT"".txt"

### Whatweb ###
echo -e "##### Running	: Whatweb aggression 4 verbose"
whatweb -a 4 "$IP"":""$TPORT" --log-verbose="$IP""_whatweb_aggression4_verbose_p""$TPORT"".txt" 

### Wapiti ###
echo -e "##### Running	: Wapiti all modules"
wapiti -u "http://""$IP"":""$TPORT""/" -m "backup,blindsql,buster,crlf,exec,file,htaccess,methods,nikto,permanentxss,redirect,shellshock,sql,ssrf,xss,xxe" --color -v 2 -f txt -o "$IP""_wapiti_color_verbose2_txt_p""$TPORT"

### Nmap NSE ###
echo -e "##### Running	: NSE http"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "http-*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_http_p""$TPORT"

#----- BRUTE FORCE DIRS/FILES -----#

# GoBuster
while IFS= read -r line; do
  echo "##### Running	: GoBuster, wordlist=$line"
  gobuster dir -e -u "http://""$IP"":""$TPORT" -t 10 -w "$line" >> "$IP""_gobuster_p$TPORT.txt"
done < "$WRD_LSTS_GOBUSTER"

# Dirb recursive
echo -e "##### Running	: dirb recursive"
dirb http://"$IP"":""$TPORT" -o "$IP""_dirb_recursive_p""$TPORT"".txt"

# Ffuf
while IFS= read -r line; do
  echo -e "##### Running	: ffuf"
  nm=$(echo $line | awk -F"/" '{ print $NF }' | awk -F"." '{print $1}')
  cmd=$(head -n 1 $line)
  if [ "$cmd" == "/" ]; then
    ffuf -w "$line" -u "http://""$IP"":""$TPORT""FUZZ" -recursion -recursion-depth 2 -r -c -v -e "$WEBX_LST" -o "$IP""_ffuf_wl_""$nm""_p""$TPORT"".json"
  else
    ffuf -w "$line" -u "http://""$IP"":""$TPORT""/FUZZ" -recursion -recursion-depth 2 -r -c -v -e "$WEBX_LST" -o "$IP""_ffuf_wl_""$nm""_p""$TPORT"".json"
  fi
done < "$WRD_LSTS_FFUF"

#----- FIND ALL DIFFERENT STATUS CODES -----#
echo -e "##### Running	: Finding all HTTP status codes"
cat *dirb*p"$TPORT"".txt" | grep "CODE:" | awk -F"CODE:" '{print $NF}' | awk -F"|" '{print $1}' | sort | uniq >> "$HTTP_CODES" 
cat *gobuster*p"$TPORT"".txt" | grep "^http://" | awk -F" " '{print $NF}' | sed 's/)//g' | sort | uniq >> "$HTTP_CODES"
cat *ffuf*p"$TPORT"".json" | jq '.results[]| .status' | sort | uniq >> "$HTTP_CODES" 
TMP="tmp-http-status_p$TPORT.txt"
cat "$HTTP_CODES" | sort | uniq >> "$TMP"
cat "$TMP" > "$HTTP_CODES"
rm "$TMP"

#----- SORT OUT THE HTTP STATUS CODES -----#
echo -e "##### Running	: Sorting HTTP Statuses"
BRUTED_ALL="bruted_http-status-all_p""$TPORT"
while IFS= read -r line; do
  OUT="bruted_http-status-""$line""_p$TPORT"
  cat *gobuster_p$TPORT.txt | grep "Status: $line)$" | sort | uniq | awk -F" " '{ print $1 }' >> "$OUT"
  cat *dirb*p"$TPORT"".txt" | grep "^+" | grep "CODE:$line" | sort | uniq | awk -F" " '{ print $2 }' >> "$OUT" 
  cat *ffuf*_p"$TPORT".json | jq '.results[] | [.status,.url] | join (" ")' | sed 's/"//g' | grep "^$line" | sort | uniq | awk -F" " '{print $2}' >> "$OUT"
  TMP="tmp-bruted-http-status-$line""_p$TPORT.txt"
  cat "$OUT" | sort | uniq >> "$TMP"
  cat "$TMP" > "$OUT"
  cat "$OUT" >> "$BRUTED_ALL"
  rm "$TMP"
done < "$HTTP_CODES"

#----- TAKE SCREENSHOTS OF ALL BRUTE FORCED DIRECTORIES -----#
echo "##### Running	: Taking screenshots..."
TMP="tmp-screenshots_p$TPORT.txt"
if [ -s "$BRUTED_ALL" ]; then
  for h in $(cat "$BRUTED_ALL"); do (firefox -P takeScreenshots --screenshot $(echo "$h" | awk -F"http://" '{print $2}' | tr '//' '-' | tr '.' '_' | awk -F" " '{ print $1".png"}') "$h" ); done
else
  firefox -P takeScreenshots --screenshot $(echo "$IP:$TPORT" | awk -F"http://" '{print $2".png"}') "$h"
fi
mv *.png "$SCREENSHOTS_DIR"

#----- DOWNLOAD SOURCE OF ALL BRUTED DIRECTORIES -----#
if [ -s "$BRUTED_ALL" ]; then
  wget -i "$BRUTED_ALL" --save-headers -xattr -o "wget_source_p$TPORT.txt" -S -r -l 1 -np -P "$WGET_DIR"
else
  wget "http://$IP:$TPORT" --save-headers -xattr -o "wget_source_p$TPORT.txt" -S -r -l 1 -np -P "$WGET_DIR"
fi

#----- TEST FOR HEAD CONTROL BYPASS -----#
# For all the 302 directs, trying using HEAD instead of GET, then check for status 200
