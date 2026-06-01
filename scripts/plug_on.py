#!/data/data/com.termux/files/usr/bin/python3
import tinytuya, sys, os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
from tuya_config import DEVICE_ID, IP_ADDRESS, LOCAL_KEY, VERSION

try:
    d = tinytuya.OutletDevice(DEVICE_ID, IP_ADDRESS, LOCAL_KEY)
    d.set_version(VERSION)
    d.turn_on()
    print("ON_OK")
except Exception as e:
    print(f"ON_ERROR: {e}")
    sys.exit(1)
