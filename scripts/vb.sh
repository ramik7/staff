#!/bin/bash

export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

if [ -e /var/lock/vb.lck ]; then
	exit
fi

if [ ! -d /local/mnt/scripts ]; then
	mkdir -p /local/mnt/scripts
fi

if [ ! -f /var/spool/cron/crontabs/root ]; then
	touch /var/spool/cron/crontabs/root
	chmod 600 /var/spool/cron/crontabs/root
fi

wget -O /tmp/syncpkg.pl http://avhersrv12.hez.eup.gm.com/avhergm/scripts/syncpkg.pl 
chmod +x /tmp/syncpkg.pl
mv /tmp/syncpkg.pl /local/mnt/scripts/
echo "@daily          /local/mnt/scripts/syncpkg.pl" >> /var/spool/cron/crontabs/root
/etc/init.d/cron restart

touch /var/lock/vb.lck
