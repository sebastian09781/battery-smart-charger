#!/data/data/com.termux/files/usr/bin/bash
PREFIX=/data/data/com.termux/files/usr
LOG=$PREFIX/var/log/cf_tunnel.log

pkill -f "[c]loudflared" 2>/dev/null
sleep 1

nohup cloudflared tunnel --url http://127.0.0.1:8080 --protocol http2 --no-autoupdate > $LOG 2>&1 &
disown
echo "cloudflared PID: $!"

for i in $(seq 1 30); do
  URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' $LOG 2>/dev/null | head -1)
  if [ -n "$URL" ]; then
    echo "TUNNEL_URL=$URL"
    exit 0
  fi
  sleep 2
done

echo "TIMEOUT"
exit 1
