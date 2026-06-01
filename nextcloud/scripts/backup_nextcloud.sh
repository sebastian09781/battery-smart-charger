#!/data/data/com.termux/files/usr/bin/bash
# Backup & Restore de configuracion Nextcloud
# Uso: backup_nextcloud.sh [backup|restore|list]
#      backup_nextcloud.sh backup [nombre]
#      backup_nextcloud.sh restore <nombre>
#      backup_nextcloud.sh list

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'
PREFIX=/data/data/com.termux/files/usr
export PATH=/usr/bin:/bin:/usr/sbin:$PREFIX/bin

BACKUP_DIR="/data/data/com.termux/files/home/backups"
NC_HOME="/data/data/com.termux/files/home"
SCRIPTS_DIR="${NC_HOME}/scripts"
NC_VARS="${NC_HOME}/nc_vars.env"
STARTUP_LOG="${NC_HOME}/logs/startup.log"

mkdir -p "$BACKUP_DIR"

_cmd_backup() {
  local name="${1:-manual_$(date +%Y%m%d_%H%M%S)}"
  local dest="${BACKUP_DIR}/${name}"
  mkdir -p "$dest/scripts" "$dest/config" "$dest/logs"

  echo -e "${B}Backup: ${name}${N}"

  # 1. Scripts
  cp -a "$SCRIPTS_DIR/" "$dest/scripts/" 2>/dev/null
  [ -f "$NC_VARS" ] && cp "$NC_VARS" "$dest/config/nc_vars.env"
  echo -e "  ${G}✅${N} scripts/"

  # 2. Logs relevantes
  [ -f "$STARTUP_LOG" ] && cp "$STARTUP_LOG" "$dest/logs/startup.log"
  [ -f "${PREFIX}/var/log/cf_tunnel.log" ] && cp "${PREFIX}/var/log/cf_tunnel.log" "$dest/logs/cf_tunnel.log"
  echo -e "  ${G}✅${N} logs/"

  # 5. Nextcloud config (si accesible)
  NC_CONFIG="/storage/emulated/0/Nextcloud/html/config/config.php"
  [ -f "$NC_CONFIG" ] && cp "$NC_CONFIG" "$dest/config/config.php" && echo -e "  ${G}✅${N} config.php"

  # Resumen
  echo ""
  echo -e "${G}Backup completo:${N} $dest"
  echo -e "  Tamaño: $(du -sh "$dest" 2>/dev/null | cut -f1)"
}

_cmd_restore() {
  local name="$1"
  local dest="${BACKUP_DIR}/${name}"
  if [ ! -d "$dest" ]; then
    echo -e "${R}Error: backup '${name}' no encontrado en ${BACKUP_DIR}${N}"
    echo "Disponibles:"
    _cmd_list
    exit 1
  fi

  echo -e "${Y}⚠  RESTAURANDO: ${name}${N}"
  echo -e "${Y}   Se detendran los servicios primero${N}"
  echo ""
  echo -ne "  Confirmar? (si/no): "; read confirm
  [ "$confirm" != "si" ] && echo "Cancelado." && exit 0

  # Detener servicios
  echo "  Deteniendo servicios..."
  bash "${SCRIPTS_DIR}/stop_nextcloud.sh" >/dev/null 2>&1
  sleep 2

  # Restaurar scripts
  if [ -d "$dest/scripts" ]; then
    cp -a "$dest/scripts/"* "$SCRIPTS_DIR/" 2>/dev/null
    chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null
    echo -e "  ${G}✅${N} scripts restaurados"
  fi

  # Restaurar nc_vars.env
  [ -f "$dest/config/nc_vars.env" ] && cp "$dest/config/nc_vars.env" "$NC_VARS"
  echo -e "  ${G}✅${N} config restaurada"

  # Restaurar glibc local
  if [ -d "$dest/glibc" ] && [ -n "$(ls -A "$dest/glibc/" 2>/dev/null)" ]; then
    cp -a "$dest/glibc/" "${WRITABLE}/glibc/"
    echo -e "  ${G}✅${N} glibc restaurado"
  fi

  echo ""
  echo -e "${G}Restauracion completa.${N}"
  echo -e "  Para iniciar: ${B}bash ${SCRIPTS_DIR}/start_nextcloud.sh${N}"
}

_cmd_list() {
  echo -e "${B}Backups disponibles en ${BACKUP_DIR}:${N}"
  echo ""
  for d in "$BACKUP_DIR"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    size=$(du -sh "$d" 2>/dev/null | cut -f1)
    files=$(find "$d" -type f 2>/dev/null | wc -l)
    date=""
    [ -f "$d/logs/startup.log" ] && date=$(head -1 "$d/logs/startup.log" 2>/dev/null | cut -d']' -f1 | tr -d '[')
    echo -e "  ${B}${name}${N}"
    echo -e "    Tamaño: ${size}  |  Archivos: ${files}"
    [ -n "$date" ] && echo -e "    Inicio: ${date}"
    echo ""
  done
}

case "${1:-list}" in
  backup|b|-b|--backup) _cmd_backup "$2" ;;
  restore|r|-r|--restore) _cmd_restore "$2" ;;
  list|l|-l|--list) _cmd_list ;;
  *)
    echo "Uso: backup_nextcloud.sh <comando> [nombre]"
    echo ""
    echo "  backup  [nombre]  Crear backup (default: manual_TIMESTAMP)"
    echo "  restore <nombre>  Restaurar desde backup"
    echo "  list              Listar backups disponibles"
    ;;
esac
