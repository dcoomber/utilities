#!/bin/bash

# A shell script to extract Trello board list IDs
# Written by: David Coomber
# Last updated on: 14 December 2020
# -------------------------------------------------------

function usage {
    printf "\nA shell script to extract Trello board list IDs\n\n"
    printf "${WARNING}usage:${NC} %s config_file\n" "$0"
    printf "  config_file       file containing Trello board specific detail\n"
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

# Download Trello board
# Special thanks to https://stackoverflow.com/questions/31390311/is-there-a-way-to-export-an-entire-trello-board-as-json-via-api
base_url="https://api.trello.com/1"
boards_path="boards/${BOARD_ID}"
auth="key=${API_KEY}&token=${TOKEN}"
url="${base_url}/${boards_path}/lists?${auth}"

curl --silent "${url}" | jq -r '(["id", "name", "closed"]) as $keys | $keys, map([.[ $keys[] ]])[] | @csv' | sed 's/,/ ,/g' | sed 's/"//g' | column -t -s,
