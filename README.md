# Apache Drill TPC-H Experiments

This project contains scripts and instructions which runs TPC-H on Apache Drill.

这个项目包含了用Apache Drill运行分布式代码的脚本和指示。具体做的事情是，在5台机器上从零搭建Apache Drill，并将其运行于容器中。

## Environment
- OS / Kernel: Debian GNU/Linux 8.9, kernel 4.9.0
- CPU: Intel(R) Xeon(R) E5-2650 v4, 48 cores per host, 2 NUMA nodes
- Memory: 128GB
- Network:
	- Every node has two NICs: IP address on mgmt port range in 10.2.96.[50-54] and corresponding IP address on discrete NIC range in 192.168.0.[50-54]
	- The discrete NIC is 100Gbps per port

## Docker images
- [smizy/apache-drill](https://hub.docker.com/r/smizy/apache-drill/)
- [smizy/hadoop-base](https://hub.docker.com/r/smizy/hadoop-base/)
- [zookeeper](https://hub.docker.com/_/zookeeper/)
As far as I know, apache-drill docker image maintained by harisekhon is quite bad so that when drill parses parquet file, it will throw a memory leak execption. It takes me much time to figure out the problem.
Images maintained by smizy is much better.

## Standalone and single node Mode
_More documents_ [here](https://drill.apache.org/docs/)

Running in embedded mode is quite simple and not easy to come into faults.
Just run the container and expose port 8047
```bash
docker run --rm -it -p 8047:8047 smizy/apache-drill drill-embedded
```
and we can go http://ipaddress:8047/ to access web console.

---
But running in embedded mode is boring. We can do a little more things to make Apache Drill run in distributed mode but with only one node online.

First, start a zookeeper instance on 192.168.0.54
```bash
docker run --name zookeeper --net=host --restart always -d zookeeper
or just type
./run-zookeeper.sh
```

Then, modify `drill-override.conf` like below
```
drill.exec:{
	cluster-id: "rdma-testbed",
	rpc: {
		use.ip: true
	},
	zk.connect: "192.168.0.54:2181"
}
```

Finally, we map the `drill-override.conf` to inside container and run `drillbit.sh`
```bash
docker run -d --name apache-drill -it -p 8047:8047 -v /home/cjr/apache-drill/drill-override.conf:/usr/local/apache-drill-1.13.0/conf/drill-override.conf smizy/apache-drill drillbit.sh run
```

Then either access the web console or start a command-line shell
```
docker exec -it apache-drill drill-conf
```
On successful run, the prompt should be like `0: jdbc:drill:> ` instead of `0: jdbc:drill:zk=local> `(embedded mode)

## TPC-H Dataset

## Distributed Mode

## References
