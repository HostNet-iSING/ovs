#!/bin/bash
#----------------Parameters---------------
YCSB_PATH="/home/ubuntu/git_repos/YCSB-C-master"
HOST_IP="10.0.2.102"
PORT=11211
WORKLOAD_PATH="workloads/"
WORKLOAD_TYPE="workloada.spec"
CLIENT_NUM=1        # all client thread will located in one core, haven't address
#----------------Parameters END---------------
cd $YCSB_PATH
# start client
./ycsbc -db memcached -threads $CLIENT_NUM -P ${WORKLOAD_PATH}${WORKLOAD_TYPE} -host $HOST_IP -port $PORT
