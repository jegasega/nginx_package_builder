#!/usr/bin/env sh

# This script is intended to be used as a pre/postinstall script.


if [ "${1}" -eq 1 ] || [ "${1}" -eq 2 ]; then
    /bin/systemctl daemon-reload
fi
