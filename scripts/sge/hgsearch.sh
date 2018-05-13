#!/bin/bash -f

export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
export PATH=${PATH}:/proj/sge/uge854/bin/lx-amd64

. /proj/sge/uge854/REDA/common/settings.sh

if [ $# -ne 1 ]; then
	echo ""; echo "Enter $0 hostname"
	exit
fi

for hgrp in `qconf -shgrpl`; do
	qconf -shgrp_tree $hgrp | grep $1 >& /dev/null
	if [ $? -eq 0 ]; then
		echo "$hgrp"
	fi
done
