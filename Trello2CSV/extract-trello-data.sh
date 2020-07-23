#!/bin/bash

INPUT=$1

OUT_ACTIONS=data_actions.csv
OUT_CARDS=data_cards.csv
OUT_LABELS=data_labels.csv
OUT_LISTS=data_lists.csv
OUT_MEMBERS=data_members.csv

# TODO: Automate download of Trello board

# extract action detail
echo type,date,board_name,list_name,list_before,list_after,action_by > ${OUT_ACTIONS}
cat ${INPUT} | jq -r '.actions[] | [.type, .date, .data.board.name, .data.list.name, .data.listBefore.name, .data.listAfter.name, .memberCreator.fullName] | @csv' >> ${OUT_ACTIONS}

# extract the cards detail
echo id,item,background,short_id,short_url,list,label1,label2,label3,label4,label5,archived > ${OUT_CARDS}
cat ${INPUT} | jq -r '.cards[] | [.id, .name, .desc, .idShort, .shortUrl, .idList, .idLabels[0], .idLabels[1], .idLabels[2], .idLabels[3], .idLabels[4], .closed] | @csv' >> ${OUT_CARDS}

# extract labels detail
echo id,name > ${OUT_LABELS}
cat ${INPUT} | jq -r '.labels[] | [.id, .name] | @csv' >> ${OUT_LABELS}

# extract lists detail
echo id,name,archived > ${OUT_LISTS}
cat ${INPUT} | jq -r '.lists[] | [.id, .name, .closed] | @csv' >> ${OUT_LISTS}

# extract members detail
echo id,name > ${OUT_MEMBERS}
cat ${INPUT} | jq -r '.members[] | [.id, .fullName] | @csv' >> ${OUT_MEMBERS}
