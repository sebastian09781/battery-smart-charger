#!/data/data/com.termux/files/usr/bin/bash

PREFIX=/data/data/com.termux/files/usr
export LD_LIBRARY_PATH=$PREFIX/lib
source /data/data/com.termux/files/home/nc_vars.env

LOG="/data/data/com.termux/files/home/logs/worker_update.log"
echo "[$(date)] Iniciando actualizacion Worker..." >> $LOG

# Kill previous tunnel
$PREFIX/bin/pgrep -f "[c]loudflared tunnel" 2>/dev/null | while read pid; do kill -9 $pid 2>/dev/null; done
sleep 2

# Start tunnel (sin LD_LIBRARY_PATH para cloudflared)
rm -f $PREFIX/var/log/cf_tunnel.log
SAVE_LD=$LD_LIBRARY_PATH
unset LD_LIBRARY_PATH
cloudflared tunnel --url http://127.0.0.1:8080 \
  --protocol http2 \
  --no-autoupdate \
  --loglevel info \
  2>$PREFIX/var/log/cf_tunnel.log &

CF_PID=$!
echo $CF_PID > $PREFIX/var/log/cf_tunnel.pid
export LD_LIBRARY_PATH=$SAVE_LD

# Wait for URL
TUNNEL_URL=""
for i in $(seq 1 30); do
  TUNNEL_URL=$($PREFIX/bin/grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' $PREFIX/var/log/cf_tunnel.log 2>/dev/null | $PREFIX/bin/head -1)
  if [ -n "$TUNNEL_URL" ]; then
    break
  fi
  sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
  echo "[$(date)] ERROR: No se obtuvo URL del túnel" >> $LOG
  termux-notification --title "Nextcloud ERROR" --content "Túnel no inició" --priority high
  exit 1
fi

echo "[$(date)] Túnel activo: $TUNNEL_URL" >> $LOG

# Generate Worker JS
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
    try {
      res = await fetch(target, {
        method: req.method,
        headers,
        body: isBodyless ? undefined : req.body,
        redirect: "manual",
      });
    } catch (e) {
      return new Response("Servidor no disponible: " + e.message, { status: 503 });
    }

    const resHeaders = new Headers(res.headers);

    if (resHeaders.has("location")) {
      const loc = resHeaders.get("location");
      resHeaders.set("location", loc.replace(/https?:\/\/[a-z0-9-]*\.trycloudflare\.com/, PUBLIC));
    }

    resHeaders.set("X-Content-Type-Options", "nosniff");
    resHeaders.set("X-Frame-Options", "SAMEORIGIN");

    return new Response(res.body, {
      status: res.status,
      statusText: res.statusText,
      headers: resHeaders,
    });
  }
};
WORKEREOF

# Upload to Cloudflare
SAVE_LD=$LD_LIBRARY_PATH
unset LD_LIBRARY_PATH
HTTP_STATUS=$($PREFIX/bin/curl -s -o $PREFIX/var/log/cf_response.json -w "%{http_code}" \
  -X PUT "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/workers/scripts/${WORKER_NAME}" \
  -H "Authorization: Bearer ${CF_TOKEN}" \
  -F "metadata={\"main_module\":\"worker.js\",\"usage_model\":\"bundled\",\"compatibility_date\":\"2024-01-01\"};type=application/json" \
  -F "worker.js=@$PREFIX/var/log/worker.js;type=application/javascript+module")
export LD_LIBRARY_PATH=$SAVE_LD

if [ "$HTTP_STATUS" = "200" ]; then
  # Re-enable workers.dev subdomain (upload may reset it)
  curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/workers/scripts/${WORKER_NAME}/subdomain" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"enabled":true}' > /dev/null 2>&1
  echo "[$(date)] Worker actualizado correctamente -> $TUNNEL_URL" >> $LOG
  termux-notification \
    --title "Nextcloud activo" \
    --content "${PUBLIC_URL:-https://nextcloud.sebastiancloud.workers.dev} -> $TUNNEL_URL" \
    --priority default
else
  echo "[$(date)] ERROR actualizando Worker. HTTP: $HTTP_STATUS" >> $LOG
  cat $PREFIX/var/log/cf_response.json >> $LOG
  termux-notification \
    --title "Worker no actualizado" \
    --content "Revisar ~/logs/worker_update.log" \
    --priority high
fi
