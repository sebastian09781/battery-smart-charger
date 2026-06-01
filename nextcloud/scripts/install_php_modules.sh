#!/data/data/com.termux/files/usr/bin/bash
# Instala los módulos PHP faltantes para Nextcloud
# Ejecutar DESDE TERMUX (no como root, no desde widget)

echo "Instalando módulos PHP para Nextcloud..."
pkg install php-apcu php-sysvsem php-imagick -y

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Módulos instalados. Ahora reinicia Nextcloud:"
  echo "   Usa el widget 'Iniciar Nextcloud' o ejecuta:"
  echo "   ~/scripts/stop_nextcloud.sh && ~/scripts/start_nextcloud.sh"
else
  echo "❌ Error al instalar. Revisa los mensajes arriba."
fi
