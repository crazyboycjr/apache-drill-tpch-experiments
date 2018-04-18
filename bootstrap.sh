#!/bin/bash

drillbit.sh restart

sleep 5

drill-conf -f /tpch_create_table.sql

queries_arr=(01.q  03.q  04.q  05.q  06.q  07.q  08.q  09.q  10.q  11.q  12.q  13.q  14.q  15a.q  15.q  15c.q  16.q  17.q  18.q  19.q  20.q)

# drill-conf -f /tpch-queries/03.q |& grep seconds | tail -n1 | sed "s/\(.*\)/$query: \1/" | tee -a /tmp/benchmark_results.txt
# The output should be like: 03.q: 10 rows selected (10.758 seconds)
for query in ${queries_arr[@]}; do
	drill-conf -f /tpch-queries/$query |& grep seconds | tail -n1 | sed "s/\(.*\)/$query: \1/" | tee -a /tmp/benchmark_results.txt
done

#cp /tmp/benchmark_results.txt /results/benchmark_results_single.txt
for i in {0..9999}; do
	if [ ! -f results/benchmark_results_single_$i.txt ]; then
		cp /tmp/benchmark_results.txt results/benchmark_results_single_$i.txt
		break
	fi
done
