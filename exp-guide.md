# Experiment Guidance

> Reference:
> 1. https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/general.rst
> 2. https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/afxdp.rst
> 3. https://developers.redhat.com/blog/2017/06/05/measuring-and-comparing-open-vswitch-performance#bridge_configuration


1. install pre-built dependencies

```bash
sudo apt-get install guestfs-tools libosinfo-bin qemu-system-x86 libvirt-daemon-system python3-libvirt libosinfo-1.0-dev libxml2-dev libxml2 python3-libxml2
```

2. install `libxdp`

```bash
cd exp-third-party
git clone git@github.com:xdp-project/xdp-tools.git

cd xdp-tools
./configure
make
make install
```

3. make sure `libbfp` and `libxdp` is exist

```bash
apt-get install libbpf-dev

dpkg -l | grep libbpf
ii  libbpf0:amd64                                 1:0.5.0-1ubuntu22.04.1                   amd64        eBPF helper library (shared library)

dpkg -l | grep libxdp
```

!!
```bash
sudo -i
```


4. install 

see [https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/afxdp.rst#installing](https://github.com/openvswitch/ovs/blob/master/Documentation/intro/install/afxdp.rst#installing)

```bash
# setup dpdk path
export C_INCLUDE_PATH=/home/ubuntu/git_repos/dpdk/dpdk-stable-22.11.3/build/install/include:$C_INCLUDE_PATH
export LIBRARY_PATH=/home/ubuntu/git_repos/dpdk/dpdk-stable-22.11.3/build/install/lib/x86_64-linux-gnu:$LIBRARY_PATH
export LD_LIBRARY_PATH=/home/ubuntu/git_repos/dpdk/dpdk-stable-22.11.3/build/install/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
export CPPFLAGS="-I/home/ubuntu/git_repos/dpdk/dpdk-stable-22.11.3/build/install/include"
export LDFLAGS="-L/home/ubuntu/git_repos/dpdk/dpdk-stable-22.11.3/build/install/lib/x86_64-linux-gnu"

export PKG_CONFIG_PATH=/home/ubuntu/git_repos/dpdk/dpdk-stable-22.11.3/build/install/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH

./boot.sh
# ./configure --enable-afxdp --with-dpdk=shared CFLAGS="-Ofast -msse4.2 -mpopcnt"
./configure --with-dpdk=static CFLAGS="-Ofast -msse4.2 -mpopcnt"
make -j && make install
```

```bash
export PATH=/usr/local/share/openvswitch/scripts:$PATH
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
```


start ovs

```bash
# to start
ovs-ctl --no-ovs-vswitchd start 
# ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
# 请注意 NUMA! 
# ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true other_config:pmd-cpu-mask=0xFF00
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true other_config:pmd-cpu-mask=0xFF00FF00
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start

# to stop
ovs-vsctl get Open_vSwitch . dpdk_initialized

# to stop
ovs-ctl stop
```

setup network IF and bridge

```bash
# bridge
ovs-vsctl -- add-br br0 -- set Bridge br0 datapath_type=netdev

# to delete
ovs-vsctl -- del-br br0

# IF
# ethtool -L rdma0 combined 8
ethtool -L rdma0 combined 16

# pmd-rxq-affinity: <queue-id>:<core-id>
# 请注意 NUMA! 
ovs-vsctl add-port br0 rdma0 -- set interface rdma0 type=dpdk options:n_rxq=8 options:n_txq=8 options:dpdk-devargs=0000:98:00.0 other_config:pmd-rxq-affinity="0:8,1:9,2:10,3:11,4:12,5:13,6:14,7:15" options:rx-steering=rss+pipetune

ovs-vsctl add-port br0 rdma0 -- set interface rdma0 type=dpdk options:n_rxq=16 options:n_txq=16 options:dpdk-devargs=0000:98:00.0 other_config:pmd-rxq-affinity="0:8,1:9,2:10,3:11,4:12,5:13,6:14,7:15,8:24,9:25,10:26,11:27,12:28,13:29,14:30,15:31" options:rx-steering=rss+pipetune
```

set flow entry

```bash
# set ovs bridge
ovs-ofctl show br0 

# check rdma0 open_flow index
ovs-vsctl get interface rdma0 ofport

# add flow


ovs-ofctl add-flow br0 "cookie=0,priority=40001,in_port=1 actions=in_port"

# show
ovs-ofctl dump-flows br0
```

```bash
# show statistics
cd exp-scripts
watch -n1 bash show_statistics.sh --duration 60 --rates --stats
```


check log

```bash
cat /usr/local/var/log/openvswitch/ovs-vswitchd.log
```

5. setup virtual machine

(1) download image

```bash
mkdir /opt/images && cd /opt/images
export LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1 LIBGUESTFS_BACKEND=direct
sudo virt-builder centos-7.3 --root-password password:centos -o centos_loopback.qcow2 --format qcow2
```

(2) get `virt-manager` for creating the Virtual Machine profile

```bash

```


(3)

```bash
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
```

setup 1GB hugepages for VM

```bash
sudo -i
echo 1024 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 1024 > /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages
mkdir /mnt/huge
mount -t hugetlbfs pagesize=2MB /mnt/huge
mount -t hugetlbfs pagesize=1GB /mnt/huge
```


> https://docs.openvswitch.org/en/latest/topics/dpdk/vhost-user/
```bash
ovs-vsctl add-port ovs-br0 vhost0 -- set Interface vhost0 type=dpdkvhostuser -- set Interface vhost0 ofport_request=2
ovs-vsctl del-port ovs-br0 vhost0
```

```bash
export OS_IMAGE_PATH=/opt/images
export OVS_BR_SOCKET_PATH=/usr/local/var/run/openvswitch/ovs-br0.snoop

sudo virt-install --connect=qemu:///system \
  --network vhostuser,source_type=unix,source_path=/var/run/openvswitch/vhost0,source_mode=client,model=virtio,driver_queues=4 \
  --network network=default \
  --name=centos_loopback \
  --disk path=$OS_IMAGE_PATH/centos_loopback.qcow2,format=qcow2 \
  --ram 4096 \
  --memorybacking hugepages=off,size=1024,unit=M,nodeset=0 \
  --vcpus=5,cpuset=6,7,8,9,10 \
  --check-cpu \
  --cpu Haswell-noTSX,cell0.id=0,cell0.cpus=0,cell0.memory=4194304 \
  --numatune mode=strict,nodeset=0 \
  --nographics --noautoconsole \
  --import \
  --os-variant=rhel7.0

sudo virt-install --connect=qemu:///system \
  --network vhostuser,source_type=unix,source_path=$OVS_BR_SOCKET_PATH,source_mode=client,model=virtio,driver_queues=4 \
  --network network=default \
  --name=centos_loopback \
  --disk path=$OS_IMAGE_PATH/centos_loopback.qcow2,format=qcow2 \
  --ram 4096 \
  --vcpus=5,cpuset=6,7,8,9,10 \
  --check-cpu \
  --cpu Haswell-noTSX,cell0.id=0,cell0.cpus=0,cell0.memory=4194304 \
  --numatune mode=strict,nodeset=0 \
  --nographics --noautoconsole \
  --import \
  --os-variant=rhel7.0
```