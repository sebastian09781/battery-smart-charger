#!/data/data/com.termux/files/usr/bin/bash
python3 -c "
import tinytuya
d = tinytuya.OutletDevice('CHANGE_ME', 'CHANGE_ME', 'CHANGE_ME')
d.set_version(3.3)
s = d.status()
if s.get('dps', {}).get('1'):
    print('Estado: ENCENDIDO')
else:
    print('Estado: APAGADO')
" 2>/dev/null || echo "Estado: ERROR - sin conexión"
