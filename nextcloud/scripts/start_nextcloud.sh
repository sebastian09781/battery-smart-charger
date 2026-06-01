#!/data/data/com.termux/files/usr/bin/bash

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'

WIDGET=0
[ ! -t 0 ] && WIDGET=1

echo ""
echo -e "${B}============================================${N}"
echo -e "${B}     INICIANDO SEBASTIAN NEXTCLOUD${N}"
echo -e "${B}============================================${N}"
echo ""

source /data/data/com.termux/files/home/nc_vars.env
LOG="/data/data/com.termux/files/home/logs/startup.log"
PREFIX=/data/data/com.termux/files/usr
export PATH=/usr/bin:/bin:/usr/sbin:$PREFIX/bin

# pgrep usando /proc (compatible Android + proot)
LNK=/system/bin/linker64
_pids() { for f in /proc/[0-9]*/cmdline; do [ -r "$f" ] && grep -aq "$1" "$f" 2>/dev/null && echo "${f#/proc/}"; done | sed 's|/cmdline||'; }
_running() { for f in /proc/[0-9]*/cmdline; do [ -r "$f" ] && grep -aq "$1" "$f" 2>/dev/null && return 0; done; return 1; }

mkdir -p /data/data/com.termux/files/home/logs 2>/dev/null
chmod 777 /data/data/com.termux/files/home/logs 2>/dev/null
echo "[$(date)] Iniciando Nextcloud ---" >> $LOG

# 0. Matar cron loop previo
_pids "[c]ron_loop" | xargs kill -9 2>/dev/null

# 1. Wakelock
echo -ne "[1/9] ${Y}Wakelock${N} ............ "
timeout 3 termux-wake-lock 2>/dev/null
echo -e "${G}✅ activo${N}"
echo "[$(date)] Wakelock activado" >> $LOG

timeout 3 termux-notification --title "Nextcloud iniciando..." --content "Arrancando servicios..." --priority default 2>/dev/null

# 2. Redis (Termux binary -> usar Android linker)
echo -ne "[2/9] ${Y}Redis${N} .............. "
_pids "[r]edis" | xargs kill -9 2>/dev/null; sleep 1
/system/bin/linker64 $PREFIX/bin/redis-server $PREFIX/etc/redis.conf >> $LOG 2>&1
sleep 2
if _running "[r]edis"; then
  echo -e "${G}✅ activo${N}"
  echo "[$(date)] Redis OK" >> $LOG
else
  echo -e "${Y}⚠ fallo (no crítico)${N}"
  echo "[$(date)] Redis no inicio" >> $LOG
fi

# 3. MariaDB (Termux binary -> usar Android linker)
echo -ne "[3/9] ${Y}MariaDB${N} .............. "
export HOME=/data/data/com.termux/files/home
_pids "[m]ariadbd" | xargs kill -9 2>/dev/null; sleep 1
/system/bin/linker64 $PREFIX/bin/mariadbd --user=root --datadir=$PREFIX/var/lib/mysql --port=3306 > $PREFIX/var/log/mariadbd.log 2>&1 &
disown
for i in $(seq 1 12); do
  sleep 1
  /system/bin/linker64 $PREFIX/bin/mysqladmin -h 127.0.0.1 ping --silent 2>/dev/null && break
done
if /system/bin/linker64 $PREFIX/bin/mysqladmin -h 127.0.0.1 ping --silent 2>/dev/null; then
  echo -e "${G}✅ activo${N}"
  echo "[$(date)] MariaDB OK" >> $LOG
else
  echo -e "${R}❌ fallo${N}"
  echo "[$(date)] ERROR: MariaDB no inicio" >> $LOG
  timeout 3 termux-notification --title "MariaDB fallo" --content "Ver startup.log" --priority high 2>/dev/null
  if [ "$WIDGET" = "1" ]; then
    sleep 5
  else
    read -p "Presiona Enter para cerrar..."
  fi
  exit 1
fi

# 4. PHP-FPM (Termux binary -> usar Android linker)
echo -ne "[4/9] ${Y}PHP-FPM${N} ............. "
for i in $(seq 1 30); do
  if [ -d "/storage/emulated/0/Nextcloud/data" ]; then break; fi
  sleep 1
done
[ -f $PREFIX/var/run/php-fpm.pid ] && kill -QUIT $(cat $PREFIX/var/run/php-fpm.pid) 2>/dev/null; sleep 1
_pids php-fpm | xargs kill -9 2>/dev/null; sleep 1
/system/bin/linker64 $PREFIX/bin/php-fpm -D --allow-to-run-as-root >> $LOG 2>&1 &
sleep 3
if _running php-fpm; then
  echo -e "${G}✅ activo${N}"
  echo "[$(date)] PHP-FPM OK" >> $LOG
else
  echo -e "${R}❌ fallo${N}"
  echo "[$(date)] PHP-FPM ERROR" >> $LOG
fi

# 5. Apache (Termux binary -> usar Android linker)
echo -ne "[5/9] ${Y}Apache${N} .............. "
for i in $(seq 1 30); do
  if [ -d "/storage/emulated/0/Nextcloud/html" ]; then break; fi
  sleep 1
done
_pids "[h]ttpd" | xargs kill -9 2>/dev/null
rm -f $PREFIX/var/run/apache2/httpd.pid 2>/dev/null
sleep 1
for attempt in 1 2 3; do
  /system/bin/linker64 $PREFIX/bin/httpd -k start 2>/dev/null
  sleep 3
  HTTP_CODE=$(/system/bin/linker64 $PREFIX/bin/curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://127.0.0.1:8080/core/img/favicon.png 2>/dev/null)
  if [ "$HTTP_CODE" = "200" ]; then
    break
  fi
  _pids "[h]ttpd" | xargs kill -9 2>/dev/null
  rm -f $PREFIX/var/run/apache2/httpd.pid 2>/dev/null
  sleep 2
done
if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${G}✅ HTTP 200 (PHP OK)${N}"
  echo "[$(date)] Apache OK, PHP OK (HTTP $HTTP_CODE)" >> $LOG
else
  echo -e "${Y}⚠ HTTP $HTTP_CODE${N}"
  echo "[$(date)] WARNING: Apache responde HTTP $HTTP_CODE" >> $LOG
fi

# 6. Permisos
echo -ne "[6/9] ${Y}Permisos${N} ............ "
chgrp -R 9997 /storage/emulated/0/Nextcloud/data/ 2>/dev/null
find /storage/emulated/0/Nextcloud/data -type d -exec chmod 755 {} + 2>/dev/null
find /storage/emulated/0/Nextcloud/data/sebastian09781/files -type f -exec chmod 644 {} + 2>/dev/null
echo -e "${G}✅ listo${N}"
echo "[$(date)] Permisos fijados" >> $LOG

# 7. Cloudflare Tunnel (binario estatico)
echo -ne "[7/9] ${Y}Cloudflare Tunnel${N} ... "
_pids "[c]loudflared" | xargs kill -9 2>/dev/null
cloudflared tunnel --url http://127.0.0.1:8080 --protocol http2 --no-autoupdate --loglevel info >/dev/null 2>$PREFIX/var/log/cf_tunnel.log &
disown
TUNNEL_URL=""
for i in $(seq 1 60); do
  TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' $PREFIX/var/log/cf_tunnel.log 2>/dev/null | head -1)
  [ -n "$TUNNEL_URL" ] && break
  sleep 2
done
echo -e "${G}✅ $TUNNEL_URL${N}"
echo "[$(date)] Tunel: $TUNNEL_URL" >> $LOG

# 8. Worker
echo -ne "[8/9] ${Y}Cloudflare Worker${N} .... "
if [ -n "$TUNNEL_URL" ]; then
  for i in $(seq 1 12); do
    HTTP_CHECK=$($LNK $PREFIX/bin/curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$TUNNEL_URL/core/img/favicon.png" 2>/dev/null)
    [ "$HTTP_CHECK" = "200" ] && break
    sleep 5
  done
  cat > $PREFIX/var/log/worker.js << WORKEREOF
const TUNNEL = "${TUNNEL_URL}";
const PUBLIC = "https://nextcloud.sebastiancloud.workers.dev";
export default {
  async fetch(req) {
    const url = new URL(req.url);
    const target = TUNNEL + url.pathname + url.search;
    const headers = new Headers(req.headers);
    headers.set("X-Forwarded-Proto", "https");
    headers.set("X-Forwarded-Host", "nextcloud.sebastiancloud.workers.dev");
    headers.delete("cf-connecting-ip");
    const isBodyless = req.method === "GET" || req.method === "HEAD";
    let res;
    try { res = await fetch(target, { method: req.method, headers, body: isBodyless ? undefined : req.body, redirect: "manual" }); }
    catch (e) { return new Response("Servidor no disponible: " + e.message, { status: 503 }); }
    const resHeaders = new Headers(res.headers);
    if (resHeaders.has("location")) { resHeaders.set("location", resHeaders.get("location").replace(/https?:\/\/[a-z0-9-]*\.trycloudflare\.com/, PUBLIC)); }
    resHeaders.set("X-Content-Type-Options", "nosniff");
    resHeaders.set("X-Frame-Options", "SAMEORIGIN");
    return new Response(res.body, { status: res.status, statusText: res.statusText, headers: resHeaders });
  }
};
WORKEREOF
  for attempt in 1 2 3; do
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/workers/scripts/${WORKER_NAME}" -H "Authorization: Bearer ${CF_TOKEN}" -F "metadata={\"main_module\":\"worker.js\",\"usage_model\":\"bundled\",\"compatibility_date\":\"2024-01-01\"};type=application/json"   -F "worker.js=@$PREFIX/var/log/worker.js;type=application/javascript+module")
    if echo "$HTTP" | grep -qE '^2'; then
      break
    fi
    echo -e "${Y}⚠ reintento $attempt (HTTP $HTTP)${N} "
    sleep 5
  done
  if echo "$HTTP" | grep -qE '^2'; then
    echo -e "${G}✅ actualizado (HTTP $HTTP)${N}"
    curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/workers/scripts/${WORKER_NAME}/subdomain" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{"enabled":true}' > /dev/null 2>&1
  else
    echo -e "${R}❌ HTTP $HTTP${N}"
  fi
  echo "[$(date)] Worker update: HTTP $HTTP" >> $LOG
else
  echo -e "${Y}⚠ omitido${N}"
  echo "[$(date)] WARNING: Tunel no conectado" >> $LOG
fi

# 9. Cron
echo -ne "[9/9] ${Y}Cron${N} ............... "
_pids "[c]ron_loop" | xargs kill -9 2>/dev/null
nohup $PREFIX/bin/bash /data/data/com.termux/files/home/scripts/cron_loop.sh > /dev/null 2>&1 &
sleep 1
if _running "[c]ron_loop"; then
  echo -e "${G}✅ activo${N}"
  echo "[$(date)] Cron iniciado" >> $LOG
else
  echo -e "${Y}⚠ fallo${N}"
  echo "[$(date)] Cron no inicio" >> $LOG
fi

echo ""
echo -e "${G}============================================${N}"
echo -e "${G}     ✅ SEBASTIAN NEXTCLOUD OPERATIVO${N}"
echo -e "${G}============================================${N}"
echo ""
echo -e "   ${B}Local:${N}  http://192.168.137.76:8080"
echo -e "   ${B}Remoto:${N} https://nextcloud.sebastiancloud.workers.dev"
echo ""
echo -e "   ${B}Usuario:${N} sebastian09781"
echo -e "   ${B}Tunel:${N}  ${TUNNEL_URL:-desconocido}"
echo ""
echo "[$(date)] Inicio completado" >> $LOG

timeout 3 termux-notification --title "Sebastian NextCloud listo ✅" --content "Local: http://192.168.137.76:8080 | Cloud: https://nextcloud.sebastiancloud.workers.dev" --priority low 2>/dev/null

read -t 10 -p "Presiona Enter para cerrar (auto 10s)..."
