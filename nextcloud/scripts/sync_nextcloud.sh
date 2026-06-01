#!/data/data/com.termux/files/usr/bin/bash
chmod 755 "$0" 2>/dev/null
# Sincroniza archivos de Nextcloud a una carpeta visible en el file manager
# Los archivos se copian a ~/storage/downloads/Nextcloud/

NC_DATA="/storage/emulated/0/Nextcloud/data/admin/files"
NC_USER="admin"
SYNC_DIR="/storage/emulated/0/Download/Nextcloud"

echo "[$(date)] Sincronizando archivos de Nextcloud..."

# Crear directorio de destino
mkdir -p "$SYNC_DIR"

# Copiar archivos (solo nuevos/modificados)
rsync -a --delete "$NC_DATA/" "$SYNC_DIR/" 2>/dev/null

# Fijar permisos world-readable
find "$SYNC_DIR" -type d -exec chmod 777 {} + 2>/dev/null
find "$SYNC_DIR" -type f -exec chmod 666 {} + 2>/dev/null

total=$(find "$SYNC_DIR" -type f | wc -l)
echo "[$(date)] Sincronizacion completa. $total archivos en $SYNC_DIR"

# Notificar
termux-notification --title "Nextcloud sync" --content "$total archivos sincronizados a Downloads/Nextcloud/" --priority low
