#!/data/data/com.termux/files/usr/bin/python3
"""
Obtiene los datos de dispositivos Tuya desde la nube.
Requiere Access ID y Access Secret del proyecto Tuya IoT.
"""
import tinytuya

API_REGION = "us"   # us, eu, cn, in
API_KEY = "CHANGE_ME"
API_SECRET = "CHANGE_ME"

c = tinytuya.Cloud(apiRegion=API_REGION, apiKey=API_KEY, apiSecret=API_SECRET)
result = c.getdevices()
devices = result.get("devices") if isinstance(result, dict) else result

if not devices:
    print("No se encontraron dispositivos.")
    print("Vincula tu app en: Cloud → Projects → tu proyecto → Devices → Link Tuya App Account")
else:
    print(f"Se encontraron {len(devices)} dispositivo(s):\n")
    for d in devices:
        print(f"  Nombre:    {d.get('name')}")
        print(f"  Device ID: {d.get('id')}")
        print(f"  Local Key: {d.get('key')}")
        print(f"  Producto:  {d.get('product_name')}")
        print()
