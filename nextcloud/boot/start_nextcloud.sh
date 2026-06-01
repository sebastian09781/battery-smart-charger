#!/data/data/com.termux/files/usr/bin/bash
sleep 15
source /data/data/com.termux/files/home/nc_vars.env
termux-wake-lock
# Matar procesos huerfanos antes de iniciar
pkill -f cloudflared 2>/dev/null
pkill -9 mariadbd 2>/dev/null
pkill php-fpm 2>/dev/null
pkill httpd 2>/dev/null
pkill -f redis-server 2>/dev/null
/data/data/com.termux/files/home/scripts/start_nextcloud.sh
