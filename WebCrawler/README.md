# Web crawl and search

A shell script to crawl a website and return a list of pages that do not contain the specified string

``` bash
usage: ./crawl.sh base_url search_scope search_string report_on
  base_url         the base protocal and domain (e.g. http://example.com)
  search_scope     one of internal, external or all
  search_string    the string that should exist on all pages
  report_on        one of exists or not_exists
```

## Example usage

``` bash
./crawl.sh https://microsoft.com internal windows not_exists
```