#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== Instalación automática del proyecto Tuya Cargador ==="
echo ""

# Dependencias
echo "[1/3] Instalando paquetes..."
pkg update -y
pkg install -y python termux-api

echo "[2/3] Instalando tinytuya..."
pip install tinytuya

# Directorios
echo "[3/3] Preparando directorios..."
mkdir -p ~/.termux/tasker ~/.termux/widget ~/.shortcuts
chmod +x scripts/*.py
chmod +x widgets/*.sh shortcuts/*.sh

# Copiar scripts a sus ubicaciones
cp scripts/plug_on.py scripts/plug_off.py ~/.termux/tasker/
cp scripts/scan.py ~/.termux/tasker/
cp widgets/* ~/.termux/widget/
cp shortcuts/* ~/.shortcuts/

# Config
if [ ! -f ~/.termux/tasker/tuya_config.py ]; then
    cp scripts/tuya_config.py.example ~/.termux/tasker/tuya_config.py
    echo "  → Edita ~/.termux/tasker/tuya_config.py con los datos de tu enchufe"
fi

echo ""
echo "=== Instalación completada ==="
echo ""
echo "Siguientes pasos:"
echo "  1. Editar ~/.termux/tasker/tuya_config.py"
echo "  2. Probar: python ~/.termux/tasker/plug_on.py"
echo "  3. Probar: python ~/.termux/tasker/plug_off.py"
echo "  4. Configurar Tasker (ver README.md)"
