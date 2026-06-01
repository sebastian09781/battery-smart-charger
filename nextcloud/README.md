# Nextcloud en Termux

Scripts y configuración para ejecutar Nextcloud 24/7 en Android con Termux.

## Componentes

| Archivo | Función |
|---|---|
| `scripts/start_nextcloud.sh` | Inicia Nextcloud completo (DB + Redis + PHP + tunnel) |
| `scripts/stop_nextcloud.sh` | Detiene todos los servicios |
| `scripts/restart_nextcloud.sh` | Reinicia servicios |
| `scripts/status_nextcloud.sh` | Muestra estado de todos los servicios |
| `scripts/backup_nextcloud.sh` | Respalda configuración y base de datos |
| `scripts/sync_nextcloud.sh` | Sincroniza datos |
| `scripts/cron_loop.sh` | Loop de tareas programadas |
| `scripts/update_worker.sh` | Actualiza Cloudflare Worker |
| `scripts/start_tunnel.sh` | Inicia túnel Cloudflare |
| `scripts/install_php_modules.sh` | Instala módulos PHP faltantes |
| `scripts/test_mariadb.sh` | Verifica MariaDB |
| `scripts/coolwsd_start.sh` | Inicia LibreOffice Online |
| `scripts/coolwsd_stop.sh` | Detiene LibreOffice Online |
| `boot/start_nextcloud.sh` | Auto-arranque al iniciar el teléfono |
| `shortcuts/Iniciar Nextcloud` | Widget/shortcut para iniciar |
| `shortcuts/Detener Nextcloud` | Widget/shortcut para detener |
| `shortcuts/Estado Nextcloud` | Widget/shortcut para ver estado |
| `shortcuts/Reiniciar Nextcloud` | Widget/shortcut para reiniciar |

## Instalación

```bash
# Copiar scripts
cp -r scripts ~/
chmod +x ~/scripts/*.sh

# Copiar shortcuts para Termux:Widget/Tasker
cp shortcuts/* ~/.shortcuts/
chmod +x ~/.shortcuts/*

# Copiar auto-arranque
cp boot/start_nextcloud.sh ~/.termux/boot/
chmod +x ~/.termux/boot/*.sh
```

## Uso

```bash
# Iniciar
bash ~/scripts/start_nextcloud.sh

# Ver estado
bash ~/scripts/status_nextcloud.sh

# Detener
bash ~/scripts/stop_nextcloud.sh
```

## Configuración

Copia y edita los archivos de ejemplo:
- `config.php.example → nextcloud_html/config/config.php`
- `nc_vars.env.example → ~/nc_vars.env`

## Requisitos

- Termux con MariaDB, PHP, Redis, Nginx
- Cloudflare cuenta (para túnel público)
- 2GB+ RAM libre
- 4GB+ almacenamiento
