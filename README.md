# Control Automático de Cargador con Tuya + Termux + Tasker

Proyecto para controlar un enchufe inteligente Tuya automáticamente según el nivel de batería de tu Android, ideal para mantener un servidor 24/7 sin degradar la batería.

## Características

- ✅ Enciende el cargador cuando la batería baja del **30%**
- ✅ Apaga el cargador cuando la batería llega al **80%**
- ✅ Control local por WiFi (sin depender de la nube)
- ✅ Widgets para control manual desde la pantalla de inicio
- ✅ Automatización vía Tasker o cron interna
- ✅ Compatible con servidores Android 24/7 (Nextcloud, Home Assistant, etc.)

## Índice

1. [Instalación de Termux](#1-instalación-de-termux)
2. [Termux Add-ons](#2-termux-add-ons)
3. [Instalación de Tasker](#3-instalación-de-tasker)
4. [Configurar Tuya IoT](#4-configurar-tuya-iot)
5. [Scripts de control](#5-scripts-de-control)
6. [Perfiles de Tasker](#6-perfiles-de-tasker)
7. [Widgets](#7-widgets)
8. [Rango de batería recomendado](#8-rango-de-batería-recomendado)

---

## 1. Instalación de Termux

> **IMPORTANTE:** Instala Termux desde **F-Droid**, NO desde Google Play Store.

```bash
# Descarga: https://f-droid.org/packages/com.termux/
# Abre la app y actualiza:
pkg update && pkg upgrade -y
```

## 2. Termux Add-ons

```bash
# Termux:API  - para leer estado de batería
pkg install termux-api

# Termux:Widget - para widgets en pantalla inicio
# Descargar APK: https://f-droid.org/packages/com.termux.widget/

# Termux:Tasker - para integración con Tasker
# Descargar APK: https://f-droid.org/packages/com.termux.tasker/

# Termux:Boot - para ejecutar scripts al arrancar
# Descargar APK: https://f-droid.org/packages/com.termux.boot/

# Ver permisos de Termux:Tasker
termux-permissions grant com.termux.permission.RUN_COMMAND net.dinglisch.android.taskerm
```

## 3. Instalación de Tasker

Descarga Tasker desde Google Play Store:
- https://play.google.com/store/apps/details?id=net.dinglisch.android.taskerm

## 4. Configurar Tuya IoT

### 4.1 Crear cuenta de desarrollador

1. Ve a [https://iot.tuya.com](https://iot.tuya.com)
2. Regístrate con el mismo email de tu app Tuya Smart / Smart Life
3. Crea un **Cloud Project**:
   - Nombre: cualquiera
   - Industry: **Smart Home**
   - Data Center: el más cercano a ti (us/eu/cn/in)

### 4.2 Vincular la app

1. En tu proyecto: `Devices → Link Tuya App Account → Add App Account`
2. Escanea el QR con tu app **Tuya Smart** o **Smart Life**
3. Las credenciales aparecerán en: `Overview → Authorization Key`

### 4.3 Obtener datos del enchufe

Copia `tuya_config.py.example` como `tuya_config.py` y completa con los valores del paso anterior, luego ejecuta:

```bash
python fetch_keys.py
```

Esto te dará el **Device ID** y **Local Key** de tu enchufe.

## 5. Scripts de control

### 5.1 Instalar dependencias

```bash
pip install tinytuya
```

### 5.2 Configurar

Edita `tuya_config.py`:

```python
DEVICE_ID = "27051506ecfabca45f0e"  # ID de tu enchufe
IP_ADDRESS = "192.168.10.28"         # IP de tu enchufe
LOCAL_KEY = ".|>Wos7M@#mL.X[N"       # Local Key
VERSION = 3.3                         # Versión del protocolo
```

### 5.3 Probar

```bash
python plug_on.py   # Enciende
python plug_off.py  # Apaga
```

## 6. Perfiles de Tasker

### 6.1 Copiar shortcuts

```bash
mkdir -p ~/.shortcuts
cp shortcuts/* ~/.shortcuts/
chmod +x ~/.shortcuts/*
```

### 6.2 Crear Perfil: Encender al 30%

1. Abre **Tasker** → pestaña **Profiles**
2. `+` → `State` → `System` → `Battery Level`
   - `From: 30`, `To: 30` → ⬅️
3. Nueva tarea → `+` → `Plugin` → `Termux:Tasker`
4. Configuration → escribe como **command**:
   ```
   bash /data/data/com.termux/files/home/.shortcuts/encender_cargador.sh
   ```

### 6.3 Crear Perfil: Apagar al 80%

1. `+` → `State` → `System` → `Battery Level`
   - `From: 80`, `To: 80` → ⬅️
2. Nueva tarea → `+` → `Plugin` → `Termux:Tasker`
3. Configuration → escribe como **command**:
   ```
   bash /data/data/com.termux/files/home/.shortcuts/apagar_cargador.sh
   ```

### 6.4 Desactivar optimización de batería

```
Ajustes Android → Apps → Tasker → Batería → Sin restricción
Ajustes Android → Apps → Termux → Batería → Sin restricción
```

## 7. Widgets

Para acceso manual desde la pantalla de inicio:

```bash
cp widgets/* ~/.termux/widget/
chmod +x ~/.termux/widget/*
```

1. En el escritorio Android, mantén presionado → **Widgets**
2. Busca **Termux:Widget**
3. Arrastra un widget → selecciona el script deseado

| Widget | Función |
|---|---|
| `encender_cargador.sh` | Enciende el enchufe |
| `apagar_cargador.sh` | Apaga el enchufe |
| `estado_cargador.sh` | Muestra estado actual |

## 8. Nextcloud (servidor 24/7)

Este proyecto también incluye la configuración completa para ejecutar **Nextcloud** en Termux como servidor 24/7.

### 8.1 Copiar scripts

```bash
cp -r nextcloud/scripts/* ~/scripts/
chmod +x ~/scripts/*.sh
```

### 8.2 Configurar variables de entorno

```bash
cp nextcloud/nc_vars.env.example ~/nc_vars.env
nano ~/nc_vars.env  # Completa con tus datos
```

### 8.3 Iniciar Nextcloud

```bash
bash ~/scripts/start_nextcloud.sh
```

### 8.4 Auto-arranque al boot

```bash
cp nextcloud/boot/start_nextcloud.sh ~/.termux/boot/
chmod +x ~/.termux/boot/*.sh
```

### 8.5 Widgets

```bash
cp nextcloud/shortcuts/* ~/.shortcuts/
chmod +x ~/.shortcuts/*
```

### 8.6 Servicios incluidos

| Script | Función |
|---|---|
| `start_nextcloud.sh` | Inicia DB + Redis + PHP + tunneling |
| `stop_nextcloud.sh` | Detiene todos los servicios |
| `status_nextcloud.sh` | Estado de todos los servicios |
| `backup_nextcloud.sh` | Respaldo de datos y configuración |
| `start_tunnel.sh` | Túnel Cloudflare para acceso público |

Ver `nextcloud/README.md` para la documentación completa.

## 9. Rango de batería recomendado

Para máxima vida útil de la batería Li-ion en un servidor 24/7:

| | Mínimo | Máximo |
|---|---|---|
| **Recomendado** | 30% | 80% |
| **Óptimo absoluto** | 35% | 75% |
| **Evitar** | <10% | 100% |

Mantener la batería entre 30-80% reduce el estrés químico y alarga la vida útil 2-3x comparado con ciclos 0-100%.

---

## Estructura del proyecto

```
proyecto-tuya/
├── README.md
├── scripts/
│   ├── setup.sh            # Instalación automática
│   ├── tuya_config.py.example  # Plantilla de configuración
│   ├── fetch_keys.py       # Obtener datos desde nube Tuya
│   ├── plug_on.py          # Encender enchufe
│   ├── plug_off.py         # Apagar enchufe
│   ├── scan.py             # Escanear dispositivos en red
│   └── requirements.txt    # Dependencias Python
├── widgets/
│   ├── encender_cargador.sh
│   ├── apagar_cargador.sh
│   └── estado_cargador.sh
├── shortcuts/
│   ├── encender_cargador.sh
│   └── apagar_cargador.sh
└── nextcloud/
    ├── README.md
    ├── nc_vars.env.example
    ├── config.php.example
    ├── scripts/          # Gestión Nextcloud
    ├── shortcuts/        # Widgets Nextcloud
    └── boot/             # Auto-arranque
```

## Licencia

MIT
