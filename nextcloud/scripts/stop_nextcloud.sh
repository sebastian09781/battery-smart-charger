#!/data/data/com.termux/files/usr/bin/bash

PREFIX=/data/data/com.termux/files/usr
export PATH=/usr/bin:/bin:/usr/sbin:$PREFIX/bin
LNK=/system/bin/linker64

WIDGET=0
[ ! -t 0 ] && WIDGET=1

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'

echo ""
echo -e "${B}============================================${N}"
echo -e "${B}     DETENIENDO SEBASTIAN NEXTCLOUD${N}"
echo -e "${B}============================================${N}"
echo ""

_pids() { for f in /proc/[0-9]*/cmdline; do [ -r "$f" ] && grep -aq "$1" "$f" 2>/dev/null && echo "${f#/proc/}"; done | sed 's|/cmdline||'; }

# 0. Cron
echo -ne "[0/6] ${Y}Cron${N} ............... "
_pids "[c]ron_loop" | xargs kill -9 2>/dev/null; sleep 1
echo -e "${R}✅ detenido${N}"

# 1. Cloudflared
echo -ne "[1/6] ${Y}Cloudflare Tunnel${N} ... "
CF_PID=$(_pids "[c]loudflared" | head -1)
if [ -n "$CF_PID" ]; then
  kill -9 $CF_PID 2>/dev/null
  sleep 1
  echo -e "${R}✅ detenido${N}"
else
  echo -e "${Y}⚠ no estaba corriendo${N}"
fi

# 3. Apache
echo -ne "[2/6] ${Y}Apache${N} .............. "
$LNK $PREFIX/bin/httpd -k stop 2>/dev/null; sleep 1
_pids "[h]ttpd" | head -1 | xargs kill -9 2>/dev/null; sleep 1
echo -e "${R}✅ detenido${N}"

# 4. PHP-FPM
echo -ne "[3/6] ${Y}PHP-FPM${N} ............. "
[ -f $PREFIX/var/run/php-fpm.pid ] && kill -QUIT $(cat $PREFIX/var/run/php-fpm.pid) 2>/dev/null; sleep 1
_pids php-fpm | xargs kill -9 2>/dev/null; sleep 1
echo -e "${R}✅ detenido${N}"

# 5. MariaDB
echo -ne "[4/6] ${Y}MariaDB${N} .............. "
_pids "[m]ariadbd" | head -1 | xargs kill -9 2>/dev/null; sleep 1
echo -e "${R}✅ detenido${N}"

# 6. Redis
echo -ne "[5/6] ${Y}Redis${N} .............. "
_pids "[r]edis" | head -1 | xargs kill -9 2>/dev/null; sleep 1
echo -e "${R}✅ detenido${N}"

echo ""
timeout 3 termux-wake-unlock 2>/dev/null

echo ""
echo -e "${G}============================================${N}"
echo -e "${G}     ✅ SEBASTIAN NEXTCLOUD DETENIDO${N}"
echo -e "${G}============================================${N}"
echo ""
echo -e "   Todos los servicios han sido detenidos."
echo ""

echo "[$(date)] Servidor detenido" >> /data/data/com.termux/files/home/logs/startup.log

timeout 3 termux-notification --title "Sebastian NextCloud detenido" --content "Servicios detenidos correctamente" --priority default 2>/dev/null

if [ "$WIDGET" != "1" ]; then
  read -t 10 -p "Presiona Enter para cerrar (auto 10s)..."
fi
