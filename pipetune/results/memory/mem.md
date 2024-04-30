Status: Incomplete

Date: 12/07/2023

## PCIe & Topology Summary
### Lab Servers
#### Device info
Desktop01: rdma PCIe4.0x16 NUMA1; singnic PCIe3.0x16 NUMA0

Desktop02: rdma PCIe4.0x16 NUMA1; singnic PCIe3.0x16 NUMA0

#### Topology

### TACC Servers
#### Device info
gpu13: rdma0/1 PCIe3.0x16 NUMA0; rdma2/3 PCIe3.0x16 NUMA1; singnic PCIe3.0x16 NUMA0

gpu14: rdma0/1 PCIe3.0x16 NUMA0; rdma2/3 PCIe3.0x16 NUMA1; singnic PCIe3.0x16 NUMA0

gpu15: rdma0/1 PCIe3.0x16 NUMA0; rdma2/3 PCIe3.0x16 NUMA1; singnic PCIe3.0x16 NUMA0

gpu16: rdma0/1 PCIe3.0x16 NUMA0; rdma2/3 PCIe3.0x16 NUMA1; singnic PCIe3.0x16 NUMA0

#### Topology
Intra: all gpus are assigned to NUMA0

Take gpu13 as an example:

|    |GPU0|GPU1|GPU2|GPU3|GPU4|GPU5|GPU6|GPU7|NIC0|NIC1|NIC2|NIC3|    CPU Affinity|NUMA Affinity|
|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
|GPU0| X  |PIX |PIX |PIX |NODE|NODE|NODE|NODE|NODE|NODE|SYS |SYS |    0-19,40-59  |0            |
|GPU1|PIX | X  |PIX |PIX |NODE|NODE|NODE|NODE|NODE|NODE|SYS |SYS |    0-19,40-59  |0            |
|GPU2|PIX |PIX | X  |PIX |NODE|NODE|NODE|NODE|NODE|NODE|SYS |SYS |    0-19,40-59  |0            |
|GPU3|PIX |PIX |PIX | X  |NODE|NODE|NODE|NODE|NODE|NODE|SYS |SYS |    0-19,40-59  |0            |
|GPU4|NODE|NODE|NODE|NODE| X  |PIX |PIX |PIX |PIX |PIX |SYS |SYS |    0-19,40-59  |0            |
|GPU5|NODE|NODE|NODE|NODE|PIX | X  |PIX |PIX |PIX |PIX |SYS |SYS |    0-19,40-59  |0            |
|GPU6|NODE|NODE|NODE|NODE|PIX |PIX | X  |PIX |PIX |PIX |SYS |SYS |    0-19,40-59  |0            |
|GPU7|NODE|NODE|NODE|NODE|PIX |PIX |PIX | X  |PIX |PIX |SYS |SYS |    0-19,40-59  |0            |
|NIC0|NODE|NODE|NODE|NODE|PIX |PIX |PIX |PIX | X  |PIX |SYS |SYS |                |             |
|NIC1|NODE|NODE|NODE|NODE|PIX |PIX |PIX |PIX |PIX | X  |SYS |SYS |                |             |
|NIC2|SYS |SYS |SYS |SYS |SYS |SYS |SYS |SYS |SYS |SYS | X  |PIX |                |             |
|NIC3|SYS |SYS |SYS |SYS |SYS |SYS |SYS |SYS |SYS |SYS |PIX | X  |                |             |

## Methodology
Examined Datapath: Cache (if enabling DDIO) -- Main Memory -- PCIe -- NIC queue -- NIC pipeline

Using RDMA verbs (openib) to test. 

Potential overheads: NIC queues, PCIe switch, DMA batch, ring buffer descriptors, and cache.

Detail:

First, use Nvidia Performance Utils to test the basic performance (e.g., bandwidth & latency of each verbs). To deep dive into the potential overheads, use RDMA-core to write specific programs, to test different cases (e.g., message size, QP num, etc.).

## Test Results
### with Nvidia Tools



## Deep Dive
### Analysis in theory
Ref:
1. 18-Sigcomm-Understanding PCIe performance for end host networking
2. 16-ATC-Design Guidelines for High Performance RDMA Systems

PCIe TLP: 128B total length with 20~30B TLP Headers

PCIe physical layer throughput: for PCIe 3.0, it can achieve 8.0GT/s per lane, around 7.87 Gbps per lane. When invovling the flow control, the final throughput is 7.08Gb/s (10% deduct).

According the above information, if we transfer 46B UDP/IP packets via PCIe (then the final MAC frame is 64B), the actual PCIe TLP is 128B, and the max throughput is 46 / 128 * 7.08 = 2.54Gbps per lane. After enabling DMA batching (fully leverage TLP payload), the max throughput is 116 / 128 * 7.08 = 6.42Gbps per lane. 

The results demonstrate that, if we want a 100Gbps network transmission for 64B MAC payload, the payload transfer over PCIe should at least achieve 100Gbps, which means at least 100 / 6.42 = 15.6 concurrent DMA transfers with batch optimization. The result is based on throughput, thus is independent of packet size (for 1500 IP payload, it also needs 16 concurrent DMA transfers). For the small packets (e.g., 64B), the DMA batching is necessary.

The latency of PCIe TLP is around 900ns, which means the max throughput of one NIC queue is 1.11Mpps (the pipeline performance depends on the slowest phase). After DMA batching (with 16 lanes), it can achieve 17.7 Mpps per queue. As a result, if we want fully utilize the 100Gbps line rate, 8 queues is needed at least. 

Conclusion: DMA batching is necessary, and 8 queues is necessary for small packet processing. The max throughput per queue is 17.7Mpps (for PCIe 3.0 x 16, 16 DMA batching).
