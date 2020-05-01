#!/bin/bash
# A shell script to crawl a website and return a list of
#   pages that do not contain the specified string
# Written by: David Coomber
# Last updated on: 1 May 2020
# -------------------------------------------------------

# based on https://gist.github.com/antoineMoPa/ada42dcfc96197e38dc8c4df363aed72 


#  https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

function usage {
    echo
    echo "A shell script to crawl a website and return a list of pages that do not contain the specified string"
    echo
    echo "usage: $0 base_url search_string [search_scope]"
    echo "  base_url         the domain, optionally including path (e.g. http://example.com or http://example.com/path"
    echo "  search_string    the string that should exist on all pages"
    echo "  search_scope     one of internal, external or all (default=internal)"
    echo
    exit 1
}

function clean() {
    # clean-up transient files used during processing
    rm -rf *.out
}

function visit() {
    echo Visiting $1 for $2 links

    # get URLs internal to the domain
    if [ "$2" == "internal" ] || [ "$2" == "all" ]; then
        curl -silent $1 | grep -o "href=\"\/[^(\ \>)]*" | sed 's|.*\="\(.*\)\"|\1|' | grep -v "^\/$" | sort | uniq > $3
    fi

    # get URLs external to the domain
    if [ "$2" == "external" ] || [ "$2" == "all" ]; then
        curl -silent $1 | grep -o "href=\"[http|https][^(\ \>)]*" >$4
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
    echo "Missing required argument 'search_string'."
    usage
fi

if [ -z "$3" ]; then
    # default to internal domain
    scope=internal
else
    scope=$3
fi

# a variable needs a name
site=$1
search_string=$2

# file name variables
internal_list=internal_list.out
external_list=external_list.out
next_search_list=next_search_list.out
visited_list=visited_list.out
temp_file=temp.out
url_list=urls.out

# clean up in case previous runs failed
clean

# create fake files for first run
echo $site > $url_list
cp $url_list $next_search_list

while [ -f $next_search_list ]
do
    # crawl the last set of results
    while read line
    do
        visit $line $scope $internal_list $external_list
    done < $next_search_list

    # clean
    rm $next_search_list

    # internal list
    if [ -f $internal_list ]; then 
        # add base_url prefix
        cat $internal_list | sed -e "s|^|$site|" > $temp_file
        mv $temp_file $internal_list

        # remove duplicated urls
        cat $url_list $internal_list | sort | uniq -u >> $temp_file
        cat $url_list $internal_list $temp_file | sort | uniq -u >> $next_search_list

        rm $internal_list
    fi

    if [ -f $external_list ]; then 
        cat $url_list $external_list | sort | uniq -u >> $next_search_list

        rm $external_list
    fi

    # add new urls 
    cat $url_list $next_search_list | sort | uniq > $temp_file
    mv $temp_file $url_list

    # delete empty files
    find *.out -size 0 -delete
done

# iterate whilst the file exists




# while read line
# do
#     visit $line sub-2-urls.txt
# done < sub-urls.txt

# clean