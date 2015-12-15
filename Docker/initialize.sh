#! /bin/bash

export CONFIG_FILE=/usr/share/docassemble/config.yml
source /usr/share/docassemble/local/bin/activate
sed -i'' \
    -e 's@{{DBPREFIX}}@'"${DBPREFIX-postgresql+psycopg2://}"'@' \
    -e 's/{{DBNAME}}/'"${DBNAME-docassemble}"'/' \
    -e 's/{{DBUSER}}/'"${DBUSER-docassemble}"'/' \
    -e 's/{{DBPASSWORD}}/'"${DBPASSWORD-abc123}"'/' \
    -e 's/{{DBHOST}}/'"${DBHOST-null}"'/' \
    -e 's/{{S3ENABLE}}/'"${S3ENABLE-false}"'/' \
    -e 's/{{S3ACCESSKEY}}/'"${S3ACCESSKEY-null}"'/' \
    -e 's/{{S3SECRETACCESSKEY}}/'"${S3SECRETACCESSKEY-null}"'/' \
    -e 's/{{S3BUCKET}}/'"${S3BUCKET-null}"'/' \
    -e 's/{{EC2}}/'"${EC2-false}"'/' \
    $CONFIG_FILE || exit 1
python -m docassemble.webapp.update_config $CONFIG_FILE || exit 1

if [ "${CONTAINERROLE-all}" == "all" ]; then
    supervisorctl start postgres || exit 1
    dbexists=`su -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='docassemble'\"" postgres`
    if [ -z "$dbexists" ]; then
	echo "drop database if exists docassemble; drop role if exists \"www-data\"; create role \"www-data\" login; drop role if exists root; create role root login; create database docassemble owner \"www-data\";" | su -c psql postgres || exit 1
        su -c "source /usr/share/docassemble/local/bin/activate && python -m docassemble.webapp.create_tables $CONFIG_FILE" www-data || exit 1
    fi
else
    python -m docassemble.webapp.create_tables $CONFIG_FILE
fi
python -m docassemble.webapp.install_certs $CONFIG_FILE || exit 1
if [ "${USEHTTPS-false}" == "true" ]; then
    a2enmod ssl
fi
supervisorctl start apache2