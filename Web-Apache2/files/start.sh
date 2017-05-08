#!/bin/bash
set -e  

# if $proxy_domain is not set, then default to $HOSTNAME
export id_server=${id_server:-"Error, no se pudo setear el parámetro"}

# ensure the following environment variables are set. exit script and container if not set.
test $id_server

/usr/local/bin/confd -onetime -backend env

echo "Starting Apache"
exec httpd -DFOREGROUND
