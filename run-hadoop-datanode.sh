#!/bin/bash

docker run -d --restart always -it --name datanode --net=host --env HADOOP_ZOOKEEPER_QUORUM='192.168.0.54:2181' --env HADOOP_NAMENODE1_HOSTNAME='192.168.0.51' smizy/hadoop-base datanode
