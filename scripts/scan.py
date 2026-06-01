#!/data/data/com.termux/files/usr/bin/python3
"""Escanea la red local en busca de dispositivos Tuya."""
import tinytuya

devices = tinytuya.deviceScan()
if not devices:
    print("No se encontraron dispositivos Tuya en la red.")
    print("Asegúrate de que el enchufe esté encendido y en la misma WiFi.")
else:
    for gw, info in devices.items():
        print(f"gwId (Device ID): {gw}")
        print(f"  IP:      {info.get('ip')}")
        print(f"  Versión: {info.get('version')}")
        print(f"  Producto: {info.get('productName')}")
        print()
