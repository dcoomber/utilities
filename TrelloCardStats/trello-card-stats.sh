#!/bin/bash

# A shell script to extract Trello card list movement dates
#   for Kanban stype reporting (lag, cycle, etc.)
# Written by: David Coomber
# Last updated on: 14 December 2020
# -------------------------------------------------------

function usage {
    printf "\nA shell script to extract Trello card list movement dates\n\n"
    printf "${WARNING}usage:${NC} %s config_file [input_file]\n" "$0"
    printf "  config_file       file containing Trello board specific detail\n"
    printf "  input_file        [optional] Trello board json file\n\n"
    exit 1
}

# printf formatting
#  https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
ERROR='\033[1;31m'    # Brown/Orange
WARNING='\033[1;33m'  # Yellow
NC='\033[0m'          # No Color

# load configuration file
CONFIG="$1"

    if [ -z "${CONFIG}" ]; then
    # shellcheck disable=SC2059
    printf "\n${ERROR}Missing required argument 'config_file'.${NC}\n"
    usage
fi

if [ ! -f "$CONFIG" ]; then
    printf "\n${ERROR}Configuration file not found at '%s'${NC}\n" "$CONFIG"
    usage
fi

# shellcheck disable=SC1090
source "${CONFIG}"

# Shared Trello URL variables
base_url="https://api.trello.com/1"
auth="key=${API_KEY}&token=${TOKEN}"

# Retrieve list of DONE cards
# TODO: Add filter to remove archived cards
IFS=', ' read -r -a list_array <<< "${DONE}}"


card_array=()

for list in "${list_array[@]}"
do
    lists_path="lists/${list}"
    url="${base_url}/${lists_path}/cards?${auth}"
    
    while IFS='' read -r item; do card_array+=("$item"); done < <(curl --silent "${url}" | jq -r .[].id)
done

# Compile card details
for card in "${card_array[@]}"
do
    echo "${card}"
done
