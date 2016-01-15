#!/bin/bash
set -e

BACKUP_USER="mybackup"

echo "BACKUP SETTINGS"
echo "==============="
echo
echo "  User:     ${BACKUP_USER}"
echo "  UID:      ${BACKUP_UID:=666}"
echo "  GID:      ${BACKUP_GID:=666}"
echo
echo "  Location: ${BACKUP_DIR:=/backup}"
echo "  Options:  ${BACKUP_OPTIONS:=-c}"
echo

CONTAINER=$(export | sed -nr "/ENV_MYSQL_DATABASE/{s/^.+ -x (.+)_ENV.+/\1/p}")

if [[ -z "${CONTAINER}" ]]
then
    echo "ERROR: Couldn't find linked MySQL container." >&2
    echo >&2
    echo "Please link a MySQL or MariaDB container to the backup container and try again" >&2
    exit 1
fi

DB_PORT=$(export | sed -nr "/${CONTAINER}_PORT_[[:digit:]]+_TCP_PORT/{s/^.+ -x (.+)=.+/\1/p}")
DB_ADDR="${CONTAINER}_PORT_${!DB_PORT}_TCP_ADDR"
DB_NAME="${CONTAINER}_ENV_MYSQL_DATABASE"
DB_USER="${CONTAINER}_ENV_MYSQL_USER"
DB_PASS="${CONTAINER}_ENV_MYSQL_PASSWORD"

echo "CONTAINER SETTINGS"
echo "=================="
echo
echo "  Container: ${CONTAINER}"
echo
echo "  Address:   ${!DB_ADDR}"
echo "  Port:      ${!DB_PORT}"
echo
echo "  Database:  ${!DB_NAME}"
echo

[[ $(id -u ${BACKUP_USER}) == $BACKUP_UID ]] || usermod  -o -u $BACKUP_UID ${BACKUP_USER}
[[ $(id -g ${BACKUP_USER}) == $BACKUP_GID ]] || groupmod -o -g $BACKUP_GID ${BACKUP_USER}

mkdir -p ${BACKUP_DIR}
chown ${BACKUP_USER}: ${BACKUP_DIR}
cd ${BACKUP_DIR}

su -pc "mydumper -h ${!DB_ADDR} -P ${!DB_PORT} -u ${!DB_USER} -p ${!DB_PASS} -B ${!DB_NAME} ${BACKUP_OPTIONS}" ${BACKUP_USER}
