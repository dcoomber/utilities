# Utilities

## Data volume injector
Java/Maven based utility to inject data into a database table.
I used this to inject millions of records for volume testing (performance test with JMeter)
Update DataInjector.java with your database connection parameters, table name, field list and then set the field values inside the loop.

## Kubernetes deployment
Externally configurable bash utility for deploying to Kubernetes.

Default configuration is overrideable via namespace-specific configuration files.

As a final step of execution, the script outputs all the helper commands that I have thus far needed whilst performing my testing.

1. Deleting pods
1. Checking status of pods
1. Viewing ingress details
1. Viewing / changing helm installation details
1. Viewing / changing K8s deployment configuration
1. Viewing application logs
1. Editing the namespace configuration

## Web crawl and search
Command-line utility to traverse all links within a specific domain in order to search for specific text within the `html` of each page.
