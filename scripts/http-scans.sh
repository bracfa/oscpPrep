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
# Brute forced directories/files
BRUTED=""
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

#----- MANUAL ENUMERATION -----#
# file extensions

#----- GENERAL SCANNING -----#

#----- BRUTE FORCE DIRS/FILES -----#
BRUTED="bruted_dirs_p$TPORT"

### Ffuf ###
while IFS= read -r line; do
  echo -e "#### Running	: ffuf"
  nm=$(echo $line | awk -F"/" '{ print $NF }' | awk -F"." '{print $1}')
  ffuf -c -w "$line" -u "http://""$IP"":""$TPORT""/FUZZ" -r -c -v -o "$IP""_ffuf_wl_""$nm""_p""$TPORT"".json"
  #cat "$IP""_ffuf_wl_""$nm""_p""$TPORT"".json"  | jq '.results[].url?' | sed 's/"//g' | sort | uniq >> "$BRUTED"
  cat *ffuf*.json | jq '.results[] | [.status,.url] | join (" ")' | sed 's/"//g' | grep "^200" | sort | uniq | awk -F" " '{print $NF}' >> "$BRUTED"
done < "$WRD_LSTS"

#----- TAKE SCREENSHOTS -----#
echo "##### Running	: Taking screenshots..."
TMP="tmp_p$TPORT.txt"
cat "$BRUTED" | sort | uniq -i  >> "$TMP"
cat "$TMP" > "$BRUTED"
rm "$TMP"
if [ -s "$BRUTED" ]; then
  for h in $(cat "$BRUTED"); do (cutycapt --url=$h --out=$(echo "$h" | awk -F"//" '{print $NF}' | tr '\/' '_' | tr '.' '_' | awk -F" " '{ print $NF".png"}')); done
else
  cutycapt --url="http://$IP:$TPORT" --out=$(echo "$IP:$TPORT" | tr '.' '_' | awk -F" " '{ print $NF".png"}')
fi
mv *.png "$SCREENSHOTS_DIR"

#----- DOWNLOAD SOURCE -----#
if [ -s "$BRUTED" ]; then
  wget -i "$BRUTED" -xattr -o "wget_source_p$TPORT.txt" -S -r -l 1 -np -P "$WGET_DIR"
else
  wget "http://$IP:$TPORT" -xattr -o "wget_source_p$TPORT.txt" -S -r -l 1 -np -P "$WGET_DIR"
fi
