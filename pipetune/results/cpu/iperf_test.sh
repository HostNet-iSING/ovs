#!/bin/bash
# Server/Client info
NIC_NAME='rdma0'
NIC_IP='10.0.13.1'  # server ip
CORE_ID=10  # make sure the numa node of this cpu core is the same as the NIC
PORT=30081
# UDP info
PAYLOAD_SIZE=18
BANDWIDTH=1G
# Multi-flow info
FLOW_NUM=1

# server
if [ 'server' == $1 ]; then
    sudo taskset -c ${CORE_ID} iperf3 -s -i 1 -p ${PORT}
# client
elif [ 'client' == $1 ]; then
    sudo taskset -c ${CORE_ID} iperf3 -f g -i 1 -t 20 -c ${NIC_IP} -p ${PORT} -u -l ${PAYLOAD_SIZE} -b ${BANDWIDTH} -P ${FLOW_NUM}
fi


