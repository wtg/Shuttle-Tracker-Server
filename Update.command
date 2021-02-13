#!/bin/bash

if [ $(id -u) -ne 0 ]; then
	echo "ERROR: This script must be run as root." >> /dev/stderr
	exit
fi
echo "Stopping daemon..." >> /dev/stdout
systemctl stop shuttle >> /var/log/shuttle_update.log
echo "Downloading shuttle server..." >> /dev/stdout
git pull >> /var/log/shuttle_update.log
echo "Building shuttle server..." >> /dev/stdout
swift build -c release >> /var/log/shuttle_update.log
echo "Starting daemon..." >> /dev/stdout
systemctl restart shuttle >> /var/log/shuttle_update.log
echo "The shuttle server has been updated! You can check out the update log in \`/var/log/shuttle_update.log\`." >> /dev/stdout
