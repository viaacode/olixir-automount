#!/bin/sh
echo mount disk $DEVNAME to $dir_name >> /var/log/olixir.log
echo `date` >> /var/log/olixir.log
ID_SERIAL_SHORT=${ID_SERIAL_SHORT} ID_PATH=${ID_PATH} /usr/local/bin/olixir_mounter.sh add $DEVNAME >> /var/log/olixir.log

