#!/data/data/com.termux/files/usr/bin/bash

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'

WIDGET=0
[ ! -t 0 ] && WIDGET=1

echo ""
echo -e "${B}============================================${N}"
echo -e "${B}     REINICIANDO SEBASTIAN NEXTCLOUD${N}"
echo -e "${B}============================================${N}"
echo ""

echo -e "${Y}Deteniendo servicios...${N}"
bash /data/data/com.termux/files/home/scripts/stop_nextcloud.sh < /dev/null

echo ""
echo -e "${Y}Iniciando servicios...${N}"
bash /data/data/com.termux/files/home/scripts/start_nextcloud.sh < /dev/null

echo ""
echo -e "${G}============================================${N}"
echo -e "${G}     ✅ SEBASTIAN NEXTCLOUD REINICIADO${N}"
echo -e "${G}============================================${N}"
echo ""

echo "[$(date)] Servidor reiniciado" >> /data/data/com.termux/files/home/logs/startup.log

if [ "$WIDGET" != "1" ]; then
  read -t 10 -p "Presiona Enter para cerrar (auto 10s)..."
fi
