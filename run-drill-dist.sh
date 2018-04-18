#!/bin/bash

#HOSTNAME=$1
#
#if [ -z $HOSTNAME ]; then
#	echo "Usage: $0 [hostname]"
#	exit -1
#fi

docker run -d --restart always --name apache-drill --net=host -it -v /home/cjr/apache-drill/drill-override.conf:/usr/local/apache-drill-1.13.0/conf/drill-override.conf -v /home/cjr/apache-drill/tpch-queries:/tpch-queries -v /home/cjr/apache-drill/tpch_create_table.sql:/tpch_create_table.sql -v /home/cjr/apache-drill/bootstrap.sh:/bootstrap.sh -v /home/cjr/apache-drill/results:/results smizy/apache-drill drillbit.sh run
