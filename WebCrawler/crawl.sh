#!/bin/bash
# A shell script to crawl a website and return a list of
#   pages that do not contain the specified string
# Written by: David Coomber
# Last updated on: 1 May 2020
# -------------------------------------------------------

# built on top of https://gist.github.com/antoineMoPa/ada42dcfc96197e38dc8c4df363aed72 

function usage() {
    echo
    echo "A shell script to crawl a website and return a list of pages that do not contain the specified string"
    echo
    echo "usage: $0 base_url search_scope search_string report_on"
    echo "  base_url         the base protocal and domain (e.g. http://example.com"
    echo "  search_scope     one of internal, external or all"
    echo "  search_string    the string that should exist on all pages"
    echo "  report_on        one of exists or not_exists"
    echo
    exit 1
}

function clean() {
    # clean-up transient files used during processing
    rm -rf *.out
}

function crawl() {
    line=$1
    search_scope=$2
    internal_list=$3
    external_list=$4

    echo Crawling $1 for $2 links

    # get URLs internal to the domain
    if [ "$search_scope" == "internal" ] || [ "$search_scope" == "all" ]; then
        curl -silent $line | grep -o "href=\"\/[^(\ \>)]*" | sed 's|.*\="\(.*\)\"|\1|' | grep -v "^\/$" | sort | uniq > $internal_list
    fi

    # get URLs external to the domain
    if [ "$search_scope" == "external" ] || [ "$search_scope" == "all" ]; then
        curl -silent $line | grep -o "href=\"[http|https][^(\ \>)]*" | sed 's|.*\="\(.*\)\"|\1|' > $external_list
    fi
}

function search() {
    line=$1
    search_string=$2
    report_on=$3
    output=$4

    echo Searching $1

    if [ "$report_on" == "exists" ]; then
        if ! curl -silent $line | grep -q $search_string; then
            echo "     should contain the search string '$search_string'... but doesn't!"
            echo $line >> $output
        fi
    else
        if curl -silent $line | grep -q $search_string; then
            echo "     should not contain the search string '$search_string'... but does!"
            echo $line >> $output
        fi
    fi
}

# validate script arguments
if [ -z "$1" ]; then
    echo
    echo "Missing required argument 'base_url'."
    usage
fi

if [ -z "$2" ]; then
    echo
    echo "Missing required argument 'search_scope'."
    usage
fi

if [ -z "$3" ]; then
    echo
    echo "Missing required argument 'search_string'."
    usage
fi

if [ -z "$4" ]; then
    echo
    echo "Missing required argument 'report_on'."
    usage
fi

# a variable needs a name
site="$1"
search_scope="$2"
search_string="$3"
report_on="$4"

# file name variables
internal_list=internal_list.out
external_list=external_list.out
next_search_list=next_search_list.out
this_search_list=this_search_list.out
temp_file=temp.out
url_list=urls.out
output=$report_on.txt

# clean up in case previous runs failed
clean

# create some fake files for first run
echo $site > $url_list
cp $url_list $next_search_list

# get all the urls
while [ -f $next_search_list ]
do
    mv $next_search_list $this_search_list

    # crawl the results from the previous iteration
    while read line
    do
        crawl $line $search_scope $internal_list $external_list

        # internal list
        if [ -f $internal_list ]; then 
            # add base_url prefix
            cat $internal_list | sed -e "s|^|$site|" > $temp_file
            mv $temp_file $internal_list

            # identify unique urls
            cat $url_list $internal_list | sort | uniq >> $temp_file
            rm $internal_list

            # identify delta list of urls
            cat $url_list $temp_file | sort | uniq -u >> $next_search_list
        fi

        if [ -f $external_list ]; then 
            # identify unique urls
            cat $url_list $external_list | sort | uniq >> $temp_file
            rm $external_list

            # identify delta list of urls
            cat $url_list $temp_file | sort | uniq -u >> $next_search_list
        fi

        # add new urls 
        cat $url_list $next_search_list | sort | uniq > $temp_file
        mv $temp_file $url_list

    done < $this_search_list

    rm $this_search_list

    # delete empty search list
    find next_search_list.out -size 0 -delete
done

# search the urls
echo "Search for '$search_string' '$report_on' failed in the following files:" > $output
echo >> $output

while read line
do
    search $line $search_string $report_on $output
done < $url_list

# clean up
clean
