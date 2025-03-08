#!/usr/bin/bash

# Read through domains
for domain in $(find /etc/acme -type d -not -path /etc/acme); do
    if [ -f ${domain}/fullchain_new.pem ]; then # The certificate was renewed
        echo "Replacing certificate and fixing permissions for ${domain##*/}…"
        mv ${domain}/fullchain{_new,}.pem
        chown root:root ${domain}/fullchain.pem
        chmod 444 ${domain}/fullchain.pem
    fi
done
