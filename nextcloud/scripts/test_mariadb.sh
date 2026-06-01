#!/data/data/com.termux/files/usr/bin/bash
PREFIX=/data/data/com.termux/files/usr
pkill -9 -f "[m]ariadbd" 2>/dev/null
sleep 2
echo "Starting mariadb..."
export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu
/usr/sbin/mariadbd --user=root --datadir=$PREFIX/var/lib/mysql --port=3306 > /dev/null 2>&1 &
disown
for i in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  if /usr/bin/mysqladmin -h 127.0.0.1 ping --silent 2>/dev/null; then
    echo "SUCCESS after ${i}s"
    exit 0
  fi
done
echo "FAILED"
exit 1
