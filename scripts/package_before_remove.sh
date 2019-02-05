#!/usr/bin/env sh

# This script is intended to be used as a package pre-uninstall script.


/bin/systemctl is-active nginx
if [ $? -eq 0 ]; then
  /bin/systemctl stop nginx
fi
  /bin/systemctl disable nginx
  /bin/systemctl daemon-reload
