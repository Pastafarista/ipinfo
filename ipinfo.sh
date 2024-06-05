#!/bin/bash
# Description: Get information from an IP and CIDR
# Author: Antonio

# colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
TURQUOISE="\033[1;96m"
NC="\033[0m"

# ctrl + c
trap ctrl_c INT

function ctrl_c(){
    echo -e "\n\n${RED}[!] Exiting...\n${NC}"
    exit 1
}

function help(){
    echo -e "\n${TURQUOISE}Usage:${NC}"
    echo -e "\t./ipinfo.sh x.x.x.x/x\n"
}

to_bin ()
{
    printf "%08d\n" $(dc -e "$1 2op")
}

function get_subnet_class() {
    cidr=$1
    
    # get subnet number
    power=$((32 - $cidr))
    power=$((power % 8))
    subnet_number=$( echo "2^8 - 2^{$power}" | bc)

    # get the subnet type
    if [ $cidr -gt 24 ]; then
        subnet_type="C"
    elif [ $cidr -gt 16 ]; then
        if [ $subnet_number -eq 255 ]; then
            subnet_type="C"
        else
            subnet_type="B"
        fi
    elif [ $cidr -gt 8 ]; then
        if [ $subnet_number -eq 255 ]; then
            subnet_type="B"
        else
            subnet_type="A"
        fi
    else
        if [ $subnet_number -eq 255 ] && [ $cidr -ne 0 ] ; then
            subnet_type="A"
        else
            subnet_type="N/A"
        fi
    fi

    echo $subnet_type
}

# get the arguments
while getopts "hi:" opt; do
    case $opt in
        h)
            help
            exit 0
            ;;
        *)
            help
            exit 1
            ;;
    esac
done

# get the ip address in the format x.x.x.x/x
ip_cidr=$1

# get the ip address
ip=$(echo $ip_cidr | cut -d'/' -f1)

# validate that the ip address is valid
rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'

if [[ ! $ip =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
    echo -e "\n${RED}[!] Invalid IP Address\n${NC}"
    exit 1
fi

# get the cidr
cidr=$(echo $ip_cidr | cut -d'/' -f2)

# validate that cidr is a number
if ! [[ $cidr =~ ^[0-9]+$ ]]; then
    echo -e "\n${RED}[!] CIDR must be a number\n${NC}"
    exit 1
fi

# conver cidr to integer
cidr=$((cidr))

# validate that the cidr is between 0 and 32
if [ $cidr -lt 0 ] || [ $cidr -gt 32 ]; then
    echo -e "\n${RED}[!] CIDR must be between 0 and 32\n${NC}"
    exit 1
fi

# get an array of the 4 octets of the ip address
IFS='.' read -r -a ip_dec <<< $ip

# calculate the subnet mask adding 1's to the left equal to the cidr
cont=0

for i in {0..3}; do
    octal=""

    for j in {1..8}; do
        if [ $cont -lt $cidr ]; then
            octal+="1"
        else
            octal+="0"
        fi

        let cont++
    done

    mask_dec[$i]=$(echo "ibase=2; $octal" | bc)
done

# calculate the network address array, by doing a bitwise AND between the ip address and the subnet mask
for i in {0..3}; do
    network_dec[$i]=$((${mask_dec[$i]} & ${ip_dec[$i]}))
    network_bin[$i]=$(to_bin ${network_dec[$i]})
done

# calculate the broadcast address array, by replacing the last bits of the host address with 1's
cont=0
for i in {0..3}; do
    octal=""
    
    for j in {0..7}; do
        if [ $cont -lt $cidr ]; then
            octal+="${network_bin[$i]:$j:1}"
        else
            octal+="1"
        fi

        let cont++
    done
    
    broadcast_dec[$i]=$(echo "ibase=2; $octal" | bc)
done

# calculate the number of hosts
num_hosts=$(echo "2^((32 - $cidr)) - 2" | bc)

if [ $num_hosts -lt 0 ]; then
    num_hosts=0
fi

subnet_type=$(get_subnet_class $cidr)

# print the results
echo -e "\n${TURQUOISE}IP Address:${NC} $ip"
echo -e "${TURQUOISE}CIDR:${NC} $cidr"
echo -e ${TURQUOISE}"Subnet Mask:${NC} $(echo ${mask_dec[@]} | tr ' ' '.')"
echo -e "${TURQUOISE}Subnet Type:${NC} $subnet_type"
echo -e "${TURQUOISE}Network Address:${NC} $(echo ${network_dec[@]} | tr ' ' '.')"
echo -e "${TURQUOISE}Broadcast Address:${NC} $(echo ${broadcast_dec[@]} | tr ' ' '.')"
echo -e "${TURQUOISE}Number of Hosts:${NC} $num_hosts"
