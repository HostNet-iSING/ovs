#!/bin/bash

CORE_ID='8-15'
host_ip='10.0.2.101'
client_ip='10.0.2.102'
ib_dev='mlx5_0'
client_mac='10:70:fd:87:0e:ba'
server_mac='10:70:fd:6b:93:5c'
duration=10

# -----------------server-----------------
if [ 'server_atomic_bw' == $1 ]; then
    sudo taskset -c ${CORE_ID} ib_atomic_bw -d $ib_dev --report_gbits --use_hugepages --cpu_util --mr_per_qp
elif [ 'server_atomic_lat' == $1 ]; then
    sudo taskset -c ${CORE_ID} ib_atomic_lat -d $ib_dev --report_gbits --use_hugepages --cpu_util --mr_per_qp
elif [ 'server_read_bw' == $1 ]; then
    sudo taskset -c ${CORE_ID} ib_read_bw -d $ib_dev --report_gbits --use_hugepages --cpu_util --mr_per_qp
elif [ 'server_read_lat' == $1 ]; then
    sudo taskset -c ${CORE_ID} ib_read_lat -d $ib_dev --report_gbits --use_hugepages --cpu_util --mr_per_qp
elif [ 'server_write_bw' == $1 ]; then
    sudo taskset -c ${CORE_ID} ib_write_bw -d $ib_dev --report_gbits --use_hugepages --cpu_util --mr_per_qp
elif [ 'server_write_lat' == $1 ]; then
    sudo taskset -c ${CORE_ID} ib_write_lat -d $ib_dev --use_hugepages 
elif [ 'server_raw_bw' == $1 ]; then
    sudo taskset -c ${CORE_ID} raw_ethernet_bw --server -B $server_mac --report_gbits --use_hugepages --cpu_util --mr_per_qp
elif [ 'server_raw_lat' == $1 ]; then
    sudo taskset -c ${CORE_ID} raw_ethernet_lat --server -B $server_mac --report_gbits --use_hugepages --cpu_util --mr_per_qp


# -----------------client-----------------
## -----------------bandwidth testing-----------------
elif [ 'client_atomic_bw' == $1 ]; then
    # atomic testing
    atomic_type='FETCH_AND_ADD' # FETCH_AND_ADD or CMP_AND_SWAP
    connection='RC' # RC/XRC/DC
    mtu=256    # 256-4096
    qp_num=1
    tx_depth=128    

    sudo taskset -c ${CORE_ID} ib_atomic_bw $host_ip -A $atomic_type -c $connection -d $ib_dev -D $duration -m $mtu -q $qp_num -t $tx_depth --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp
 
elif [ 'client_read_bw' == $1 ]; then
    # read bandwidth testing
    connection='RC' # RC/XRC/DC
    mtu=2048    # 256-4096
    qp_num=1
    tx_depth=1024
    msg_size=65536    

    sudo taskset -c ${CORE_ID} ib_read_bw $host_ip -c $connection -d $ib_dev -D $duration -m $mtu -q $qp_num -t $tx_depth -s $msg_size --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp

elif [ 'client_write_bw' == $1 ]; then
    # write bandwidth testing
    connection='RC' # RC/XRC/DC
    mtu=1024    # 256-4096
    qp_num=1
    tx_depth=1024
    msg_size=65536

    sudo taskset -c ${CORE_ID} ib_write_bw $host_ip -c $connection -d $ib_dev -D $duration -m $mtu -q $qp_num -t $tx_depth -s $msg_size --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp

elif [ 'client_raw_bw' == $1 ]; then
    # raw_eth bandwidth testing
    mtu=1500    # 256-4096
    qp_num=1
    tx_depth=1024
    rx_depth=1024
    msg_size=65536    

    sudo taskset -c ${CORE_ID} raw_ethernet_bw $host_ip -d $ib_dev -D $duration -m $mtu -q $qp_num -r $rx_depth -t $tx_depth -s $msg_size --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp

## -----------------latency testing-----------------

elif [ 'client_atomic_lat' == $1 ]; then
    # atomic testing
    atomic_type='FETCH_AND_ADD' # FETCH_AND_ADD or CMP_AND_SWAP
    connection='RC' # RC/XRC/DC
    mtu=256    # 256-4096
    qp_num=1
    tx_depth=128    

    sudo taskset -c ${CORE_ID} ib_atomic_lat $host_ip -A $atomic_type -c $connection -d $ib_dev -D $duration -m $mtu -q $qp_num -t $tx_depth --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp
 
elif [ 'client_read_lat' == $1 ]; then
    # read bandwidth testing
    connection='RC' # RC/XRC/DC
    mtu=1500    # 256-4096
    qp_num=1
    tx_depth=1024
    msg_size=65536    

    sudo taskset -c ${CORE_ID} ib_read_lat $host_ip -c $connection -d $ib_dev -D $duration -m $mtu -q $qp_num -t $tx_depth -s $msg_size --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp

elif [ 'client_write_lat' == $1 ]; then
    # write bandwidth testing
    connection='RC' # RC/XRC/DC
    mtu=1024    # 256-4096
    msg_size=4   
    inline_size=64 
    round=10
    sudo taskset -c ${CORE_ID} ib_write_lat $host_ip -c $connection -d $ib_dev -m $mtu --size $msg_size --perform_warm_up

elif [ 'client_raw_lat' == $1 ]; then
    # raw_eth bandwidth testing
    mtu=1500    # 256-4096
    qp_num=1
    tx_depth=1024
    rx_depth=1024
    msg_size=65536    

    sudo taskset -c ${CORE_ID} raw_ethernet_lat $host_ip -d $ib_dev -D $duration -m $mtu -q $qp_num -r $rx_depth -t $tx_depth -s $msg_size --report-both --report_gbits --use_hugepages --cpu_util --mr_per_qp
fi


