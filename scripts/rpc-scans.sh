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
# Metasploit resource file name
RPC_RSC=""

# At this point, we should already be in the target IP directory
# Create a subdirectory here, if needed, make sure to include service and port number

#---- VERIFY CLI INPUT -----#
# 3 arguments required (IP, port, scan type)
if [ "$#" -eq 3 ]; then
  IP="$1"
  TPORT="$2"
  if [[ "$3" != "rpc" ]]; then
    echo "##### $3 is not expected enum type	: rpc"
    exit 0	
  else
    ENUM="$3"
    echo -e "##### Running	: $0\n##### IP	: $IP\n##### Port	: $TPORT\n##### Enum	: $ENUM"
  fi
else
  echo "##### USAGE: bash $0 <IP Address> <Port> rpc"
  exit 0
fi

#----- ENUMERATE -----#
# impacket
echo -e "##### Running	: impacket rpcdump.py"
impacket-rpcdump -p "$TPORT" "$IP" > "$IP""_impacket-rpcdump_rpc_p""$TPORT"".txt"

# metasploit
echo -e "##### Creating	: rpc metsasploit resource script "
RPC_RSC="rpc-resource_$IP""_p""$TPORT"".rc"
touch "$RPC_RSC"
echo "setg rhosts $IP" >> "$RPC_RSC"
echo "use auxiliary/scanner/dcerpc/endpoint_mapper" >> "$RPC_RSC"
echo "exploit" >> "$RPC_RSC"
echo "use auxiliary/scanner/dcerpc/hidden" >> "$RPC_RSC"
echo "exploit" >> "$RPC_RSC"
echo "use auxiliary/scanner/dcerpc/management" >> "$RPC_RSC"
echo "exploit" >> "$RPC_RSC"
echo "use auxiliary/scanner/dcerpc/tcp_dcerpc_auditor" >> "$RPC_RSC"
echo "exploit" >> "$RPC_RSC"
echo "exit" >> "$RPC_RSC"

# Run metasploit
# NOTE: This is not run as sudo
echo -e "##### Running	: rpc metsasploit resource script "
msfconsole -q -r "$RPC_RSC" -o "$IP""_metasploit-rpc_p""$TPORT"".txt"

