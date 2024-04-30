Status: Incomplete

Date: 10/25/2023

Ref:
1. [Iperf3 page](https://iperf.fr/iperf-doc.php#3num)
2. [Neper page](https://github.com/google/neper)
3. [dperf page](https://github.com/baidu/dperf)
4. [XDP page](https://github.com/xdp-project/xdp-tutorial)

## Methodology
Examined Datapath: App thread -- Driver thread (optional) -- Cache -- Main memory -- NIC queue -- NIC pipeline

Examine the performance of packet processing with three methods: iperf3, dpdk, and xdp. 

For the iperf3, use udp mode and limit the packet size to the minimal, and increase gradually. As a result, it will bypass most of the kernel network stack. However, the performance would be degraded due to the data copy (from kernel space to user space), driver interaction (hard interrupt), thread interaction (driver and user thread), and memory management (discontiguous memory for descriptors). As a result, using iperf3 will get the minimal performance, refer to the Linux processing performance.

To test the best performance of packet processing, another way is to fully bypass kernel and network stack via DPDK. The receiver in dpdk apps only parses packet and then echo back (reverse the mac addr). DPDK would leverage polling mode driver and contiguous memory so that achieve the upper-bound performance. 

The last one is xdp mode. XDP runs at the starting point of kernel driver. If implementing echo-back function via xdp, most of kernel overheads will be bypassed. The advantage of xdp is the better scalability performance. Compared to dpdk, which leveraging one core to poll all packets from all flows, xdp can leverage Linux thread scheduler to balance the overheads on distributed threads (the polling threads for dpdk). As a result, xdp can achieve better CPU utilization so that support more concurrent connections (i.e., more flows).

In this testing, we mainly evaluate packet processing performance under two conditions: 1. fix only one core and vary the packet size to evaluate single-core performance; 2. fix the packet size and vary the number of concurrent flows to test scalability.

---------------------

Message length: 8B/20B (UDP or TCP Header) + payload

Ethernet MAC frame length: 14B (MAC Header) + 4B (FCS) + 20B (IP Header) + Message; make sure the MAC payload is smaller than MTU (1500 typically), and the MAC frame length is greater than 64B (minimal MAC frame)

Data transfer in practice: MAC frame length + 12B (Frame Gap) + 8B (Sync Code)

For example, when transmitting 18B via UDP, the MAC frame length is 64B (minimal MAC frame), and transfer 84B in practice; when transmitting 1472B via UDP, the MAC frame length is 1518B (maximum MAC frame), and transfer 1538B in practice.

## iPerf testing

### Setup
Enable aRFS over Mellanox CX5 to ensure the iperf application and driver are belong to the same cpu core.

### Result Summary

Reference results: results in (CoNEXT' 18) The eXpress Data Path: Fast Programmable Packet Processing in the Operating System Kernel.

---------------------

## DPDK Testing
DPDK testing is built over the dperf project. Please refer to ServerSetup to build the dperf tool. The github page is [Xinyang HUANG's dperf](https://github.com/Huangxy-Minel/dperf).

To run the testing, run "sudo LD_LIBRARY_PATH=${RTE_SDK}/build/install/lib/x86_64-linux-gnu ./build/dperf -c ./test/udp/server.conf" in server and "sudo LD_LIBRARY_PATH=${RTE_SDK}/build/install/lib/x86_64-linux-gnu ./build/dperf -c ./test/udp/client.conf" in client.

### Setup and Methodology
The basic send/recv model is: each thread of client send a packet and wait for the corresponding echo packet from the server.

To test the maximum tx throughput, we leverage the pipeline sending mechanism: for example, the client concurrently sends 10 packets in one time, without waiting for the echo packet. It may incur hardware packet loss since the nic queue is full (for the receiver). Thus, we can use it to test max pps of unidirectional flow. 

Example config in client: cc 1; keepalive 1us; pipeline 200; flood.

If we want to avoid hardware loss, it should disable the flood mode, where client sends next message only when the previous packet has been echo. For the client, the nic tx queue will never overflow since the dma is driven by the nic; for the receiver, the nic rx queue overflow occurs with a small possibility since receiver will control the sender transmission speed (by echo). It can be considered as the max pps for bidirectional flow.

Example config in client: cc 1; keepalive 0us; pipeline 200.



