#!/bin/bash

INPUT=$1

OUTPUT=data_cards.csv

# TODO: Automate download of Trello board

# Retrieve card details, lookup list and label details
# Special thanks to https://gist.github.com/mgeh/8644a15a96759921505fd531a0cb8f2f
cat ${INPUT} | jq -r '
    (
        ["Short ID", "Item", "Background", "Short URL", "Card Closed", "List", "List Closed", "Labels"], 
        (reduce .lists[] as $listName ({}; .[$listName.id] = $listName.name)) as $listNames | 
        (reduce .lists[] as $listStatus ({}; .[$listStatus.id] = $listStatus.closed)) as $listStatuses | 
        (reduce .labels[] as $labelName ({}; .[$labelName.id] = $labelName.name)) as $labelNames | 
        .cards[] | 
        [.idShort, .name, .desc, .shortUrl, .closed, $listNames[.idList], $listStatuses[.idList], $listStatuses[.labels[].id]]
    ) | @csv' > ${OUTPUT}