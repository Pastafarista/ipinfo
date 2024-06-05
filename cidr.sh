#!/bin/bash

# bc alias
alias bc='bc -l ~/.config/bcinit'

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
    echo -e "\t./cidr.sh <cidr>"
}

function info_subnet(){
    # get the cidr
    cidr=$1
    
    # get the number of posible hosts in the subnet
    number_of_ceros=$(echo "(32 - ${cidr})" | bc)
    number_hosts=$(echo "2^${number_of_ceros} - 2" | bc)
    
    # check if number_hosts is less than 0
    if [ $number_hosts -lt 0 ]; then
        number_hosts=0
    fi

    # subnet number
    subnet_number=$( echo "2^8 - 2^(mod($number_of_ceros,8))" | bc -l ~/.config/bcinit)

    # get the subnet type
    if [ $cidr -gt 24 ]; then
        mask="255.255.255.${subnet_number}"
        
        # get the subnet type
        subnet_type="C"
    elif [ $cidr -gt 16 ]; then
        mask="255.255.${subnet_number}.0"
        
        # get the subnet type
        if [ $subnet_number -eq 255 ]; then
            subnet_type="C"
        else
            subnet_type="B"
        fi
    elif [ $cidr -gt 8 ]; then
        mask="255.${subnet_number}.0.0"

        # get the subnet type
        if [ $subnet_number -eq 255 ]; then
            subnet_type="B"
        else
            subnet_type="A"
        fi
    else
        mask="${subnet_number}.0.0.0"

        # get the subnet type
        if [ $subnet_number -eq 255 ]; then
            subnet_type="A"
        else
            subnet_type="N/A"
        fi
    fi

    # print subnet info
    echo -e "\n${TURQUOISE}[*] Subnet info:${NC}"
    echo -e "\t${YELLOW}CIDR:${NC} ${cidr}"
    echo -e "\t${YELLOW}Number of hosts:${NC} ${number_hosts}"
    echo -e "\t${YELLOW}Subnet type:${NC} ${subnet_type}"
    echo -e "\t${YELLOW}Mask:${NC} ${mask}"
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

# get the cidr
cidr=$1

# check if ip_cidr is empty
if [ -z $cidr ]; then
    help
    exit 1
fi

# validate cidr is a number
if ! [[ $cidr =~ ^[0-9]+$ ]]; then
    echo -e "${RED}[!] CIDR must be a number${NC}"
    exit 1
fi

# validate cidr is between 0 and 32
if [ $cidr -lt 0 ] || [ $cidr -gt 32 ]; then
    echo -e "${RED}[!] CIDR must be between 0 and 32${NC}"
    exit 1
fi

# run the program
info_subnet $cidr
