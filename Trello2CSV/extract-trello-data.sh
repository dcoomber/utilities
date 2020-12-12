#!/bin/bash

# A shell script to download and convert a Trello board to CSV
# Written by: David Coomber
# Last updated on: 12 December 2020
# -------------------------------------------------------

function usage {
    printf "\nA shell script to download and convert a Trello board to CSV\n\n"
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

if [ -z "$2" ]; then
    date_stamp=$(date +"%Y%m%d")
    config_file=$(basename "$CONFIG")
    download_file="${config_file%.*}_${date_stamp}.json"

    # clean-up prior download
    rm -rf "${download_file}"
else
    download_file="$2"
fi

if [ ! -f "${download_file}" ]; then
    # Download Trello board
    # Special thanks to https://stackoverflow.com/questions/31390311/is-there-a-way-to-export-an-entire-trello-board-as-json-via-api
    base_url="https://api.trello.com/1"
    boards_path="boards/${BOARD_ID}"
    auth="key=${API_KEY}&token=${TOKEN}"
    params1="fields=all&actions=all&action_fields=all&actions_limit=1000&cards=all"
    params2="card_fields=all&card_attachments=false&labels=all&lists=all&list_fields=all"
    params3="members=all&member_fields=all&checklists=all&checklist_fields=all&organization=false"
    url="${base_url}/${boards_path}?${auth}&${params1}&${params2}&${params3}"

    printf "${WARNING}Downloading Trello board to file: %s${NC}\n" "$download_file"

    curl --silent -o "${download_file}" "${url}"
else
    printf "${WARNING}Using existing Trello board download file: %s${NC}\n" "$download_file"
fi

# Retrieve card details, lookup list and label details from downloaded json
# Special thanks to https://gist.github.com/mgeh/8644a15a96759921505fd531a0cb8f2f
jq -r '
    (
        ["Short ID", "Item", "Background", "Short URL", "List", "Card Closed", "List Closed", "Label 1", "Label 2", "Label 3", "Label 4", "Label 5"], 
        (reduce .lists[] as $listName ({}; .[$listName.id] = $listName.name)) as $listNames | 
        (reduce .lists[] as $listStatus ({}; .[$listStatus.id] = $listStatus.closed)) as $listStatuses | 
        (reduce .labels[] as $labelName ({}; .[$labelName.id] = $labelName.name)) as $labelNames | 
        .cards[] | 
        [.idShort, .name, .desc, .shortUrl, $listNames[.idList], .closed, $listStatuses[.idList], $labelNames[.labels[].id]]
    ) | @csv' < "${download_file}"
