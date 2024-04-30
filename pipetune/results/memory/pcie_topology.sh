#!/bin/bash
# pcie addr corresponding to the NIC
ethtool -i rdma0 | grep bus-info
# pcie version
sudo lspci -s 04:00.0 -vvv | grep Width
# NUMA
sudo lspci -s 04:00.0 -vvv | grep NUMA

# PCIe Tree
sudo lspci -vt
# Nvidia topology
nvdia-smi topo -m
