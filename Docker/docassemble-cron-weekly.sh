#! /bin/bash

if [ "${USEHTTPS-false}" == "true" ]; then
    if [ "${USELETSENCRYPT-false}" == "true" ]; then
	if [ -f /etc/letsencrypt/da_using_lets_encrypt ]; then
	    supervisorctl --serverurl http://localhost:9001 stop apache2
 	    cd /usr/share/docassemble/letsencrypt
	    ./letsencrypt-auto renew
	    /etc/init.d/apache2 stop
	    supervisorctl --serverurl http://localhost:9001 start apache2
	fi
    fi
fi
