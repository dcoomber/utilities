#!/bin/bash

INPUT=$1

# TODO: Automate download of Trello board

# Retrieve card details, lookup list and label details
# Special thanks to https://gist.github.com/mgeh/8644a15a96759921505fd531a0cb8f2f
jq -r '
    (
        ["Short ID", "Item", "Background", "Short URL", "List", "Card Closed", "List Closed", "Label 1", "Label 2", "Label 3", "Label 4", "Label 5"], 
        (reduce .lists[] as $listName ({}; .[$listName.id] = $listName.name)) as $listNames | 
        (reduce .lists[] as $listStatus ({}; .[$listStatus.id] = $listStatus.closed)) as $listStatuses | 
        (reduce .labels[] as $labelName ({}; .[$labelName.id] = $labelName.name)) as $labelNames | 
        .cards[] | 
        [.idShort, .name, .desc, .shortUrl, $listNames[.idList], .closed, $listStatuses[.idList], $labelNames[.labels[].id]]
    ) | @csv' < "${INPUT}"