#!/bin/bash

#=============================================
# Desc: docker image for Unbound DNS server 
# Author: Ivan Cherniy
# Main site: https://r4ven.me
# Config note: https://r4ven.me/unbound-docker
#=============================================


### PREPARATION ###

# Define working directory and root hints URL
WORK_DIR="/etc/unbound"
ROOT_HINTS_URL="https://www.internic.net/domain/named.cache"
CONF_LIST=("unbound.conf" "forward-records.conf" "srv-records.conf" "a-records.conf")

# Copy default config files if they don't exist
for config in "${CONF_LIST[@]}"; do
    if [[ ! -f "${WORK_DIR}"/"${config}" ]]; then
        cp /usr/share/doc/unbound/"${config}" "${WORK_DIR}"
    fi
done

# Handle root.key file - create backup and update or restore
if [[ -f "${WORK_DIR}"/root.key ]]; then
    cp "${WORK_DIR}"/root.key{,_backup}

    if ! unbound-anchor -a "${WORK_DIR}"/root.key; then
        mv "${WORK_DIR}"/root.key{_backup,}
    else
        rm -f "${WORK_DIR}"/root.key_backup
    fi
else
    cp /usr/share/doc/unbound/root.key "$WORK_DIR"
fi

# Handle root.hints file - download fresh copy or restore backup
if [[ -f "${WORK_DIR}"/root.hints ]]; then
    cp "${WORK_DIR}"/root.hints{,_backup}

    if ! curl -sSL "$ROOT_HINTS_URL" > "${WORK_DIR}"/root.hints; then
        mv "${WORK_DIR}"/root.hints{_backup,}
    else
        rm -f "${WORK_DIR}"/root.hints_backup
    fi
else
    cp /usr/share/doc/unbound/root.hints "$WORK_DIR"
fi

# Set correct ownership for all files
chown -R unbound:unbound "$WORK_DIR"


### STARTING UNBOUND ###
echo "Starting Unbound DNS server"
exec "$@" || { echo "Starting failed" >&2; exit 1; }

