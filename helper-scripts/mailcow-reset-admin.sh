#!/usr/bin/env bash
[[ -f mailcow.conf ]] && source mailcow.conf
[[ -f ../mailcow.conf ]] && source ../mailcow.conf

if [[ -z ${DBUSER} ]] || [[ -z ${DBPASS} ]] || [[ -z ${DBNAME} ]]; then
	echo "Cannot find mailcow.conf, make sure this script is run from within the mailcow folder."
	exit 1
fi

_engine="${MAILCOW_CONTAINER_ENGINE}"

echo -n "Checking MySQL service... "
if [[ -z $(${_engine} ps -qf name=mysql-mailcow) ]]; then
	echo "failed"
	echo "MySQL (mysql-mailcow) is not up and running, exiting..."
	exit 1
fi

echo "OK"
read -r -p "Are you sure you want to reset the mailcow administrator account? [y/N] " response
response=${response,,}    # tolower
if [[ "$response" =~ ^(yes|y)$ ]]; then
	echo -e "\nWorking, please wait..."
  random=$(</dev/urandom tr -dc _A-Z-a-z-0-9 2> /dev/null | head -c${1:-16})
  password=$(${_engine} exec -it $(${_engine} ps -qf name=dovecot-mailcow) doveadm pw -s SSHA256 -p ${random} | tr -d '\r')
	${_engine} exec -it $(${_engine} ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "DELETE FROM admin WHERE username='admin';"
  ${_engine} exec -it $(${_engine} ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "DELETE FROM domain_admins WHERE username='admin';"
	${_engine} exec -it $(${_engine} ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "INSERT INTO admin (username, password, superadmin, active) VALUES ('admin', '${password}', 1, 1);"
	${_engine} exec -it $(${_engine} ps -qf name=mysql-mailcow) mysql -u${DBUSER} -p${DBPASS} ${DBNAME} -e "DELETE FROM tfa WHERE username='admin';"
	echo "
Reset credentials:
---
Username: admin
Password: ${random}
TFA: none
"
else
	echo "Operation canceled."
fi
