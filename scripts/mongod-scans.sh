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
  if [[ "$3" != "mongod" ]]; then
    echo "##### $3 is not expected enum type	: mongod"
    exit 0	
  else
    ENUM="$3"
    echo -e "##### Running	: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
  fi
else
  echo "##### USAGE: bash $0 <IP Address> <Port> mongod"
  exit 0
fi

#----- ENUMERATE -----#
echo -e "##### Running	: NSE mongod"
echo "$PASS" | sudo -S nmap -p"$TPORT" --script "*mongod*" "$IP" -oA "$IP""_nmap_tcp_sS_nse_mongod_p""$TPORT"
