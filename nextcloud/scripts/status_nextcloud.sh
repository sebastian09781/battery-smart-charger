#!/data/data/com.termux/files/usr/bin/bash

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

echo ""
echo -e "${B}============================================${N}"
echo -e "${B}     ESTADO DE SEBASTIAN NEXTCLOUD${N}"
echo -e "${B}============================================${N}"
echo ""

PREFIX=/data/data/com.termux/files/usr
export PATH=/usr/bin:/bin:/usr/sbin:$PREFIX/bin
LNK=/system/bin/linker64

WIDGET=0
[ ! -t 0 ] && WIDGET=1

_pids() { for f in /proc/[0-9]*/cmdline; do [ -r "$f" ] && grep -aq "$1" "$f" 2>/dev/null && echo "${f#/proc/}"; done | sed 's|/cmdline||'; }
_running() { for f in /proc/[0-9]*/cmdline; do [ -r "$f" ] && grep -aq "$1" "$f" 2>/dev/null && return 0; done; return 1; }

echo -ne "${C}Verificando servicios${N}"
for i in $(seq 1 3); do echo -n "."; sleep 0.3; done
echo ""

echo ""
echo -e "  ${B}Servicios:${N}"
echo "  ─────────────────────────────"

# Redis
echo -ne "  Redis      "
if _running "[r]edis"; then
  echo -e "${G}✅ activo${N}"
else
  echo -e "${R}❌ inactivo${N}"
fi

# MariaDB
echo -ne "  MariaDB    "
if $LNK $PREFIX/bin/mariadb-admin ping --silent 2>/dev/null; then
  echo -e "${G}✅ activo${N}"
else
  echo -e "${R}❌ inactivo${N}"
fi

# PHP-FPM
echo -ne "  PHP-FPM    "
PIDS=$(_pids php-fpm | wc -l)
if [ "$PIDS" -gt 0 ]; then
  echo -e "${G}✅ ${PIDS} procesos${N}"
else
  echo -e "${R}❌ inactivo${N}"
fi

# Apache
echo -ne "  Apache     "
PIDS=$(_pids "[h]ttpd" | wc -l)
if [ "$PIDS" -gt 0 ]; then
  HTTP=$($LNK $PREFIX/bin/curl -m 3 -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/core/img/favicon.png 2>/dev/null)
  if [ "$HTTP" = "200" ]; then
    echo -e "${G}✅ ${PIDS} procesos (HTTP 200)${N}"
  else
    echo -e "${Y}⚠ ${PIDS} procesos (HTTP ${HTTP:-timeout})${N}"
  fi
else
  echo -e "${R}❌ inactivo${N}"
fi

# Cloudflare
echo -ne "  Cloudflare "
TUNNEL_URL=$(grep -h -o 'https://[a-z0-9-]*\.trycloudflare\.com' $PREFIX/var/log/cf_tunnel.log $PREFIX/var/log/cf_http2.log $PREFIX/var/log/cf_persist.log 2>/dev/null | tail -1)
if _running "[c]loudflared"; then
  if [ -n "$TUNNEL_URL" ]; then
    echo -e "${G}✅ activo${N}"
  else
    echo -e "${Y}⚠ conectando...${N}"
  fi
else
  echo -e "${R}❌ inactivo${N}"
fi

# Cron
echo -ne "  Cron       "
if _running "[c]ron_loop"; then
  echo -e "${G}✅ activo${N}"
else
  echo -e "${R}❌ inactivo${N}"
fi

echo ""
echo -e "  ${B}URLs:${N}"
echo "  ─────────────────────────────"
echo -e "  ${C}Local:${N}  http://192.168.137.76:8080"
echo -e "  ${C}Remoto:${N} https://nextcloud.sebastiancloud.workers.dev"
echo ""
echo -e "  ${B}Usuario:${N} sebastian09781"
echo ""

if [ -n "$TUNNEL_URL" ]; then
  echo -e "  ${B}Tunel activo:${N} $TUNNEL_URL"
  echo ""
fi

echo -e "${B}============================================${N}"
echo ""

if [ "$WIDGET" != "1" ]; then
  read -t 10 -p "Presiona Enter para salir (auto 10s)..."
fi
