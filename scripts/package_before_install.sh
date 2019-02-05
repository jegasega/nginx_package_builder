#!/usr/bin/env sh

# This script is intended to be used as a package pre/postinstall script.
GROUPNAME="nginx"
ALLOCATED_GID=994
USERNAME="nginx"
ALLOCATED_UID=994

HOMEDIR="/var/lib/nginx"

getent group "${GROUPNAME}" >/dev/null || groupadd -f -g "${ALLOCATED_GID}" -r "${GROUPNAME}"
if ! getent passwd "${USERNAME}" >/dev/null ; then
    if ! getent passwd "${ALLOCATED_UID}" >/dev/null ; then
        useradd -r -u "${ALLOCATED_UID}" -g "${GROUPNAME}" -d "${HOMEDIR}" -s /sbin/nologin -c "NGINX server account" "${USERNAME}"
    else
        useradd -r -g "${GROUPNAME}" -d "${HOMEDIR}" -s /sbin/nologin -c "NGINX server account" "${USERNAME}"
    fi
fi
