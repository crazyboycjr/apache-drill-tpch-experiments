#!/bin/bash

# This should be run on correct host, such 192.168.0.54
docker run --name zookeeper --net=host --restart always -d zookeeper
