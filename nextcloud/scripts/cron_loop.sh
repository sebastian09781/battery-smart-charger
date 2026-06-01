#!/data/data/com.termux/files/usr/bin/bash
# Nextcloud cron loop
export PATH=/data/data/com.termux/files/usr/bin:/data/data/com.termux/files/usr/bin:/usr/bin:/bin
PHP=/data/data/com.termux/files/usr/bin/php
CRON_PHP=/data/data/com.termux/files/home/nextcloud_html/cron.php
LOG=/data/data/com.termux/files/home/logs/cron.log

while true; do
  $PHP -f $CRON_PHP >> $LOG 2>&1
  sleep 300
done
