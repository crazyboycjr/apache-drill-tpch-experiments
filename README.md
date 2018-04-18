# Apache Drill TPC-H Experiments

This project contains scripts and instructions which runs TPC-H on Apache Drill.

这个项目包含了用Apache Drill运行分布式代码的脚本和指示。具体做的事情是，在5台机器上从零搭建Apache Drill，将其运行于容器中，并进行benchmark.


## Environment
- OS / Kernel: Debian GNU/Linux 8.9, kernel 4.9.0
- CPU: Intel(R) Xeon(R) E5-2650 v4, 48 cores per host, 2 NUMA nodes
- Memory: 128GB
- Network:
	- Every node has two NICs: IP address on mgmt port ranges in 10.2.96.[50-54] and corresponding IP address on discrete NIC ranges in 192.168.0.[50-54]
	- The discrete NIC is 100Gbps per port


## Docker images
- [smizy/apache-drill](https://hub.docker.com/r/smizy/apache-drill/) Apache Drill 1.13.0
- [smizy/hadoop-base](https://hub.docker.com/r/smizy/hadoop-base/) Apache Hadoop 2.7.4
- [zookeeper](https://hub.docker.com/_/zookeeper/) The official docker image

As far as I know, apache-drill docker image maintained by harisekhon is quite bad so that when drill parses parquet file, it will throw a memory leak execption. It takes me much time to figure out the problem.
Images maintained by smizy is much better.


## TPC-H Dataset
The TPC-H Tools can be download via this [link](https://cjr.host/download/TPC-H_Tools_v2.17.3.zip).

Uncompress the file and go to `dbgen` directory, change the `makefile.suite` like below
```
...
CC      = gcc
# Current values for DATABASE are: INFORMIX, DB2, TDAT (Teradata)
#                                  SQLSERVER, SYBASE, ORACLE, VECTORWISE
# Current values for MACHINE are:  ATT, DOS, HP, IBM, ICL, MVS, 
#                                  SGI, SUN, U2200, VMS, LINUX, WIN32 
# Current values for WORKLOAD are:  TPCH
DATABASE= ORACLE
MACHINE = LINUX
WORKLOAD = TPCH
...
```
and `make`. After make finishes, use `./dbgen -vf -s 1` to generate 1GB data. This data should have `.tbl` suffix, move these files to `tpch-data/`

The benchmark queries and create table queries are extracted from [drill-perf-test-framework](https://github.com/mapr/drill-perf-test-framework). I made some changes to them for my environment.


## Standalone and single node Mode
_More documents_ [here](https://drill.apache.org/docs/)

Running in embedded mode is quite simple and not easy to come into faults.
Just run the container and expose port 8047
```bash
docker run --rm -it -p 8047:8047 smizy/apache-drill drill-embedded
```
and we can go http://ipaddress:8047/ to access web console.

---
But running in embedded mode is boring. We can do a little more things to make Apache Drill run in distributed mode with only one node in the cluste.

First, start a zookeeper instance on 192.168.0.54
```
docker run --name zookeeper --net=host --restart always -d zookeeper
or just type
./run-zookeeper.sh
```

Then, modify `drill-override.conf` like below
```
drill.exec: {
  cluster-id: "rdma-testbed",
  rpc: {
    use.ip: true
  },
  zk.connect: "192.168.0.54:2181"
}
```

Finally, we map the `drill-override.conf` to inside container and run `drillbit.sh`
```bash
docker run -d --name apache-drill -it \
        -p 8047:8047 \
        -v /home/cjr/apache-drill/drill-override.conf:/usr/local/apache-drill-1.13.0/conf/drill-override.conf \
        smizy/apache-drill \
        drillbit.sh run
```

Then either access the web console or start a command-line shell
```
docker exec -it apache-drill drill-conf
```
On successful run, the prompt should be like `0: jdbc:drill:> ` instead of `0: jdbc:drill:zk=local> `(embedded mode)

### Run Benchmark on single node
Here we let `dfs`(Apache drill's storage plugin) to choose local filesystem as data source.

In drill-conf shell, we can use grammar `!run <path>` to run a sql script, so just type
```
0: jdbc:drill:> !run /tpch_create_table.sql
```
to create tables and import the data located in `/tpch-data/`. The script will use `dfs.tmp` as database because it is writable in default.

To run the benchmark query,
```
0: jdbc:drill:> !run /tpch-queries/01.q
1/2          use dfs.tmp;
+-------+--------------------------------------+
|  ok   |               summary                |
+-------+--------------------------------------+
| true  | Default schema changed to [dfs.tmp]  |
+-------+--------------------------------------+
1 row selected (0.105 seconds)
2/2          select
l_returnflag,
l_linestatus,
sum(l_quantity) as sum_qty,
sum(l_extendedprice) as sum_base_price,
sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
avg(l_quantity) as avg_qty,
avg(l_extendedprice) as avg_price,
avg(l_discount) as avg_disc,
count(*) as count_order
from
lineitem
where
l_shipdate <= date '1998-12-01' - interval '120' day (3)
group by
l_returnflag,
l_linestatus
order by
l_returnflag,
l_linestatus;
+---------------+---------------+--------------+------------------------+------------------------+------------------------+---------------------+--------------------+-----------------------+--------------+
| l_returnflag  | l_linestatus  |   sum_qty    |     sum_base_price     |     sum_disc_price     |       sum_charge       |       avg_qty       |     avg_price      |       avg_disc        | count_order  |
+---------------+---------------+--------------+------------------------+------------------------+------------------------+---------------------+--------------------+-----------------------+--------------+
| A             | F             | 3.7734107E7  | 5.658655440073042E10   | 5.375825713486977E10   | 5.5909065222827415E10  | 25.522005853257337  | 38273.12973462196  | 0.04998529583846936   | 1478493      |
| N             | F             | 991417.0     | 1.4875047103800015E9   | 1.4130821680541005E9   | 1.469649223194375E9    | 25.516471920522985  | 38284.46776084835  | 0.05009342667421577   | 38854        |
| N             | O             | 7.2798693E7  | 1.0918605603816025E11  | 1.0372791027784682E11  | 1.078808064265123E11   | 25.5017571306365    | 38248.43782754766  | 0.04999991942984775   | 2854654      |
| R             | F             | 3.7719753E7  | 5.6568041380899445E10  | 5.374129268460387E10   | 5.588961911983182E10   | 25.50579361269077   | 38250.85462609928  | 0.050009405830198715  | 1478870      |
+---------------+---------------+--------------+------------------------+------------------------+------------------------+---------------------+--------------------+-----------------------+--------------+
4 rows selected (14.659 seconds)
```

**Note**: _If you get an error tells lack of memory, please open http://ipaddress:8047/options and check_ `planner.memory.percent_per_query`_, update the value to 1.0_


I wrote a script called `bootstrap.sh` to import data and run queries sequentially. So we can simply run `./bench-drill-local.sh` which called `bootstrap.sh` to get the benchmark result.
The benchmark result will be named as `benchmark_results_single_%d.txt`, where `%d` is the trail number.


## Distributed Mode

Now we step into the distributed world!

Basically, 2 things are needed to make Apache Drill distributed.
1. Use a distributed data source, otherwise the local disk and the single storage node's outbound network becomes bottleneck
2. Start Drillbit process on each node to distribute query work across the cluster to maximize data locality.

### 1. Prepare HDFS

Apache Drill provides various Storage Plugin, such as HBase, Hive, MongoDB and Kafka etc.
The Apache Drill already have a internal data storage structure, which may be redundant (I'm not sure) to what HBase and Hive do.
So I decide to choose raw HDFS as the storage layer.

For a minimized configuration, on a 5 nodes cluster, we do not need redundancy. So I only 1 zookeeper, 1 hadoop namenode, and 5 datanodes(each datanode per node in cluster).

FOr example, I run namenode on 192.168.0.51,
```
./run-hadoop-namenode.sh
```
and run
```
./run-hadoop-datanode.sh
```
on all nodes.

After hadoop started, create some directories in HDFS, and copy `tpch-data/*.tbl` to HDFS
```
docker exec -it datanode hadoop fs -mkdir /tmp
docker exec -it datanode hadoop fs -mkdir /tpch-data
docker exec -it datanode hadoop fs -put tpch-data/ /tpch-data
docker exec -it datanode hadoop fs -ls /tpch-data

Found 8 items
-rw-r--r--   3 root hadoop   24346144 2018-04-18 05:33 /tpch-data/customer.tbl
-rw-r--r--   3 root hadoop  759863287 2018-04-18 05:33 /tpch-data/lineitem.tbl
-rw-r--r--   3 root hadoop       2224 2018-04-18 05:33 /tpch-data/nation.tbl
-rw-r--r--   3 root hadoop  171952161 2018-04-18 05:33 /tpch-data/orders.tbl
-rw-r--r--   3 root hadoop   24135125 2018-04-18 05:33 /tpch-data/part.tbl
-rw-r--r--   3 root hadoop  118984616 2018-04-18 05:33 /tpch-data/partsupp.tbl
-rw-r--r--   3 root hadoop        389 2018-04-18 05:33 /tpch-data/region.tbl
-rw-r--r--   3 root hadoop    1409184 2018-04-18 05:33 /tpch-data/supplier.tbl
```

### 2. Connect Drill to HDFS
To connect Apache Drill to HDFS, we need to update the dfs storage plugin. Go to http://ipaddress:8047/storage/dfs, and modify `"connection": "hdfs://192.168.0.51:8020/"`, or you just copy the content of `storage.dfs.conf` to the configuration block.

First
```
./run-drill-dist.sh
```
on one node and open a SQL shell to see if it works properly. Then start this script on all nodes in cluster.
Wait a while and go to web console, you should see 5 drillbits connection.

**Important Note**: Please make sure the DNS can correctly resolve the FQDN formed like `<hostname>.<domain>`, because the Zookeeper Quorum only returns the hostname of the running drillbit. Thus, one drillbit process can only find other process by hostname, which will cause `UnresolvedAddressException` or `CONNECTION ERROR`.
Although there is a property in `drill-override.conf` called `drill.exec.rpc.use.ip` seems related to this behavior, change the value could not take any desired effect.
According to [this page](https://issues.apache.org/jira/browse/DRILL-4934) and [this page](http://drill-user.incubator.apache.narkive.com/MgMU4NaA/dockerized-drill-with-bridged-network), the code does not leverage this property.

### Run Benchmark on multiple nodes
If everything goes well, we should start our benchmark.
```
./bench-drill-dist.sh
```

## Benchmark results
single node, see [results/benchmark_results_single_0.txt](https://github.com/crazyboycjr/apache-drill-tpch-experiments/tree/master/results/benchmark_results_single_0.txt)
```
01.q: 4 rows selected (14.312 seconds)
03.q: 10 rows selected (10.608 seconds)
04.q: 5 rows selected (9.512 seconds)
05.q: 5 rows selected (10.347 seconds)
06.q: 1 row selected (8.921 seconds)
07.q: 4 rows selected (13.392 seconds)
08.q: 2 rows selected (10.257 seconds)
09.q: 175 rows selected (14.042 seconds)
10.q: 20 rows selected (11.048 seconds)
11.q: 1 row selected (0.182 seconds)
12.q: 2 rows selected (10.434 seconds)
13.q: 42 rows selected (3.88 seconds)
14.q: 1 row selected (9.192 seconds)
15a.q: 1 row selected (0.128 seconds)
15.q: 1 row selected (8.692 seconds)
15c.q: 1 row selected (0.095 seconds)
16.q: 18,368 rows selected (2.585 seconds)
17.q: 1 row selected (14.768 seconds)
18.q: 57 rows selected (15.188 seconds)
19.q: 1 row selected (20.481 seconds)
20.q: 181 rows selected (8.262 seconds)
```

five nodes, see [results/benchmark_results_dist_5_nodes_3.txt](https://github.com/crazyboycjr/apache-drill-tpch-experiments/tree/master/results/benchmark_results_dist_5_nodes_3.txt)
```
01.q: 4 rows selected (2.582 seconds)
03.q: 10 rows selected (2.629 seconds)
04.q: 5 rows selected (1.555 seconds)
05.q: 5 rows selected (3.297 seconds)
06.q: 1 row selected (1.58 seconds)
07.q: 4 rows selected (2.541 seconds)
08.q: 2 rows selected (3.107 seconds)
09.q: 175 rows selected (4.135 seconds)
10.q: 20 rows selected (2.471 seconds)
11.q: 1 row selected (0.211 seconds)
12.q: 2 rows selected (2.416 seconds)
13.q: 42 rows selected (2.822 seconds)
14.q: 1 row selected (1.655 seconds)
15a.q: 1 row selected (0.169 seconds)
15.q: 1 row selected (1.676 seconds)
15c.q: 1 row selected (0.097 seconds)
16.q: 18,368 rows selected (2.599 seconds)
17.q: 1 row selected (3.016 seconds)
18.q: 57 rows selected (3.743 seconds)
19.q: 1 row selected (3.32 seconds)
20.q: 181 rows selected (2.281 seconds)
```

We can observe that the Apache Drill in distributed mode achieves a better performance on TPC-H dataset.
However, I still wonder
1. how is the scalibility of Apache Drill
2. where is the bottleneck of these benchmark results.

Apache Drill and Hadoop HDFS are complex systems. I am not a developer, thus, I can only measure it as a black box.

I use `dstat` tool to monitor I/O, CPU, Memory and Network utilization every 1 second
```
dstat --top-bio --top-io --top-mem --top-cpu
```
![dstat.png](https://github.com/crazyboycjr/apache-drill-tpch-experiments/blob/master/measurements/dstat.png)

In this picture, the CPU utilization always floats at ~5%, which indicates that the CPU is not the bottleneck, thus, run multiple drill instance in the cluster get marginal earnings in performance.
Obviously, memory is not the bottleneck either.
The I/O seems to be the bottleneck because sometimes the java process reaches more than 262MB/s I/O speed. The timing buffered disk read speed is about 265.20 MB/sec measured by `hdparm` tool.

However, on 100Gbps Ethernet, granularity of 1s interval are too rough, so I write a script which calls `ethtool -S` to read NIC counters to visualize the transient throughput,  
```
measurements/bench.sh
```
will generate `rcv.png` and `xmit.png` of eth10 network interface.

![rcv.png](https://github.com/crazyboycjr/apache-drill-tpch-experiments/blob/master/measurements/rcv.png)
![xmit.png](https://github.com/crazyboycjr/apache-drill-tpch-experiments/blob/master/measurements/xmit.png)

In these two pictures, the first is Rx throughput, and the second is Tx throughput. Both are on the same Drill node.
The maximum Tx and Rx speed can up to ~500,000,000 Bytes/s, which does not reach the upper bound of bandwidth of 100Gbps.

In conclusion,
1. the HDFS plays an important role in disperse the I/O traffic onto multiple nodes, thus decreasing query time greatly
2. although drillbit process runs distributedly on each node, but it brings little profits to query performance on TPC-H dataset.

This explain why we can achieve similiar results on HDFS cluster with only one drillbit process running.

## References

