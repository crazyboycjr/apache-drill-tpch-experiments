#!/bin/bash

# 15000 taks about 15 secs to finish
for i in {1..15000}; do printf '%s %s\n' `date +%s%N` `ethtool -S eth10 | grep rx_prio0_bytes | awk '{print $2}'`; done | tee /tmp/rcv_data &
for i in {1..15000}; do printf '%s %s\n' `date +%s%N` `ethtool -S eth10 | grep tx_prio0_bytes | awk '{print $2}'`; done | tee /tmp/xmit_data &
wait
./draw.py
echo 'Done'
