#!/bin/bash
#----------------Parameters---------------
IF_NAME='rdma0'
#----------------Parameters END---------------
if [ 'pin' == $1 ]; then
    sudo tc qdisc add dev $IF_NAME clsact
    sudo tc filter add dev $IF_NAME egress bpf object-pinned /sys/fs/bpf/bmc_tx_filter
elif [ 'unpin' == $1 ]; then
    sudo tc filter del dev $IF_NAME egress
    sudo tc qdisc del dev $IF_NAME clsact
fi
