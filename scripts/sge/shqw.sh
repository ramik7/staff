#!/bin/bash -f

export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/unix_srv/local/scripts/uge

. /proj/sge/uge83/UREDA/common/settings.sh
for pp in `qstat -u \* | grep qw | awk '{print $1}'`; do
	now=`qstat -u \* | grep qw | grep $pp | awk '{print $4" "$6" "$7}'`
	sub=`qstat -ext -j $pp | grep sge_o_log_name | awk '{print $2}'`
	echo -ne "[$pp],[$sub],[$now] "
	echo -ne "\t"
	qstat -ext -j $pp | grep hard | grep resou
done
