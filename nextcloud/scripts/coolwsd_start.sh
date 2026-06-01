#!/data/data/com.termux/files/usr/bin/bash
# Inicia el servidor Collabora CODE para Nextcloud Office
PATH_EXTRACTED="/data/data/com.termux/files/usr/tmp/opencode/squashfs-root"
WRITABLE="/data/data/com.termux/files/usr/tmp/opencode/coolwsd_data"
LOG="/data/data/com.termux/files/home/logs/coolwsd.log"
PIDFILE="/data/data/com.termux/files/home/nextcloud_data/tmp/coolwsd.pid"

export PATH="${PATH_EXTRACTED}/usr/bin/:${PATH_EXTRACTED}/bin/:${PATH}"
export LD_LIBRARY_PATH="${PATH_EXTRACTED}/opt/collaboraoffice/program/:${PATH_EXTRACTED}/usr/lib/:${PATH_EXTRACTED}/usr/lib/aarch64-linux-gnu/"
export COOLKITCONFIG_XCU="${PATH_EXTRACTED}/etc/coolwsd/coolkitconfig.xcu"
export LC_ALL=C.UTF-8
export SAL_LOG="-INFO-WARN"

mkdir -p "$(dirname "$LOG")" "$WRITABLE" "$(dirname "$PIDFILE")"

_pid() { cat "$PIDFILE" 2>/dev/null; }
_running() { [ -n "$(_pid)" ] && kill -0 "$(_pid)" 2>/dev/null; }

echo "[$(date)] ===== coolwsd_start.sh iniciado =====" >> "$LOG"

# Verificar si el puerto 9983 ya está ocupado por un proceso zombie
if timeout 2 bash -c 'echo > /dev/tcp/127.0.0.1/9983' 2>/dev/null; then
  echo "[$(date)] ADVERTENCIA: puerto 9983 ocupado, matando proceso..." >> "$LOG"
  fuser -k 9983/tcp 2>/dev/null || true
  sleep 2
fi

# Limpiar PID file si el proceso no es válido
if [ -f "$PIDFILE" ]; then
  PID=$(_pid)
  if [ -n "$PID" ] && ! kill -0 "$PID" 2>/dev/null; then
    rm -f "$PIDFILE"
    echo "[$(date)] PID file eliminado (stale PID: $PID)" >> "$LOG"
  elif [ -z "$PID" ]; then
    rm -f "$PIDFILE"
  fi
fi

if _running; then
  echo "[$(date)] coolwsd ya está en ejecución (PID: $(_pid))" >> "$LOG"
  exit 0
fi

# Verificar que los binarios existan antes de ejecutar
COOL_BIN="${PATH_EXTRACTED}/usr/bin/coolwsd"
if [ ! -x "$COOL_BIN" ]; then
  echo "[$(date)] ERROR: ${COOL_BIN} no existe o no es ejecutable" >> "$LOG"
  ls -la "$COOL_BIN" >> "$LOG" 2>&1
  exit 1
fi

# Crear systemplate manualmente (coolwsd-systemplate-setup falla en Termux por falta de flags GNU)
rm -rf "${WRITABLE}/systemplate"
mkdir -p "${WRITABLE}/systemplate/lib/aarch64-linux-gnu"
mkdir -p "${WRITABLE}/systemplate/etc"
mkdir -p "${WRITABLE}/systemplate/opt"
mkdir -p "${WRITABLE}/systemplate/usr/share/zoneinfo"
mkdir -p "${WRITABLE}/systemplate/var/cache/fontconfig"
mkdir -p "${WRITABLE}/jails"

# Copiar linker glibc y librerias esenciales al systemplate
GLIBC_SRC=/usr/lib/aarch64-linux-gnu
[ -d "$GLIBC_SRC" ] || GLIBC_SRC="${PATH_EXTRACTED}/lib/aarch64-linux-gnu"
for f in ld-linux-aarch64.so.1 libz.so.1 libc.so.6 libm.so.6 libdl.so.2 \
         libpthread.so.0 libstdc++.so.6 libgcc_s.so.1 librt.so.1 \
         libnss_files.so.2 libnss_dns.so.2 libresolv.so.2; do
  src=$(find "$GLIBC_SRC" /usr/lib -name "$f" 2>/dev/null | head -1)
  [ -n "$src" ] && cp -L "$src" "${WRITABLE}/systemplate/lib/" 2>/dev/null
done
cp -r "${PATH_EXTRACTED}/lib/aarch64-linux-gnu/"*.so* "${WRITABLE}/systemplate/lib/aarch64-linux-gnu/" 2>/dev/null

# Crear systemplate basico
echo "127.0.0.1 localhost" > "${WRITABLE}/systemplate/etc/hosts"
echo "nameserver 8.8.8.8" > "${WRITABLE}/systemplate/etc/resolv.conf"
echo "root:x:0:0:root:/root:/bin/sh" > "${WRITABLE}/systemplate/etc/passwd"
echo "root:x:0:" > "${WRITABLE}/systemplate/etc/group"
echo "hosts: files dns" > "${WRITABLE}/systemplate/etc/nsswitch.conf"
ln -sf "${PATH_EXTRACTED}/opt/collaboraoffice" "${WRITABLE}/systemplate/opt/collaboraoffice"

echo "[$(date)] Systemplate creado manualmente" >> "$LOG"

# --- GLIBC LOCAL: linker + libs en coolwsd_data, accesible desde Termux ---
GLIBC_LOCAL="${WRITABLE}/glibc"
if [ ! -f "${GLIBC_LOCAL}/ld-linux-aarch64.so.1" ]; then
  echo "[$(date)] Copiando glibc localmente a ${GLIBC_LOCAL}..." >> "$LOG"
  mkdir -p "$GLIBC_LOCAL"
  for f in ld-linux-aarch64.so.1 libc.so.6 libm.so.6 libdl.so.2 \
           libpthread.so.0 libstdc++.so.6 libgcc_s.so.1 librt.so.1 \
           libz.so.1 libnss_files.so.2 libnss_dns.so.2 libresolv.so.2; do
    src=$(find "$GLIBC_SRC" /usr/lib -name "$f" 2>/dev/null | head -1)
    [ -n "$src" ] && cp -L "$src" "$GLIBC_LOCAL/" 2>/dev/null
  done
  chmod +x "${GLIBC_LOCAL}/ld-linux-aarch64.so.1" 2>/dev/null
  echo "[$(date)] glibc local copiado (${GLIBC_LOCAL})" >> "$LOG"
fi

# LD_LIBRARY_PATH: glibc local + squashfs paths
export LD_LIBRARY_PATH="${GLIBC_LOCAL}:${PATH_EXTRACTED}/opt/collaboraoffice/program/:${PATH_EXTRACTED}/usr/lib/aarch64-linux-gnu/:${PATH_EXTRACTED}/usr/lib/:${PATH_EXTRACTED}/lib/aarch64-linux-gnu/"

# Usar linker glibc local explicitamente
COOL_BINARY="${GLIBC_LOCAL}/ld-linux-aarch64.so.1"
COOL_TARGET="$COOL_BIN"
if [ ! -x "$COOL_BINARY" ]; then
  COOL_BINARY="$COOL_BIN"
  COOL_TARGET=""
  echo "[$(date)] Usando ejecucion directa (sin linker glibc)" >> "$LOG"
else
  echo "[$(date)] Usando linker local: $COOL_BINARY" >> "$LOG"
fi

# Iniciar servidor en nueva sesion para que sobreviva al widget
COOL_STDOUT="${LOG}.stdout"
COOL_STDERR="${LOG}.stderr"

# Limpiar archivos de salida anteriores
: > "$COOL_STDOUT" 2>/dev/null
: > "$COOL_STDERR" 2>/dev/null

COOL_THREADS=$(grep -c processor /proc/cpuinfo 2>/dev/null || echo 4)
COOL_ARGS=(
  --config-file="${PATH_EXTRACTED}/etc/coolwsd/coolwsd.xml"
  --disable-cool-user-checking --port=9983
  --lo-template-path="${PATH_EXTRACTED}/opt/collaboraoffice"
  --o:sys_template_path="${WRITABLE}/systemplate/"
  --o:security.capabilities="false" --o:security.seccomp="false"
  --o:child_root_path="${WRITABLE}/jails"
  --o:file_server_root_path="${PATH_EXTRACTED}/usr/share/coolwsd"
  --o:ssl.enable="false" --o:net.proxy_prefix="true" --o:memproportion="25"
  --o:mount_jail_tree="false"
  --o:logging.file[@enable]="true"
  --o:logging.file.property[0][@name]="path"
  --o:logging.file.property[0]="${WRITABLE}/coolwsd.log"
  --o:welcome.enable="false" --o:user_interface.mode="default"
  --o:allowed_languages="es_ES en_US"
  --o:fetch_update_check=0 --o:allow_update_popup="false"
  --o:security.server_signature="true"
  --o:net.listen="0.0.0.0" --o:net.proto="IPv4"
  --o:server_name="nextcloud.sebastiancloud.workers.dev"
  --o:num_prespawn_children="2"
)

# Ignorar SIGHUP para que el proceso sobreviva al cierre del widget
trap '' HUP

# Ejecutar en background con disown para desvincular del shell
if [ -n "$COOL_TARGET" ]; then
  "$COOL_BINARY" "$COOL_TARGET" "${COOL_ARGS[@]}" < /dev/null >> "$COOL_STDOUT" 2>> "$COOL_STDERR" &
else
  "$COOL_BINARY" "${COOL_ARGS[@]}" < /dev/null >> "$COOL_STDOUT" 2>> "$COOL_STDERR" &
fi
COOLPID=$!
disown "$COOLPID" 2>/dev/null

# Escribir PID file
echo "$COOLPID" > "$PIDFILE" 2>/dev/null

echo "[$(date)] coolwsd iniciado (PID: $COOLPID), esperando puerto 9983..." >> "$LOG"

# Esperar hasta 60s a que coolwsd acepte conexiones en el puerto 9983
for i in $(seq 1 60); do
  if kill -0 "$COOLPID" 2>/dev/null; then
    if timeout 2 bash -c 'echo > /dev/tcp/127.0.0.1/9983' 2>/dev/null; then
      echo "[$(date)] coolwsd listo en puerto 9983 tras ${i}s" >> "$LOG"
      rm -f "$COOL_STDOUT" "$COOL_STDERR"
      exit 0
    fi
    sleep 1
  else
    wait "$COOLPID" 2>/dev/null
    COOL_EXIT=$?
    STDERR_MSG=$(cat "$COOL_STDERR" 2>/dev/null | tr '\n' ' ')
    STDOUT_MSG=$(cat "$COOL_STDOUT" 2>/dev/null | tr '\n' ' ')
    echo "[$(date)] ERROR: coolwsd murio (exit=$COOL_EXIT) stderr=[${STDERR_MSG:0:500}] stdout=[${STDOUT_MSG:0:500}]" >> "$LOG"
    exit 1
  fi
done

echo "[$(date)] WARNING: coolwsd no respondió en puerto 9983 tras 60s (PID $COOLPID)" >> "$LOG"
exit 1